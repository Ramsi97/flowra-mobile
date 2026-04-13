import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_colors.dart';
import 'package:flowra/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:flowra/features/auth/presentation/pages/login_page.dart';
import 'package:flowra/features/home/presentation/pages/home_page.dart';
import 'package:flowra/features/task/presentation/bloc/task_bloc.dart';

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
      ],
      child: MaterialApp(
        title: 'Flowra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Inter', // Note: User may need to add this font to pubspec
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            surface: AppColors.background,
          ),
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const HomePage();
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
