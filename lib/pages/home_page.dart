import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String role = args?['role'] ?? 'Unknown';
    final String username = args?['username'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('i-EMS Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $username',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Role: $role',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey[700]),
            ),
            const SizedBox(height: 30),
            _buildRoleSpecificUI(role),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificUI(String role) {
    switch (role) {
      case 'Admin':
        return const Text('Admin Panel: Manage Users, Teachers, and Students');
      case 'Teacher':
        return const Text('Teacher Panel: Manage Classes and Grades');
      case 'Student':
        return const Text('Student Panel: View Courses and Results');
      default:
        return const Text('Dashboard Content');
    }
  }
}
