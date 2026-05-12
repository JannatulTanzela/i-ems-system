import 'package:flutter/material.dart';
import 'package:i_ems/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleAndRedirect();
    });
  }

  void _checkRoleAndRedirect() {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String role = args?['role'] ?? 'Student';
    
    if (role.toLowerCase() == 'admin') {
      Navigator.pushReplacementNamed(
        context,
        '/admin',
        arguments: args,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String role = args?['role'] ?? 'Student';
    final String username = args?['username'] ?? 'User';
    final String email = args?['email'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: const Text('i-EMS Dashboard',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade800),
              accountName:
                  Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(role),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome Back,",
                      style: TextStyle(
                          color: Colors.blue.shade100, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Role: $role",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Quick Actions",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildRoleSpecificGrid(role),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificGrid(String role) {
    List<Map<String, dynamic>> actions = [];

    if (role == 'Admin') {
      actions = [
        {'title': 'Students', 'icon': Icons.people, 'color': Colors.orange},
        {'title': 'Teachers', 'icon': Icons.supervisor_account, 'color': Colors.green},
        {'title': 'Classes', 'icon': Icons.class_outlined, 'color': Colors.blue},
        {'title': 'Fees', 'icon': Icons.monetization_on, 'color': Colors.purple},
        {'title': 'Exam', 'icon': Icons.assignment, 'color': Colors.red},
        {'title': 'Settings', 'icon': Icons.settings, 'color': Colors.grey},
      ];
    } else if (role == 'Teacher') {
      actions = [
        {'title': 'My Classes', 'icon': Icons.class_outlined, 'color': Colors.blue},
        {'title': 'Attendance', 'icon': Icons.how_to_reg, 'color': Colors.green},
        {'title': 'Assignments', 'icon': Icons.assignment_turned_in, 'color': Colors.orange},
        {'title': 'Exams', 'icon': Icons.edit_note, 'color': Colors.red},
        {'title': 'Library', 'icon': Icons.menu_book, 'color': Colors.purple},
        {'title': 'Schedule', 'icon': Icons.calendar_month, 'color': Colors.teal},
      ];
    } else {
      // Student
      actions = [
        {'title': 'Courses', 'icon': Icons.book, 'color': Colors.blue},
        {'title': 'Results', 'icon': Icons.grade, 'color': Colors.green},
        {'title': 'Schedule', 'icon': Icons.calendar_today, 'color': Colors.orange},
        {'title': 'Payments', 'icon': Icons.payment, 'color': Colors.red},
        {'title': 'Library', 'icon': Icons.library_books, 'color': Colors.purple},
        {'title': 'Support', 'icon': Icons.help_outline, 'color': Colors.teal},
      ];
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.3,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: actions[index]['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(actions[index]['icon'], color: actions[index]['color'], size: 30),
              ),
              const SizedBox(height: 10),
              Text(
                actions[index]['title'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}