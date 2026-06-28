import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db_con.dart';

class AttendancePage extends StatefulWidget {
  final String? teacherId;
  
  const AttendancePage({super.key, this.teacherId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {};
  String? selectedClassId;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      setState(() => isLoading = true);
      
      final response = await DBCon.supabase
          .from('classes')
          .select()
          .eq('teacher_id', widget.teacherId ?? '')
          .order('created_at', ascending: false);

      setState(() {
        classes = List<Map<String, dynamic>>.from(response);
        if (classes.isNotEmpty) {
          selectedClassId = classes[0]['id'] as String;
          fetchStudents(selectedClassId!);
        } else {
          isLoading = false;
        }
      });
    } catch (e) {
      print('Error fetching classes: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> fetchStudents(String classId) async {
    try {
      setState(() => isLoading = true);
      attendanceStatus.clear();
      
      final classStudents = await DBCon.supabase
          .from('class_students')
          .select('''
            id,
            students:student_id (
              id,
              full_name,
              email,
              student_uid
            )
          ''')
          .eq('class_id', classId);

      final attendanceRecords = await DBCon.supabase
          .from('attendance')
          .select()
          .eq('class_id', classId)
          .eq('attendance_date', selectedDate.toString().split(' ')[0]);

      for (var record in attendanceRecords) {
        attendanceStatus[record['student_id']] = record['status'];
      }

      setState(() {
        students = List<Map<String, dynamic>>.from(classStudents);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching students: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _changeAttendanceStatus(String studentId, String newStatus) {
    setState(() {
      attendanceStatus[studentId] = newStatus;
    });
  }

  Future<void> _submitAttendance() async {
    if (selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    if (attendanceStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to mark attendance')),
      );
      return;
    }

    try {
      setState(() => isSubmitting = true);

      final dateStr = selectedDate.toString().split(' ')[0];

      for (var student in students) {
        final studentId = student['students']['id'];
        final status = attendanceStatus[studentId] ?? 'Present';

        final existing = await DBCon.supabase
            .from('attendance')
            .select()
            .eq('class_id', selectedClassId!)
            .eq('student_id', studentId)
            .eq('attendance_date', dateStr);

        if (existing.isEmpty) {
          await DBCon.supabase.from('attendance').insert({
            'class_id': selectedClassId,
            'student_id': studentId,
            'attendance_date': dateStr,
            'status': status,
          });
        } else {
          await DBCon.supabase
              .from('attendance')
              .update({'status': status})
              .eq('class_id', selectedClassId!)
              .eq('student_id', studentId)
              .eq('attendance_date', dateStr);
        }
      }

      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Attendance saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue[700]),
                  const SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No classes found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Class selection
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedClassId,
                              underline: const SizedBox(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              items: classes
                                  .map<DropdownMenuItem<String>>((classItem) => DropdownMenuItem<String>(
                                        value: classItem['id'] as String,
                                        child: Row(
                                          children: [
                                            Icon(Icons.class_, color: Colors.blue[700], size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                classItem['class_name'] ?? 'Unnamed Class',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedClassId = value);
                                  fetchStudents(value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Date picker
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                                fetchStudents(selectedClassId!);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('EEE, MMM dd, yyyy').format(selectedDate),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Students list
                    Expanded(
                      child: students.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No students enrolled in this class',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final enrollment = students[index];
                                final student = enrollment['students'];
                                final studentId = student['id'];
                                final status = attendanceStatus[studentId] ?? 'Present';
                                final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.orange];
                                final color = colors[index % colors.length];

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: color[100],
                                          child: Text(
                                            (student['full_name'] ?? 'S')[0].toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color[700],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student['full_name'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'UID: ${student['student_uid'] ?? 'N/A'}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: DropdownButton<String>(
                                            value: status,
                                            underline: const SizedBox(),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            items: ['Present', 'Absent', 'Late', 'Excused']
                                                .map((s) => DropdownMenuItem<String>(
                                                      value: s,
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        child: Row(
                                                          children: [
                                                            _getStatusIcon(s),
                                                            const SizedBox(width: 6),
                                                            Text(s, style: const TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                            onChanged: (value) {
                                              if (value != null) {
                                                _changeAttendanceStatus(studentId, value);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Submit button
                    if (students.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _submitAttendance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child: isSubmitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Saving...'),
                                    ],
                                  )
                                : const Text(
                                    'Save Attendance',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return const Icon(Icons.check_circle, color: Colors.green, size: 14);
      case 'Absent':
        return const Icon(Icons.close, color: Colors.red, size: 14);
      case 'Late':
        return const Icon(Icons.schedule, color: Colors.orange, size: 14);
      case 'Excused':
        return const Icon(Icons.info, color: Colors.blue, size: 14);
      default:
        return const Icon(Icons.help, size: 14);
    }
  }
}
