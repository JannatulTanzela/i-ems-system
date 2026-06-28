import 'package:flutter/material.dart';
import '../../db_con.dart';
import '../login.dart';
import 'classes_page.dart';
import 'students_page.dart';
import 'attendance_page.dart';

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
  String? teacherId = ""; // Add teacher ID
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
          teacherId = widget.teacherData!['id'] ?? '';
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
          teacherId = response['id'] ?? '';
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
        title: const Text('Teacher Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue[700]),
                  const SizedBox(height: 16),
                  Text('Loading dashboard...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white30,
                              child: Icon(Icons.person, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teacherName ?? 'Teacher',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subject ?? 'No subject assigned',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderInfoRow(Icons.badge, 'Employee ID: $employeeId'),
                              const SizedBox(height: 6),
                              _buildHeaderInfoRow(Icons.email, teacherEmail ?? 'No email'),
                              const SizedBox(height: 6),
                              _buildHeaderInfoRow(Icons.business, department ?? 'No department'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Information cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.school,
                                title: 'Subject',
                                subtitle: subject ?? 'Not assigned',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.business,
                                title: 'Department',
                                subtitle: department ?? 'Not specified',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildActionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClassesPage(teacherId: teacherId),
                                  ),
                                );
                              },
                              icon: Icons.class_,
                              label: 'Manage Classes',
                              color: Colors.blue,
                              description: 'Create and manage your classes',
                            ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentsPage(teacherId: teacherId),
                                  ),
                                );
                              },
                              icon: Icons.group,
                              label: 'Manage Students',
                              color: Colors.teal,
                              description: 'Add/remove students from classes',
                            ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendancePage(teacherId: teacherId),
                                  ),
                                );
                              },
                              icon: Icons.check_circle,
                              label: 'Mark Attendance',
                              color: Colors.orange,
                              description: 'Record student attendance',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(top: BorderSide(color: color[700]!, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color[700], size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required MaterialColor color,
    required String description,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color[700], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
