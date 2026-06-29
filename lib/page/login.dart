import 'package:flutter/material.dart';
import '../db_con.dart';
import 'admin/admin_home_page.dart';
import 'student/student_home_page.dart';
import 'teacher/teacher_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  String role = 'admin';
  bool isLoading = false;
  bool obscurePass = true;

  Future login() async {
    final input = emailController.text.trim();
    final pass = passController.text.trim();

    if (input.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String emailToUse = input;
      String passwordToUse = pass;

      if (role == 'student') {
        // Student login: Direct database query (no Supabase auth needed)
        try {
          final response = await DBCon.supabase
              .from('students')
              .select()
              .eq('email', input)
              .eq('username', pass) // password = username
              .single();

          // If we reach here, student found with matching email and username
          if (response != null) {
            // ✅ Login successful - Student data found in database
            // Pass student data to StudentHomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StudentHomePage(studentData: response),
              ),
            );
            setState(() => isLoading = false);
            return;
          }
        } catch (e) {
          // Student not found or credentials don't match
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid email or username")),
          );
          setState(() => isLoading = false);
          return;
        }
      } else if (role == 'teacher') {
        // Teacher login: Direct database query (no Supabase auth needed)
        try {
          final response = await DBCon.supabase
              .from('teachers')
              .select()
              .eq('email', input)
              .eq('username', pass) // password = username
              .single();

          // If we reach here, teacher found with matching email and username
          if (response != null) {
            // ✅ Login successful - Teacher data found in database
            // Pass teacher data to TeacherHomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherHomePage(teacherData: response),
              ),
            );
            setState(() => isLoading = false);
            return;
          }
        } catch (e) {
          // Teacher not found or credentials don't match
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid email or username")),
          );
          setState(() => isLoading = false);
          return;
        }
      } else {
        // Admin/Teacher: Use Supabase auth
        final res = await DBCon.supabase.auth.signInWithPassword(
          email: emailToUse,
          password: passwordToUse,
        );

        if (res.user != null) {
          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          }
        }
      }

    } catch (e) {
      debugPrint('Login error: $e');
      String errorMsg = 'Login failed';

      if (e.toString().contains('Invalid login credentials')) {
        errorMsg = 'Invalid email or password';
      } else if (e.toString().contains('User not found')) {
        errorMsg = 'User not found';
      } else {
        errorMsg = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), duration: const Duration(seconds: 3)),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final roleLabels = {
      'admin': 'Admin',
      'teacher': 'Teacher',
      'student': 'Student',
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F4C81), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.school, size: 68, color: Color(0xFF1E88E5)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'IEMS Login',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in as ${roleLabels[role]}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButton<String>(
                          value: role,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                            DropdownMenuItem(value: 'student', child: Text('Student')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              role = value!;
                              emailController.clear();
                              passController.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: role == 'student' ? 'Student Email' : 'Email / Username',
                          hintText: role == 'student' ? 'Enter your email' : 'Enter your email or username',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passController,
                        obscureText: obscurePass,
                        decoration: InputDecoration(
                          labelText: role == 'student' ? 'Password (Username/Nickname)' : 'Password',
                          hintText: role == 'student' ? 'Enter your username/nickname' : 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () {
                              setState(() {
                                obscurePass = !obscurePass;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: isLoading ? null : login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Powered by IEMS', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}