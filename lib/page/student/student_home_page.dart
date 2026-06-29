import 'package:flutter/material.dart';
import '../../db_con.dart';
import '../login.dart';
import 'attendance_utils.dart';

class StudentHomePage extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const StudentHomePage({super.key, this.studentData});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String? studentName = 'Student';
  String? studentEmail = '';
  String? studentId;
  bool isLoading = true;
  bool isSelectingCourse = false;
  List<Map<String, dynamic>> availableClasses = [];
  List<Map<String, dynamic>> enrolledClasses = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> attendanceSummary = [];

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    try {
      if (widget.studentData != null) {
        setState(() {
          studentName = widget.studentData!['full_name'] ?? 'Student';
          studentEmail = widget.studentData!['email'] ?? '';
          studentId = widget.studentData!['id']?.toString();
          isLoading = false;
        });
        await fetchEnrolledClasses();
        await fetchAvailableClasses();
        return;
      }

      final user = DBCon.supabase.auth.currentUser;

      if (user != null && user.email != null) {
        final response = await DBCon.supabase.from('students').select().eq('email', user.email!).single();

        setState(() {
          studentName = response['full_name'] ?? 'Student';
          studentEmail = response['email'] ?? '';
          studentId = response['id']?.toString();
          isLoading = false;
        });
        await fetchEnrolledClasses();
        await fetchAvailableClasses();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchEnrolledClasses() async {
    if (studentId == null || studentId!.isEmpty) {
      setState(() => enrolledClasses = []);
      return;
    }

    try {
      final response = await DBCon.supabase
          .from('class_students')
          .select('class_id, classes(id, class_name, subject, schedule, room)')
          .eq('student_id', studentId!);

      final classes = <Map<String, dynamic>>[];
      for (final item in response) {
        final classInfo = item['classes'];
        if (classInfo != null) {
          classes.add(Map<String, dynamic>.from(classInfo));
        }
      }

      setState(() => enrolledClasses = classes);
      await fetchAssignments();
      await fetchAttendanceSummary();
    } catch (e) {
      debugPrint('Error loading enrolled classes: $e');
      setState(() => enrolledClasses = []);
      await fetchAssignments();
      await fetchAttendanceSummary();
    }
  }

  Future<void> fetchAssignments() async {
    if (enrolledClasses.isEmpty) {
      setState(() => assignments = []);
      return;
    }

    final classIds = enrolledClasses
        .map((course) => course['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (classIds.isEmpty) {
      setState(() => assignments = []);
      return;
    }

    try {
      final response = await DBCon.supabase
          .from('class_sessions')
          .select()
          .filter('class_id', 'in', classIds)
          .order('session_datetime', ascending: true);

      setState(() => assignments = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Error loading assignments: $e');
      setState(() => assignments = []);
    }
  }

  Future<void> fetchAttendanceSummary() async {
    if (studentId == null || studentId!.isEmpty || enrolledClasses.isEmpty) {
      setState(() => attendanceSummary = []);
      return;
    }

    try {
      final classIds = enrolledClasses
          .map((course) => course['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (classIds.isEmpty) {
        setState(() => attendanceSummary = []);
        return;
      }

      final response = await DBCon.supabase
          .from('attendance')
          .select('class_id, status')
          .eq('student_id', studentId!);

      final attendanceRows = List<Map<String, dynamic>>.from(response);
      final summary = <Map<String, dynamic>>[];

      for (final course in enrolledClasses) {
        final classId = course['id']?.toString();
        if (classId == null || classId.isEmpty) continue;

        final rows = attendanceRows.where((row) => row['class_id']?.toString() == classId).toList();
        final total = rows.length;
        final present = rows.where((row) => (row['status']?.toString().toLowerCase() ?? '') == 'present').length;
        final percentage = calculateAttendancePercentage(total: total, presentCount: present.toDouble());

        summary.add({
          'class_id': classId,
          'class_name': course['class_name']?.toString() ?? course['subject']?.toString() ?? 'Course',
          'subject': course['subject']?.toString(),
          'total': total,
          'present': present,
          'percentage': percentage,
        });
      }

      setState(() => attendanceSummary = summary);
    } catch (e) {
      debugPrint('Error loading attendance summary: $e');
      setState(() => attendanceSummary = []);
    }
  }

  Future<void> fetchAvailableClasses() async {
    if (studentId == null || studentId!.isEmpty) {
      setState(() => availableClasses = []);
      return;
    }

    try {
      final response = await DBCon.supabase.from('classes').select();
      final allClasses = List<Map<String, dynamic>>.from(response);

      final enrolledIds = enrolledClasses.map((c) => c['id'].toString()).toSet();
      final available = allClasses.where((c) => !enrolledIds.contains(c['id'].toString())).toList();

      setState(() => availableClasses = available);
    } catch (e) {
      debugPrint('Error loading available classes: $e');
      setState(() => availableClasses = []);
    }
  }

  Future<void> selectCourse(String classId) async {
    if (studentId == null || studentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student profile is not ready yet.')),
      );
      return;
    }

    setState(() => isSelectingCourse = true);

    try {
      final existing = await DBCon.supabase
          .from('class_students')
          .select()
          .eq('student_id', studentId!)
          .eq('class_id', classId);

      if (existing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already selected this course.')),
        );
        return;
      }

      await DBCon.supabase.from('class_students').insert({
        'class_id': classId,
        'student_id': studentId,
        'status': 'Active',
      });

      await fetchEnrolledClasses();
      await fetchAvailableClasses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course selected successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Error selecting course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not select this course.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSelectingCourse = false);
      }
    }
  }

  Future<void> logout() async {
    try {
      await DBCon.supabase.auth.signOut();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed')),
      );
    }
  }

  void showAssignmentsSheet() {
    final courseNames = <String, String>{
      for (final course in enrolledClasses)
        course['id'].toString(): course['class_name']?.toString() ?? course['subject']?.toString() ?? 'Course',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Assignments shared by your selected courses will appear here.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              if (assignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No assignments have been added for your courses yet.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: assignments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final assignment = assignments[index];
                      final courseName = courseNames[assignment['class_id']?.toString()] ?? 'Course';
                      final description = (assignment['description'] ?? '').toString().trim();
                      final link = (assignment['link'] ?? '').toString().trim();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment['title']?.toString() ?? 'Assignment',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(courseName, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                            const SizedBox(height: 6),
                            if (assignment['session_datetime'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(_formatDateTime(assignment['session_datetime'].toString()), style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(description, style: const TextStyle(fontSize: 12)),
                            ],
                            if (link.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(link, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void showAttendanceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attendance Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('See your attendance percentage for each enrolled course.'),
              const SizedBox(height: 14),
              if (attendanceSummary.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No attendance data available yet.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: attendanceSummary.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = attendanceSummary[index];
                      final percentage = (item['percentage'] as num).toDouble();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fact_check, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['class_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (item['subject'] != null) Text(item['subject'].toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('${item['present']} / ${item['total']} sessions present', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: percentage >= 75 ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void showCoursesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select your course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Choose a course from the list below to enroll in it.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              if (enrolledClasses.isNotEmpty) ...[
                const Text('Your selected courses', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: enrolledClasses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final course = enrolledClasses[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['class_name']?.toString() ?? course['subject']?.toString() ?? 'Course', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (course['subject'] != null) Text(course['subject'].toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text('Available courses', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (availableClasses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No courses are available right now.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableClasses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final course = availableClasses[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['class_name']?.toString() ?? course['subject']?.toString() ?? 'Course', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (course['subject'] != null) Text(course['subject'].toString()),
                                  if (course['schedule'] != null) Text('Schedule: ${course['schedule']}'),
                                  if (course['room'] != null) Text('Room: ${course['room']}'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: isSelectingCourse ? null : () => selectCourse(course['id'].toString()),
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Student Portal',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Welcome back, stay on top of your learning',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: logout,
                            icon: const Icon(Icons.logout, color: Colors.white),
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: const Icon(Icons.person, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName ?? 'Student',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      studentEmail ?? '',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text('Active student', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text('Quick access', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        children: [
                          _buildFeatureCard('Courses', Icons.book, const Color(0xFF4DB6AC), showCoursesSheet),
                          _buildFeatureCard('Assignments', Icons.assignment, const Color(0xFF64B5F6), showAssignmentsSheet),
                          _buildFeatureCard('Attendance', Icons.fact_check, const Color(0xFFFFD54F), showAttendanceSheet),
                          _buildFeatureCard('Schedule', Icons.schedule, const Color(0xFFEF9A9A), () {}),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.menu_book_outlined, color: Color(0xFF1E88E5)),
                                  SizedBox(width: 8),
                                  Text('Your assigned courses', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (enrolledClasses.isEmpty)
                                const Text('No courses selected yet. Tap the Courses card to choose one.')
                              else
                                Column(
                                  children: enrolledClasses.map((course) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E88E5).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.book_outlined, color: Color(0xFF1E88E5)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(course['class_name']?.toString() ?? course['subject']?.toString() ?? 'Course', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                if (course['subject'] != null) Text(course['subject'].toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.event_note, color: Color(0xFF1E88E5)),
                                  SizedBox(width: 8),
                                  Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text('Your next class starts at 10:00 AM. Make sure your assignments are ready.'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: const [
                                  Chip(label: Text('Math')), 
                                  Chip(label: Text('Physics')), 
                                ],
                              ),
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

  String _formatDateTime(String value) {
    try {
      final dateTime = DateTime.parse(value).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  Widget _buildFeatureCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
