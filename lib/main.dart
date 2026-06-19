import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:axon/core/di/service_locator.dart';
import 'package:axon/core/theme/app_colors.dart';
import 'package:axon/core/theme/app_theme.dart';
import 'package:axon/presentation/blocs/conversation/conversation_bloc.dart';
import 'package:axon/presentation/blocs/settings/settings_bloc.dart';
import 'package:axon/presentation/blocs/settings/settings_state.dart';
import 'package:axon/presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await initDependencies();
  runApp(const AxonApp());
}

class AxonApp extends StatelessWidget {
  const AxonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<SettingsBloc>()),
        BlocProvider(create: (_) => sl<ConversationBloc>()),
      ],
      child: const _AppCore(),
    );
  }
}

class _AppCore extends StatelessWidget {
  const _AppCore();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (prev, next) {
        // Only rebuild MaterialApp when theme preset changes
        if (prev is SettingsLoaded && next is SettingsLoaded) {
          return prev.themePreset != next.themePreset;
        }
        return next is SettingsLoaded;
      },
      builder: (context, state) {
        // Apply theme preset to C class before building MaterialApp
        if (state is SettingsLoaded) {
          C.applyPreset(state.themePreset);
        }

        // Update status bar nav color to match current bg
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: C.bg,
        ));

        return MaterialApp(
          title: 'AXON',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.current,
          darkTheme: AppTheme.current,
          themeMode: ThemeMode.dark,
          home: const SplashScreen(),
        );
      },
    );
  }
}
