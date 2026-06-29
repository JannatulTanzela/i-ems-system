import 'package:flutter/material.dart';
import '../../db_con.dart';

class ClassesPage extends StatefulWidget {
  final String? teacherId;

  const ClassesPage({super.key, this.teacherId});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  List<Map<String, dynamic>> classes = [];
  Map<String, List<Map<String, dynamic>>> classItems = {};
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

      final fetchedClasses = List<Map<String, dynamic>>.from(response);

      setState(() {
        classes = fetchedClasses;
        isLoading = false;
      });

      await fetchClassItems(fetchedClasses);
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

  Future<void> fetchClassItems(List<Map<String, dynamic>> fetchedClasses) async {
    final classIds = fetchedClasses
        .map((classItem) => classItem['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (classIds.isEmpty) {
      if (mounted) {
        setState(() => classItems = {});
      }
      return;
    }

    try {
      final response = await DBCon.supabase
          .from('class_sessions')
          .select()
          .filter('class_id', 'in', classIds)
          .order('session_datetime', ascending: true);

      final groupedItems = <String, List<Map<String, dynamic>>>{};
      for (final item in List<Map<String, dynamic>>.from(response)) {
        final classId = item['class_id']?.toString();
        if (classId != null && classId.isNotEmpty) {
          groupedItems.putIfAbsent(classId, () => []).add(item);
        }
      }

      if (mounted) {
        setState(() => classItems = groupedItems);
      }
    } catch (e) {
      print('Error fetching class sessions: $e');
      if (mounted) {
        setState(() => classItems = {});
      }
    }
  }

  void _showAddClassDialog() {
    final classNameController = TextEditingController();
    final subjectController = TextEditingController();
    final classCodeController = TextEditingController();
    final scheduleController = TextEditingController();
    final roomController = TextEditingController();
    final semesterController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Class', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(classNameController, 'Class Name', Icons.class_),
              const SizedBox(height: 12),
              _buildTextField(subjectController, 'Subject', Icons.school),
              const SizedBox(height: 12),
              _buildTextField(classCodeController, 'Class Code', Icons.code),
              const SizedBox(height: 12),
              _buildTextField(scheduleController, 'Schedule (e.g., Mon-Wed 10:00 AM)', Icons.schedule),
              const SizedBox(height: 12),
              _buildTextField(roomController, 'Room Number', Icons.door_front_door),
              const SizedBox(height: 12),
              _buildTextField(semesterController, 'Semester', Icons.calendar_month),
              const SizedBox(height: 12),
              _buildTextField(descriptionController, 'Description', Icons.description, maxLines: 3),
            ],
          ),
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
              if (classNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class name is required')),
                );
                return;
              }

              try {
                await DBCon.supabase.from('classes').insert({
                  'teacher_id': widget.teacherId,
                  'class_name': classNameController.text,
                  'subject': subjectController.text,
                  'class_code': classCodeController.text,
                  'schedule': scheduleController.text,
                  'room': roomController.text,
                  'semester': semesterController.text,
                  'description': descriptionController.text,
                });

                if (mounted) {
                  Navigator.pop(context);
                  fetchClasses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Class added successfully'),
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
            child: const Text('Add Class'),
          ),
        ],
      ),
    );
  }

  void _showAddClassItemDialog(String classId) {
    _showClassItemDialog(
      classId: classId,
      title: 'Add Course Session',
      submitLabel: 'Add Session',
      onSubmit: (title, description, link, sessionDateTime) async {
        await DBCon.supabase.from('class_sessions').insert({
          'class_id': classId,
          'title': title,
          'description': description,
          'link': link,
          'session_datetime': sessionDateTime.toUtc().toIso8601String(),
        });
      },
    );
  }

  void _showEditClassItemDialog(Map<String, dynamic> session) {
    _showClassItemDialog(
      classId: session['class_id']?.toString() ?? '',
      title: 'Edit Course Session',
      submitLabel: 'Save Changes',
      initialTitle: session['title']?.toString() ?? '',
      initialDescription: session['description']?.toString() ?? '',
      initialLink: session['link']?.toString() ?? '',
      initialDateTime: session['session_datetime'] != null ? DateTime.tryParse(session['session_datetime'].toString()) : null,
      onSubmit: (title, description, link, sessionDateTime) async {
        await DBCon.supabase
            .from('class_sessions')
            .update({
              'title': title,
              'description': description,
              'link': link,
              'session_datetime': sessionDateTime.toUtc().toIso8601String(),
            })
            .eq('id', session['id']);
      },
    );
  }

  void _showClassItemDialog({
    required String classId,
    required String title,
    required String submitLabel,
    String initialTitle = '',
    String initialDescription = '',
    String initialLink = '',
    DateTime? initialDateTime,
    required Future<void> Function(String title, String description, String link, DateTime sessionDateTime) onSubmit,
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final descriptionController = TextEditingController(text: initialDescription);
    final linkController = TextEditingController(text: initialLink);
    final dateController = TextEditingController();
    DateTime? selectedDateTime = initialDateTime;

    if (initialDateTime != null) {
      dateController.text = _formatDateTime(initialDateTime);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, 'Title', Icons.title),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (pickedDate == null) return;

                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                  );
                  if (pickedTime == null) return;

                  selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  dateController.text = _formatDateTime(selectedDateTime!);
                },
                decoration: InputDecoration(
                  labelText: 'Date & Time',
                  prefixIcon: Icon(Icons.schedule, color: Colors.blue[700]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(descriptionController, 'Description (optional)', Icons.description, maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField(linkController, 'Link (optional)', Icons.link),
            ],
          ),
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
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required')),
                );
                return;
              }

              if (selectedDateTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Date & time is required')),
                );
                return;
              }

              try {
                await onSubmit(
                  titleController.text.trim(),
                  descriptionController.text.trim(),
                  linkController.text.trim(),
                  selectedDateTime!,
                );

                if (mounted) {
                  Navigator.pop(context);
                  await fetchClasses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(title.contains('Edit') ? '✓ Session updated successfully' : '✓ Session added successfully'),
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
            child: Text(submitLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
      ),
    );
  }

  void _deleteClassSession(String sessionId, String sessionTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$sessionTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await DBCon.supabase.from('class_sessions').delete().eq('id', sessionId);

                if (mounted) {
                  Navigator.pop(context);
                  await fetchClasses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Session deleted successfully'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteClass(String classId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this class? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                await DBCon.supabase
                    .from('classes')
                    .delete()
                    .eq('id', classId);

                if (mounted) {
                  Navigator.pop(context);
                  fetchClasses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Class deleted successfully'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('Loading classes...', style: TextStyle(color: Colors.grey[600])),
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
                        'No classes yet',
                        style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first class to get started',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddClassDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Class'),
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
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final classItem = classes[index];
                    final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.orange];
                    final color = colors[index % colors.length];
                    final classSessions = classItems[classItem['id'].toString()] ?? [];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: color[700]!, width: 5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color[100],
                                    child: Icon(Icons.class_, color: color[700], size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          classItem['class_name'] ?? 'Unnamed Class',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(Icons.code, classItem['class_code'] ?? 'N/A'),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(Icons.school, classItem['subject'] ?? 'N/A'),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(Icons.door_front_door, classItem['room'] ?? 'N/A'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red, size: 20),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                        onTap: () => _deleteClass(classItem['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event_note, color: Colors.blue[700], size: 18),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Course Sessions',
                                          style: TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (classSessions.isEmpty)
                                      Text(
                                        'No session details added yet.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      )
                                    else
                                      ...classSessions.map((session) => _buildSessionCard(session)).toList(),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _showAddClassItemDialog(classItem['id'].toString()),
                                      icon: const Icon(Icons.add_circle_outline),
                                      label: const Text('Add Session'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue[700],
                                        side: BorderSide(color: Colors.blue[700]!),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        backgroundColor: Colors.blue[700],
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final description = (session['description'] ?? '').toString().trim();
    final link = (session['link'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session['title'] ?? 'Untitled Session',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () => _showEditClassItemDialog(session),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => _deleteClassSession(session['id'].toString(), session['title']?.toString() ?? 'this session'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (session['session_datetime'] != null)
            _buildInfoRow(Icons.schedule, _formatDateTime(session['session_datetime'].toString())),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
          if (link.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(link, style: TextStyle(fontSize: 12, color: Colors.blue[700])),
          ],
        ],
      ),
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

  String _formatDateTime(dynamic value) {
    if (value is DateTime) {
      final dateTime = value.toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    if (value is String) {
      try {
        final dateTime = DateTime.parse(value).toLocal();
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return value;
      }
    }

    return value?.toString() ?? '';
  }
}

