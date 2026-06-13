import 'package:flutter/material.dart';
import '../../db_con.dart';
import '../login.dart';

class TeacherHomePage extends StatefulWidget {
  final Map<String, dynamic>? teacherData;
  
  const TeacherHomePage({super.key, this.teacherData});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  
  String? teacherName = "Teacher";
  String? teacherEmail = "";
  String? subject = "";
  String? employeeId = "";
  String? department = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeacherData();
  }

  Future<void> loadTeacherData() async {
    try {
      // If teacher data passed from login, use that directly
      if (widget.teacherData != null) {
        setState(() {
          teacherName = widget.teacherData!['username'] ?? 'Teacher';
          teacherEmail = widget.teacherData!['email'] ?? '';
          subject = widget.teacherData!['subject'] ?? '';
          employeeId = widget.teacherData!['employee_id'] ?? '';
          department = widget.teacherData!['department'] ?? '';
          isLoading = false;
        });
        return;
      }

      // Otherwise try to fetch from auth (fallback)
      final user = DBCon.supabase.auth.currentUser;
      
      if (user != null && user.email != null) {
        final response = await DBCon.supabase
            .from('teachers')
            .select()
            .eq('email', user.email!)
            .single();

        setState(() {
          teacherName = response['username'] ?? 'Teacher';
          teacherEmail = response['email'] ?? '';
          subject = response['subject'] ?? '';
          employeeId = response['employee_id'] ?? '';
          department = response['department'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading teacher data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      await DBCon.supabase.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      print('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header section with teacher info
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          teacherName ?? 'Teacher',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Employee ID: $employeeId',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teacherEmail ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Information cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Subject card
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.school,
                              color: Colors.blue[700],
                            ),
                            title: const Text('Subject'),
                            subtitle: Text(subject ?? 'Not assigned'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        ),
                        
                        // Department card
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.business,
                              color: Colors.blue[700],
                            ),
                            title: const Text('Department'),
                            subtitle: Text(department ?? 'Not specified'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('View Classes - Coming Soon')),
                            );
                          },
                          icon: const Icon(Icons.class_),
                          label: const Text('View Classes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('View Students - Coming Soon')),
                            );
                          },
                          icon: const Icon(Icons.group),
                          label: const Text('View Students'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('View Attendance - Coming Soon')),
                            );
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('View Attendance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
