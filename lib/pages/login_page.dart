import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'Student';
  final List<String> _roles = ['Admin', 'Student', 'Teacher'];
  bool _obscurePassword = true;

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings_outlined;
      case 'Teacher':
        return Icons.person_pin_outlined;
      case 'Student':
        return Icons.school_outlined;
      default:
        return Icons.person_outline;
    }
  }

  void _login() {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter username and password'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'role': _selectedRole, 'username': _usernameController.text},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.school, size: 50, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Login",
                      style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 5),
                  Text("i-EMS Management System",
                      style: TextStyle(color: Colors.blue.shade100, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50)
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  hintText: "Username / ID",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
                                ),
                              ),
                              const Divider(color: Colors.grey, thickness: 0.5),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.blue.shade300,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.blue.shade100),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(_getRoleIcon(_selectedRole), color: Colors.blue),
                              ),
                              items: _roles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role, style: const TextStyle(color: Colors.black87)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        MaterialButton(
                          onPressed: _login,
                          height: 55,
                          color: Colors.blue.shade800,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text("SIGN IN",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Forgot Password?",
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}