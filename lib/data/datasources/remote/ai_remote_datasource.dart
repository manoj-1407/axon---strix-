import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:axon/core/constants/app_constants.dart';
import 'package:axon/core/errors/exceptions.dart';
import 'package:axon/domain/entities/ai_provider.dart';
import 'package:axon/domain/entities/message.dart';
import 'package:axon/domain/repositories/ai_repository.dart';

abstract class AiRemoteDatasource {
  Future<AiResponse> sendMessage({required List<Message> messages, required AiProvider provider});
  Stream<String> sendMessageStream({required List<Message> messages, required AiProvider provider});
  Future<bool> testConnection(AiProvider provider);
  Future<List<String>> fetchAvailableModels(AiProvider provider);
}

class AiRemoteDatasourceImpl implements AiRemoteDatasource {
  final Dio _dio;
  AiRemoteDatasourceImpl({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<AiResponse> sendMessage({required List<Message> messages, required AiProvider provider}) async {
    try {
      if (provider.isGemini) return await _sendGeminiMessage(messages, provider);
      return await _sendOpenAiMessage(messages, provider);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Stream<String> sendMessageStream({required List<Message> messages, required AiProvider provider}) {
    if (provider.isGemini) return _streamGeminiMessage(messages, provider);
    return _streamOpenAiMessage(messages, provider);
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  List<Map<String, dynamic>> _buildOpenAiMessages(List<Message> messages) {
    return messages.map((m) {
      if (m.attachmentPaths != null && m.attachmentPaths!.isNotEmpty) {
        final contentList = <Map<String, dynamic>>[];
        contentList.add({'type': 'text', 'text': m.content});
        for (final path in m.attachmentPaths!) {
          try {
            final file = File(path);
            if (file.existsSync()) {
              final bytes = file.readAsBytesSync();
              final base64 = base64Encode(bytes);
              final mime = _getMimeType(path);
              contentList.add({
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mime;base64,$base64'
                }
              });
            }
          } catch (_) {}
        }
        return {'role': m.role.name, 'content': contentList};
      }
      return {'role': m.role.name, 'content': m.content};
    }).toList();
  }

  Future<AiResponse> _sendOpenAiMessage(List<Message> messages, AiProvider provider) async {
    final response = await _dio.post(
      '${provider.baseUrl}/chat/completions',
      options: Options(
        headers: _openAiHeaders(provider),
        sendTimeout: const Duration(seconds: AppConstants.requestTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConstants.requestTimeoutSeconds),
      ),
      data: {
        'model': provider.model,
        'messages': _buildOpenAiMessages(messages),
        'stream': false,
      },
    );
    final data = response.data;
    if (data == null || data['choices'] == null || (data['choices'] as List).isEmpty) {
      throw const InvalidResponseException('Empty response from AI provider');
    }
    final content = data['choices'][0]['message']['content'] as String;
    final usage = data['usage'];
    final totalTokens = usage?['total_tokens'] as int?;
    return AiResponse(content: content, tokenCount: totalTokens);
  }

  Stream<String> _streamOpenAiMessage(List<Message> messages, AiProvider provider) async* {
    final controller = StreamController<String>();
    _dio.post(
      '${provider.baseUrl}/chat/completions',
      options: Options(
        headers: _openAiHeaders(provider),
        responseType: ResponseType.stream,
        sendTimeout: const Duration(seconds: AppConstants.streamTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConstants.streamTimeoutSeconds),
      ),
      data: {
        'model': provider.model,
        'messages': _buildOpenAiMessages(messages),
        'stream': true,
        'stream_options': {'include_usage': true},
      },
    ).then((response) {
      (response.data.stream as Stream<List<int>>)
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') { controller.close(); return; }
            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta']?['content'];
              if (delta != null && delta is String && delta.isNotEmpty) controller.add(delta);
            } catch (_) {}
          }
        },
        onError: (e) => controller.addError(e),
        onDone: () { if (!controller.isClosed) controller.close(); },
      );
    }).catchError((Object e) {
      controller.addError(
        e is DioException ? _handleDioException(e) : e,
      );
    });
    yield* controller.stream;
  }

  Future<AiResponse> _sendGeminiMessage(List<Message> messages, AiProvider provider) async {
    final systemText = _extractSystemPrompt(messages);
    final contents = _buildGeminiContents(messages);
    final url = '${provider.baseUrl}/models/${provider.model}:generateContent?key=${provider.apiKey}';
    final body = <String, dynamic>{'contents': contents};
    if (systemText != null) {
      body['system_instruction'] = {'parts': [{'text': systemText}]};
    }
    final response = await _dio.post(url,
        options: Options(
          headers: const {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: AppConstants.requestTimeoutSeconds),
          receiveTimeout: const Duration(seconds: AppConstants.requestTimeoutSeconds),
        ),
        data: body);
    
    final data = response.data;
    final candidates = data['candidates'];
    if (candidates == null || (candidates as List).isEmpty) {
      throw const InvalidResponseException('Empty response from Gemini');
    }
    final content = candidates[0]['content']['parts'][0]['text'] as String;
    final usage = data['usageMetadata'];
    final totalTokens = usage?['totalTokenCount'] as int?;
    return AiResponse(content: content, tokenCount: totalTokens);
  }

  Stream<String> _streamGeminiMessage(List<Message> messages, AiProvider provider) async* {
    final systemText = _extractSystemPrompt(messages);
    final contents = _buildGeminiContents(messages);
    final url =
        '${provider.baseUrl}/models/${provider.model}:streamGenerateContent?key=${provider.apiKey}&alt=sse';
    final body = <String, dynamic>{'contents': contents};
    if (systemText != null) {
      body['system_instruction'] = {'parts': [{'text': systemText}]};
    }
    final controller = StreamController<String>();
    _dio.post(url,
        options: Options(
          headers: const {'Content-Type': 'application/json'},
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: AppConstants.streamTimeoutSeconds),
        ),
        data: body).then((response) {
      (response.data.stream as Stream<List<int>>)
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            try {
              final json = jsonDecode(data);
              final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
              if (text != null && text is String) controller.add(text);
            } catch (_) {}
          }
        },
        onError: (e) => controller.addError(e),
        onDone: () { if (!controller.isClosed) controller.close(); },
      );
    }).catchError((Object e) {
      controller.addError(e);
    });
    yield* controller.stream;
  }

  String? _extractSystemPrompt(List<Message> messages) {
    for (final m in messages) {
      if (m.role == MessageRole.system && m.content.isNotEmpty) return m.content;
    }
    return null;
  }

  List<Map<String, dynamic>> _buildGeminiContents(List<Message> messages) {
    return messages
        .where((m) => m.role != MessageRole.system)
        .map((m) {
          final parts = <Map<String, dynamic>>[];
          parts.add({'text': m.content});
          
          if (m.attachmentPaths != null && m.attachmentPaths!.isNotEmpty) {
            for (final path in m.attachmentPaths!) {
              try {
                final file = File(path);
                if (file.existsSync()) {
                  final bytes = file.readAsBytesSync();
                  final base64 = base64Encode(bytes);
                  final mime = _getMimeType(path);
                  parts.add({
                    'inline_data': {
                      'mime_type': mime,
                      'data': base64
                    }
                  });
                }
              } catch (_) {}
            }
          }
          
          return {
            'role': m.role == MessageRole.user ? 'user' : 'model',
            'parts': parts,
          };
        })
        .toList();
  }

  Map<String, String> _openAiHeaders(AiProvider provider) {
    final h = <String, String>{
      'Authorization': 'Bearer ${provider.apiKey}',
      'Content-Type': 'application/json',
    };
    if (provider.type == ProviderType.openRouter) {
      h['HTTP-Referer'] = 'https://axon.dev';
      h['X-Title'] = 'AXON';
    }
    return h;
  }

  @override
  Future<bool> testConnection(AiProvider provider) async {
    try {
      if (provider.isGemini) {
        final r = await _dio.get('${provider.baseUrl}/models?key=${provider.apiKey}',
            options: Options(sendTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
        return r.statusCode == 200;
      }
      final r = await _dio.get('${provider.baseUrl}/models',
          options: Options(
            headers: {'Authorization': 'Bearer ${provider.apiKey}'},
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  @override
  Future<List<String>> fetchAvailableModels(AiProvider provider) async {
    try {
      if (provider.isGemini) {
        final r = await _dio.get('${provider.baseUrl}/models?key=${provider.apiKey}');
        final models = r.data['models'] as List;
        return models
            .map((m) => (m['name'] as String).replaceAll('models/', ''))
            .where((m) => m.contains('gemini'))
            .toList()
          ..sort();
      }
      final r = await _dio.get('${provider.baseUrl}/models',
          options: Options(headers: {'Authorization': 'Bearer ${provider.apiKey}'}));
      final models = r.data['data'] as List;
      return models.map((m) => m['id'] as String).toList()..sort();
    } catch (_) { return []; }
  }

  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Request timed out. Please try again.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 401) return const AuthException('Invalid API key. Check your configuration.');
        if (code == 429) return const RateLimitException('Rate limit exceeded. Please wait and try again.');
        if (code >= 500) return ServerException('Server error ($code). Please try again later.', statusCode: code);
        return ServerException(
            e.response?.data?['error']?['message'] ?? 'Request failed with status $code',
            statusCode: code);
      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection. Check your network settings.');
      default:
        return AppException('An unexpected error occurred: ${e.message}');
    }
  }
}
