import 'package:flutter/material.dart';
import 'package:i_ems/auth_service.dart';

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
  bool _isLoading = false;
  final AuthService _authService = AuthService();

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

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter username and password', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Try to login with username (email or username field)
      var result = await _authService.loginWithUsername(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (result != null && result['success']) {
        // Verify role matches selected role
        if (result['role'].toString().toLowerCase() ==
            _selectedRole.toLowerCase()) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: {
                'role': result['role'],
                'username': result['fullName'],
                'email': result['email'],
              },
            );
          }
        } else {
          _showMessage(
              'Role mismatch. You are registered as ${result['role']}',
              false);
        }
      } else {
        _showMessage(result?['message'] ?? 'Login failed', false);
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}', false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                          onPressed: _isLoading ? null : _login,
                          height: 55,
                          color: Colors.blue.shade800,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("SIGN IN",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1.1)),
                          ),
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