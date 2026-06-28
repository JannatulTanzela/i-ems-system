import 'package:flutter/material.dart';
import '../../db_con.dart';

class StudentsPage extends StatefulWidget {
  final String? teacherId;
  
  const StudentsPage({super.key, this.teacherId});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = [];
  String? selectedClassId;
  bool isLoading = true;

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
      
      final response = await DBCon.supabase
          .from('class_students')
          .select('''
            id,
            students:student_id (
              id,
              full_name,
              email,
              student_uid,
              department
            )
          ''')
          .eq('class_id', classId);

      setState(() {
        students = List<Map<String, dynamic>>.from(response);
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

  void _showAddStudentDialog() {
    if (selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class first')),
      );
      return;
    }

    final studentUidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student to Class', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: studentUidController,
              decoration: InputDecoration(
                labelText: 'Student UID',
                prefixIcon: Icon(Icons.badge, color: Colors.blue[700]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                ),
                hintText: 'Enter student UID',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student will be added to the selected class',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (studentUidController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student UID is required')),
                );
                return;
              }

              try {
                final studentResponse = await DBCon.supabase
                    .from('students')
                    .select()
                    .eq('student_uid', studentUidController.text)
                    .single();

                final studentId = studentResponse['id'];

                final checkEnrolled = await DBCon.supabase
                    .from('class_students')
                    .select()
                    .eq('class_id', selectedClassId!)
                    .eq('student_id', studentId);

                if (checkEnrolled.isNotEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Student already enrolled in this class'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  Navigator.pop(context);
                  return;
                }

                await DBCon.supabase.from('class_students').insert({
                  'class_id': selectedClassId,
                  'student_id': studentId,
                });

                if (mounted) {
                  Navigator.pop(context);
                  fetchStudents(selectedClassId!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Student added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  void _removeStudent(String enrollmentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove $studentName from this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await DBCon.supabase
                    .from('class_students')
                    .delete()
                    .eq('id', enrollmentId);

                if (mounted) {
                  Navigator.pop(context);
                  fetchStudents(selectedClassId!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Student removed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Students', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('Loading students...', style: TextStyle(color: Colors.grey[600])),
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
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
                    ),
                    Expanded(
                      child: students.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No students enrolled yet',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add students to this class',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _showAddStudentDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Student'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    ),
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
                                final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.orange];
                                final color = colors[index % colors.length];

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: color[100],
                                      child: Text(
                                        (student['full_name'] ?? 'S')[0].toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color[700],
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      student['full_name'] ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        _buildInfoRow(Icons.badge, 'UID: ${student['student_uid'] ?? 'N/A'}'),
                                        const SizedBox(height: 3),
                                        _buildInfoRow(Icons.email, student['email'] ?? 'N/A'),
                                        const SizedBox(height: 3),
                                        _buildInfoRow(Icons.business, student['department'] ?? 'N/A'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _removeStudent(enrollment['id'], student['full_name'] ?? 'Student'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: classes.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddStudentDialog,
              backgroundColor: Colors.blue[700],
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ],
    );
  }
}
