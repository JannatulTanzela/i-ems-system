import 'package:flutter/material.dart';
import 'package:i_ems/pages/admin/admin_home_page.dart';
import 'package:i_ems/pages/home_page.dart';
import 'package:i_ems/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bcjqdypdsmegtyxaassg.supabase.co',
    anonKey: 'sb_publishable_YDLpEFmiASv6YiAnpHHfBQ_M-e56JqS',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'i-EMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return AdminHomePage(
            username: args?['username'] ?? 'Admin',
            email: args?['email'] ?? '',
          );
        },
      },
    );
  }
}
