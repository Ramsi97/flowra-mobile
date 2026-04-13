import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const FlowraApp());
}

class FlowraApp extends StatelessWidget {
  const FlowraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Flowra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121220),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFF8B5CF6),
            surface: const Color(0xFF1E1E2C),
          ),
          fontFamily: 'Roboto',
        ),
        home: const LoginPage(),
      ),
    );
  }
}
