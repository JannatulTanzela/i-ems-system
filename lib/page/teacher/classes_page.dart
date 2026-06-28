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
        isLoading = false;
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
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: color[700]!, width: 5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: color[100],
                            child: Icon(Icons.class_, color: color[700], size: 28),
                          ),
                          title: Text(
                            classItem['class_name'] ?? 'Unnamed Class',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.code, classItem['class_code'] ?? 'N/A'),
                              const SizedBox(height: 4),
                              _buildInfoRow(Icons.school, classItem['subject'] ?? 'N/A'),
                              const SizedBox(height: 4),
                              _buildInfoRow(Icons.door_front_door, classItem['room'] ?? 'N/A'),
                            ],
                          ),
                          trailing: PopupMenuButton(
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

