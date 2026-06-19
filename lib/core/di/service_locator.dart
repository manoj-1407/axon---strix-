import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axon/data/datasources/local/local_datasource.dart';
import 'package:axon/data/datasources/local/settings_datasource.dart';
import 'package:axon/data/datasources/remote/ai_remote_datasource.dart';
import 'package:axon/data/models/conversation_model.dart';
import 'package:axon/data/models/message_model.dart';
import 'package:axon/data/models/ai_provider_model.dart';
import 'package:axon/data/repositories/conversation_repository_impl.dart';
import 'package:axon/data/repositories/ai_repository_impl.dart';
import 'package:axon/domain/repositories/conversation_repository.dart';
import 'package:axon/domain/repositories/ai_repository.dart';
import 'package:axon/domain/repositories/settings_repository.dart';
import 'package:axon/presentation/blocs/chat/chat_bloc.dart';
import 'package:axon/presentation/blocs/conversation/conversation_bloc.dart';
import 'package:axon/presentation/blocs/settings/settings_bloc.dart';
import 'package:axon/core/constants/app_constants.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ConversationModelAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(AiProviderModelAdapter());

  final convBox = await Hive.openBox<ConversationModel>(AppConstants.hiveConversationBox);
  final msgBox = await Hive.openBox<MessageModel>(AppConstants.hiveMessageBox);
  final providerBox = await Hive.openBox<AiProviderModel>(AppConstants.hiveProviderBox);
  final prefs = await SharedPreferences.getInstance();

  sl.registerLazySingleton<LocalDatasource>(() => HiveLocalDatasource(conversationBox: convBox, messageBox: msgBox));
  sl.registerLazySingleton<SettingsDatasource>(() => HiveSettingsDatasource(providerBox: providerBox, prefs: prefs));
  sl.registerLazySingleton<AiRemoteDatasource>(() => AiRemoteDatasourceImpl(dio: Dio()));
  sl.registerLazySingleton<ConversationRepository>(() => ConversationRepositoryImpl(sl()));
  sl.registerLazySingleton<AiRepository>(() => AiRepositoryImpl(sl()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()));
  sl.registerFactory(() => ConversationBloc(sl()));
  sl.registerFactory(() => ChatBloc(aiRepository: sl(), conversationRepository: sl(), settingsRepository: sl()));
  sl.registerFactory(() => SettingsBloc(settingsRepository: sl(), aiRepository: sl()));
}
