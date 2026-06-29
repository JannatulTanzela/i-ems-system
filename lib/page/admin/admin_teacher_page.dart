import 'package:flutter/material.dart';
import '../../db_con.dart';

class AdminTeacherPage extends StatefulWidget {
  const AdminTeacherPage({super.key});

  @override
  State<AdminTeacherPage> createState() => _AdminTeacherPageState();
}

class _AdminTeacherPageState extends State<AdminTeacherPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> filteredTeachers = [];
  List<Map<String, dynamic>> allClasses = [];
  List<Map<String, dynamic>> assignedClasses = [];
  List<Map<String, dynamic>> unassignedClasses = [];
  String? selectedTeacherId;
  bool isLoadingClasses = false;

  Future<void> fetchTeachers() async {
    final res = await DBCon.supabase.from('teachers').select();
    final data = List<Map<String, dynamic>>.from(res);
    setState(() {
      teachers = data;
      filteredTeachers = data;
      if ((selectedTeacherId == null || selectedTeacherId!.isEmpty) && data.isNotEmpty) {
        selectedTeacherId = data.first['id']?.toString();
      }
    });
    if (selectedTeacherId != null && selectedTeacherId!.isNotEmpty) {
      await loadTeacherClasses();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void updateFilter(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredTeachers = teachers.where((teacher) {
        final username = (teacher['username'] ?? '').toString().toLowerCase();
        final email = (teacher['email'] ?? '').toString().toLowerCase();
        final subject = (teacher['subject'] ?? '').toString().toLowerCase();
        final department = (teacher['department'] ?? '').toString().toLowerCase();
        return username.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            subject.contains(lowerQuery) ||
            department.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> loadTeacherClasses() async {
    if (selectedTeacherId == null || selectedTeacherId!.isEmpty) {
      setState(() {
        allClasses = [];
        assignedClasses = [];
        unassignedClasses = [];
      });
      return;
    }

    setState(() => isLoadingClasses = true);

    try {
      final response = await DBCon.supabase
          .from('classes')
          .select('id, class_name, subject, semester, schedule, room, teacher_id')
          .order('created_at', ascending: false);

      final allClasses = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;

      setState(() {
        this.allClasses = allClasses;
        assignedClasses = this.allClasses.where((classItem) {
          final teacherValue = classItem['teacher_id']?.toString();
          return teacherValue == selectedTeacherId;
        }).toList();
        unassignedClasses = this.allClasses.where((classItem) {
          final teacherValue = classItem['teacher_id']?.toString();
          return teacherValue == null || teacherValue.isEmpty || teacherValue != selectedTeacherId;
        }).toList();
        isLoadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        allClasses = [];
        assignedClasses = [];
        unassignedClasses = [];
        isLoadingClasses = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load classes: $e')),
      );
    }
  }

  Future<void> assignClassToTeacher(String classId) async {
    if (selectedTeacherId == null || selectedTeacherId!.isEmpty) return;

    await DBCon.supabase.from('classes').update({'teacher_id': selectedTeacherId}).eq('id', classId);
    await loadTeacherClasses();
  }

  Future<void> removeClassFromTeacher(String classId) async {
    await DBCon.supabase.from('classes').update({'teacher_id': null}).eq('id', classId);
    await loadTeacherClasses();
  }

  Future<void> createClass() async {
    final classNameController = TextEditingController();
    final subjectController = TextEditingController();
    final classCodeController = TextEditingController();
    final scheduleController = TextEditingController();
    final roomController = TextEditingController();
    final semesterController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: classNameController, decoration: const InputDecoration(labelText: 'Class Name')),
              const SizedBox(height: 8),
              TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
              const SizedBox(height: 8),
              TextField(controller: classCodeController, decoration: const InputDecoration(labelText: 'Class Code')),
              const SizedBox(height: 8),
              TextField(controller: scheduleController, decoration: const InputDecoration(labelText: 'Schedule')),
              const SizedBox(height: 8),
              TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Room')),
              const SizedBox(height: 8),
              TextField(controller: semesterController, decoration: const InputDecoration(labelText: 'Semester')),
              const SizedBox(height: 8),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (classNameController.text.trim().isEmpty) {
                Navigator.pop(context, false);
                return;
              }

              await DBCon.supabase.from('classes').insert({
                'class_name': classNameController.text.trim(),
                'subject': subjectController.text.trim(),
                'class_code': classCodeController.text.trim(),
                'schedule': scheduleController.text.trim(),
                'room': roomController.text.trim(),
                'semester': semesterController.text.trim(),
                'description': descriptionController.text.trim(),
              });
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      await loadTeacherClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class created successfully.')));
      }
    }
  }

  Future<void> deleteClass(String classId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('This will remove the class record. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBCon.supabase.from('classes').delete().eq('id', classId);
      await loadTeacherClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class deleted successfully.')));
      }
    }
  }

  void openForm({Map<String, dynamic>? data}) {
    final username = TextEditingController(text: data?['username']);
    final email = TextEditingController(text: data?['email']);
    final employeeId = TextEditingController(text: data?['employee_id']);
    final subject = TextEditingController(text: data?['subject']);
    final qualification = TextEditingController(text: data?['qualification']);
    final experienceYears = TextEditingController(text: data?['experience_years']?.toString());
    final department = TextEditingController(text: data?['department']);
    final phone = TextEditingController(text: data?['phone']);
    final address = TextEditingController(text: data?['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  data == null ? 'Add Teacher' : 'Edit Teacher',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _field('Username', username),
              _field('Email', email),
              _field('Employee ID', employeeId),
              _field('Subject', subject),
              _field('Qualification', qualification),
              _field('Experience Years', experienceYears),
              _field('Department', department),
              _field('Phone', phone),
              _field('Address', address),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final payload = {
                      'username': username.text.trim(),
                      'email': email.text.trim(),
                      'employee_id': employeeId.text.trim(),
                      'subject': subject.text.trim(),
                      'qualification': qualification.text.trim(),
                      'experience_years': int.tryParse(experienceYears.text) ?? 0,
                      'department': department.text.trim(),
                      'phone': phone.text.trim(),
                      'address': address.text.trim(),
                    };

                    try {
                      if (data == null) {
                        await DBCon.supabase.from('teachers').insert(payload);
                      } else {
                        await DBCon.supabase.from('teachers').update(payload).eq('id', data['id']);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Save failed: $e')),
                      );
                      return;
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    fetchTeachers();
                  },
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save Teacher'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void deleteTeacher(dynamic id) async {
    await DBCon.supabase.from('teachers').delete().eq('id', id);
    fetchTeachers();
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Teachers',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Search and manage faculty information',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: TextField(
                  controller: searchController,
                  onChanged: updateFilter,
                  decoration: InputDecoration(
                    hintText: 'Search by name, subject, or department',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school, color: Color(0xFF1E88E5)),
                            const SizedBox(width: 10),
                            Text('${teachers.length} teachers registered', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedTeacherId,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: teachers.map((teacher) {
                                  final label = (teacher['username'] ?? teacher['email'] ?? 'Unknown teacher').toString();
                                  return DropdownMenuItem<String>(
                                    value: teacher['id']?.toString(),
                                    child: Text(label),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  setState(() => selectedTeacherId = value);
                                  if (value != null && value.isNotEmpty) {
                                    await loadTeacherClasses();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              if (selectedTeacherId == null || selectedTeacherId!.isEmpty)
                                const Text('Choose a teacher to manage assigned classes.')
                              else ...[
                                Row(
                                  children: [
                                    const Icon(Icons.book_outlined, color: Color(0xFF1E88E5), size: 18),
                                    const SizedBox(width: 6),
                                    const Text('Assigned classes', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (isLoadingClasses)
                                  const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                                else if (assignedClasses.isEmpty)
                                  const Text('No classes assigned yet.', style: TextStyle(color: Colors.grey))
                                else
                                  ...assignedClasses.map((classItem) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                classItem['class_name']?.toString() ?? 'Class',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                              onPressed: () => removeClassFromTeacher(classItem['id'].toString()),
                                            ),
                                          ],
                                        ),
                                      )),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final selectedClassId = await showDialog<String>(
                                            context: context,
                                            builder: (context) {
                                              String? tempClassId;
                                              final availableClasses = allClasses.where((classItem) {
                                                final teacherValue = classItem['teacher_id']?.toString();
                                                return teacherValue == null || teacherValue.isEmpty || teacherValue != selectedTeacherId;
                                              }).toList();
                                              return AlertDialog(
                                                title: const Text('Assign a Class'),
                                                content: DropdownButtonFormField<String>(
                                                  value: tempClassId,
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  hint: const Text('Choose a class'),
                                                  items: availableClasses.map((classItem) {
                                                    return DropdownMenuItem<String>(
                                                      value: classItem['id']?.toString(),
                                                      child: Text(classItem['class_name']?.toString() ?? 'Class'),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) => tempClassId = value,
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                                  FilledButton(
                                                    onPressed: () {
                                                      if (tempClassId != null && tempClassId!.isNotEmpty) {
                                                        Navigator.pop(context, tempClassId);
                                                      }
                                                    },
                                                    child: const Text('Assign'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (selectedClassId != null && selectedClassId.isNotEmpty) {
                                            await assignClassToTeacher(selectedClassId);
                                          }
                                        },
                                        icon: const Icon(Icons.add_circle_outline),
                                        label: const Text('Assign Class'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: createClass,
                                        icon: const Icon(Icons.add_box_outlined),
                                        label: const Text('Create Class'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (allClasses.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: allClasses.map((classItem) {
                                      return Chip(
                                        label: Text(classItem['class_name']?.toString() ?? 'Class'),
                                        deleteIcon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        onDeleted: () => deleteClass(classItem['id'].toString()),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredTeachers.isEmpty
                            ? const Center(child: Text('No teachers found'))
                            : ListView.builder(
                                itemCount: filteredTeachers.length,
                                itemBuilder: (_, i) {
                                  final t = filteredTeachers[i];
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(0xFF1E88E5).withOpacity(0.12),
                                        child: const Icon(Icons.person, color: Color(0xFF1E88E5)),
                                      ),
                                      title: Text(t['username'] ?? t['email'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('${t['subject'] ?? ''}\nDept: ${t['department'] ?? ''} • Phone: ${t['phone'] ?? ''}'),
                                      isThreeLine: true,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
                                            onPressed: () => openForm(data: t),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () => deleteTeacher(t['id']),
                                          ),
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
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
    );
  }
}