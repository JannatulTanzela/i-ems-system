import 'package:flutter/material.dart';
import '../../db_con.dart';
import '../login.dart';
import 'admin_student_page.dart';
import 'admin_teacher_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int studentCount = 0;
  int teacherCount = 0;
  bool isLoadingStats = true;
  bool isLoadingReports = false;
  List<Map<String, dynamic>> teacherCourseReports = [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final studentResponse = await DBCon.supabase.from('students').select('id');
      final teacherResponse = await DBCon.supabase.from('teachers').select('id');

      if (!mounted) return;

      setState(() {
        studentCount = List<dynamic>.from(studentResponse).length;
        teacherCount = List<dynamic>.from(teacherResponse).length;
        isLoadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        studentCount = 0;
        teacherCount = 0;
        isLoadingStats = false;
      });
    }
  }

  Future<void> _openReportsSheet(BuildContext context) async {
    setState(() => isLoadingReports = true);

    try {
      final teachersResponse = await DBCon.supabase
          .from('teachers')
          .select('id, username, email, employee_id, subject, department');

      final teachers = List<Map<String, dynamic>>.from(teachersResponse);
      final reportItems = <Map<String, dynamic>>[];

      for (final teacher in teachers) {
        final teacherId = teacher['id']?.toString();
        final classesResponse = teacherId == null || teacherId.isEmpty
            ? []
            : await DBCon.supabase
                .from('classes')
                .select('id, class_name, subject, semester, schedule, room')
                .eq('teacher_id', teacherId);

        reportItems.add({
          'teacher': teacher,
          'courses': List<Map<String, dynamic>>.from(classesResponse),
        });
      }

      if (!mounted) return;

      setState(() {
        teacherCourseReports = reportItems;
        isLoadingReports = false;
      });

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Teacher Course Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Here is the current teacher-to-course assignment overview.'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLoadingReports
                        ? const Center(child: CircularProgressIndicator())
                        : teacherCourseReports.isEmpty
                            ? const Center(child: Text('No teacher course records found.'))
                            : ListView.builder(
                                itemCount: teacherCourseReports.length,
                                itemBuilder: (_, index) {
                                  final item = teacherCourseReports[index];
                                  final teacher = item['teacher'] as Map<String, dynamic>;
                                  final courses = List<Map<String, dynamic>>.from(item['courses'] as List);
                                  final teacherName = (teacher['username'] ?? teacher['email'] ?? teacher['employee_id'] ?? 'Unknown teacher').toString();

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            teacherName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          if (teacher['employee_id'] != null) ...[
                                            const SizedBox(height: 4),
                                            Text('Employee ID: ${teacher['employee_id']}'),
                                          ],
                                          if (teacher['department'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text('Department: ${teacher['department']}'),
                                          ],
                                          const SizedBox(height: 8),
                                          const Text('Assigned Courses', style: TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 6),
                                          if (courses.isEmpty)
                                            const Text('No courses assigned yet.', style: TextStyle(color: Colors.grey))
                                          else
                                            ...courses.map((course) {
                                              final className = course['class_name']?.toString() ?? 'Untitled Course';
                                              final subject = course['subject']?.toString();
                                              final schedule = course['schedule']?.toString();
                                              final room = course['room']?.toString();
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(Icons.book_outlined, size: 16, color: Colors.blue),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(className, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                          if (subject != null && subject.isNotEmpty) Text(subject),
                                                          if (schedule != null && schedule.isNotEmpty) Text('Schedule: $schedule'),
                                                          if (room != null && room.isNotEmpty) Text('Room: $room'),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingReports = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the teacher report.')),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBCon.supabase.auth.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F4C81), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage your institution with clarity',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today at a glance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Students',
                            isLoadingStats ? '—' : studentCount.toString(),
                            Icons.school,
                            Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Teachers',
                            isLoadingStats ? '—' : teacherCount.toString(),
                            Icons.person,
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick actions',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    _buildCard(
                      title: 'Students',
                      subtitle: 'Manage student records',
                      icon: Icons.school,
                      color: const Color(0xFF1E88E5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminStudentPage()),
                        );
                      },
                    ),
                    _buildCard(
                      title: 'Teachers',
                      subtitle: 'Manage teacher profiles',
                      icon: Icons.person,
                      color: const Color(0xFF43A047),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminTeacherPage()),
                        );
                      },
                    ),
                    _buildCard(
                      title: 'Reports',
                      subtitle: 'View system reports',
                      icon: Icons.bar_chart,
                      color: const Color(0xFFFFB300),
                      onTap: () => _openReportsSheet(context),
                    ),
                    _buildCard(
                      title: 'Settings',
                      subtitle: 'Update system preferences',
                      icon: Icons.settings,
                      color: const Color(0xFF546E7A),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings will be available soon.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.insights, color: Color(0xFF1E88E5)),
                            const SizedBox(width: 8),
                            Text('System overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Active modules', '4'),
                        _buildInfoRow('Pending updates', '2'),
                        _buildInfoRow('Support status', 'Healthy'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}