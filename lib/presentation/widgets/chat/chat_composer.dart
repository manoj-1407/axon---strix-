import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:axon/core/theme/app_colors.dart';

class ChatComposer extends StatefulWidget {
  final bool isLoading;
  final Function(String text, List<String> attachments) onSend;

  const ChatComposer({super.key, required this.isLoading, required this.onSend});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _speech = SpeechToText();
  final List<String> _attachmentPaths = [];
  bool _hasText = false;
  bool _isListening = false;
  bool _speechAvail = false;
  Timer? _cursorTimer;
  bool _cursorVisible = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  Future<void> _initSpeech() async {
    _speechAvail = await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _send() {
    final text = _ctrl.text.trim();
    if ((text.isEmpty && _attachmentPaths.isEmpty) || widget.isLoading) return;
    final attachments = List<String>.from(_attachmentPaths);
    _ctrl.clear();
    setState(() {
      _hasText = false;
      _attachmentPaths.clear();
    });
    widget.onSend(text, attachments);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _attachmentPaths.add(image.path);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleListening() async {
    if (!_speechAvail) return;
    if (_isListening) {
      await _speech.stop();
      _cursorTimer?.cancel();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() => _cursorVisible = !_cursorVisible);
      });
      await _speech.listen(
        onResult: (r) {
          _ctrl.text = r.recognizedWords;
          _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
        },
        listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.bg,
        border: Border(top: BorderSide(color: C.border)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: C.error, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'listening${_cursorVisible ? '_' : ' '}',
                    style: GoogleFonts.jetBrainsMono(color: C.error, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (_attachmentPaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachmentPaths.length,
                  itemBuilder: (context, i) {
                    final path = _attachmentPaths[i];
                    final file = File(path);
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: C.border),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(file, fit: BoxFit.cover),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _attachmentPaths.removeAt(i)),
                              child: Container(
                                color: C.bg.withOpacity(0.8),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close_rounded, size: 10, color: C.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SquareButton(
                onTap: _pickImage,
                active: false,
                activeBg: Colors.transparent,
                activeBorder: C.border,
                child: const Icon(Icons.add_photo_alternate_outlined, size: 18, color: C.grey2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 15, height: 1.55),
                    decoration: InputDecoration(
                      hintText: widget.isLoading ? 'axon is generating_' : '>_ ask anything',
                      hintStyle: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 13),
                      filled: true,
                      fillColor: C.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: C.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: C.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: C.accent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_speechAvail)
                _SquareButton(
                  onTap: _toggleListening,
                  active: _isListening,
                  activeBg: C.errorDim,
                  activeBorder: C.error,
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                    size: 18,
                    color: _isListening ? C.error : C.grey2,
                  ),
                ),
              if (_speechAvail) const SizedBox(width: 6),
              _SquareButton(
                onTap: widget.isLoading ? null : _send,
                active: (_hasText || _attachmentPaths.isNotEmpty) && !widget.isLoading,
                activeBg: C.accent,
                activeBorder: C.accent,
                child: widget.isLoading
                    ? SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: C.accent),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: (_hasText || _attachmentPaths.isNotEmpty) ? C.accentText : C.grey2,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool active;
  final Color activeBg;
  final Color activeBorder;
  final Widget child;

  const _SquareButton({
    required this.onTap,
    required this.active,
    required this.activeBg,
    required this.activeBorder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? activeBg : C.surface,
          border: Border.all(color: active ? activeBorder : C.border),
          borderRadius: BorderRadius.zero,
        ),
        child: Center(child: child),
      ),
    );
  }
}
