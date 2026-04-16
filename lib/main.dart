import 'package:flutter/material.dart';
import 'package:i_ems/db_con.dart';
import 'package:i_ems/pages/home_page.dart';
import 'package:i_ems/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MongoDB connection
  try {
    await MongoDatabase.connect();
  } catch (e) {
    print("Error connecting to database: $e");
  }

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
      },
    );
  }
}
