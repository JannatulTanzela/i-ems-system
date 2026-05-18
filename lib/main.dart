import 'package:flutter/material.dart';
import 'db_con.dart';
import 'page/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBCon.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IEMS System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginPage(),
    );
  }
}