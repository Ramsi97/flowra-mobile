import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'package:flowra/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:flowra/features/auth/presentation/pages/login_page.dart';
import 'package:flowra/features/home/presentation/pages/home_page.dart';
import 'package:flowra/features/task/presentation/bloc/task_bloc.dart';
import 'package:flowra/features/settings/presentation/bloc/theme_bloc.dart';
import 'package:flowra/features/settings/presentation/bloc/theme_state.dart';
import 'package:flowra/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:flowra/features/focus/presentation/bloc/focus_bloc.dart';
import 'package:flowra/features/home/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const FlowraApp());
}

class FlowraApp extends StatelessWidget {
  const FlowraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<TaskBloc>()),
        BlocProvider(create: (_) => di.sl<ThemeBloc>()),
        BlocProvider(create: (_) => di.sl<ScheduleBloc>()),
        BlocProvider(create: (_) => di.sl<FocusBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Flowra',
            debugShowCheckedModeBanner: false,
            themeMode: themeState.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _splashFinished = false;

  @override
  void initState() {
    super.initState();
    // When the network layer can't refresh an expired session, bounce the
    // whole app back to login instead of leaving it on a dead, 401-ing screen.
    di.sl<ApiClient>().onSessionExpired = () {
      if (mounted) {
        context.read<AuthBloc>().add(SessionExpired());
      }
    };
    // Fire once on startup to restore any saved session from secure storage.
    context.read<AuthBloc>().add(CheckAuthRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // The splash is a one-time, launch-only screen. It stays up until BOTH
        // its animation has finished AND the initial session restore has
        // resolved. Crucially we only treat the *very first* AuthLoading (the
        // startup CheckAuthRequested, while still on AuthInitial-era) as
        // "restoring". Once we've left the splash, subsequent AuthLoading
        // states — e.g. during login — must NOT bring the splash back; the
        // LoginPage shows its own inline button spinner instead.
        final restoringSession = !_splashFinished &&
            (state is AuthInitial || state is AuthLoading);

        if (!_splashFinished || restoringSession) {
          return SplashPage(
            onSplashComplete: () {
              if (!_splashFinished) {
                setState(() => _splashFinished = true);
              }
            },
          );
        }

        if (state is AuthAuthenticated) {
          return const HomePage();
        }
        // Unauthenticated, error, registered, or a post-splash loading state
        // all resolve to the login surface.
        return const LoginPage();
      },
    );
  }
}
