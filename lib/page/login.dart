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

  String role = "admin";
  bool isLoading = false;
  bool obscurePass = true;

  Future login() async {
    final input = emailController.text.trim();
    final pass = passController.text.trim();

    if (input.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String emailToUse = input;
      String passwordToUse = pass;

      if (role == "student") {
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
      } else if (role == "teacher") {
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
          if (role == "admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          }
        }
      }

    } catch (e) {
      print('Login error: $e');
      String errorMsg = "Login Failed";

      if (e.toString().contains("Invalid login credentials")) {
        errorMsg = "Invalid email or password";
      } else if (e.toString().contains("User not found")) {
        errorMsg = "User not found";
      } else {
        errorMsg = "Error: ${e.toString()}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), duration: const Duration(seconds: 3)),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4FC3F7),
              Color(0xFF0288D1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school,
                          size: 70, color: Color(0xFF0288D1)),

                      const SizedBox(height: 10),

                      const Text(
                        "IEMS Login",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ROLE DROPDOWN - Must be FIRST for proper state update
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: role,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: "admin", child: Text("Admin")),
                            DropdownMenuItem(value: "teacher", child: Text("Teacher")),
                            DropdownMenuItem(value: "student", child: Text("Student")),
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

                      const SizedBox(height: 20),

                      // EMAIL FIELD - Label changes based on role
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: role == "student" ? "Student Email" : "Email/Username",
                          hintText: role == "student" ? "Enter your email" : "Enter your email or username",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PASSWORD FIELD - For all roles (Admin, Teacher, Student)
                      TextField(
                        controller: passController,
                        obscureText: obscurePass,
                        decoration: InputDecoration(
                          labelText: role == "student" ? "Password (Username/Nickname)" : "Password",
                          hintText: role == "student" ? "Enter your username/nickname" : "Enter your password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePass
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                obscurePass = !obscurePass;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      const SizedBox(height: 10),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Powered by IEMS",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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