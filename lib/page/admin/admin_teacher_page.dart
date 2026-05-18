import 'package:flutter/material.dart';
import '../../db_con.dart';

class AdminTeacherPage extends StatefulWidget {
  const AdminTeacherPage({super.key});

  @override
  State<AdminTeacherPage> createState() => _AdminTeacherPageState();
}

class _AdminTeacherPageState extends State<AdminTeacherPage> {
  List<Map<String, dynamic>> teachers = [];

  Future<void> fetchTeachers() async {
    final res = await DBCon.supabase.from('teachers').select();
    setState(() => teachers = List<Map<String, dynamic>>.from(res));
  }

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  void openForm({Map<String, dynamic>? data}) {
    final username = TextEditingController(text: data?['username']);
    final email = TextEditingController(text: data?['email']);
    final employeeId = TextEditingController(text: data?['employee_id']);
    final subject = TextEditingController(text: data?['subject']);
    final qualification = TextEditingController(text: data?['qualification']);
    final experienceYears = TextEditingController(
      text: data?['experience_years']?.toString(),
    );
    final department = TextEditingController(text: data?['department']);
    final phone = TextEditingController(text: data?['phone']);
    final address = TextEditingController(text: data?['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
            children: [

              Text(
                data == null ? "Add Teacher" : "Edit Teacher",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              _field("Username", username),
              _field("Email", email),
              _field("Employee ID", employeeId),
              _field("Subject", subject),
              _field("Qualification", qualification),
              _field("Experience Years", experienceYears),
              _field("Department", department),
              _field("Phone", phone),
              _field("Address", address),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  final payload = {
                    'username': username.text.trim(),
                    'email': email.text.trim(),
                    'employee_id': employeeId.text.trim(),
                    'subject': subject.text.trim(),
                    'qualification': qualification.text.trim(),
                    'experience_years':
                        int.tryParse(experienceYears.text) ?? 0,
                    'department': department.text.trim(),
                    'phone': phone.text.trim(),
                    'address': address.text.trim(),
                  };

                  try {
                    if (data == null) {
                      await DBCon.supabase.from('teachers').insert(payload);
                    } else {
                      await DBCon.supabase
                          .from('teachers')
                          .update(payload)
                          .eq('id', data['id']);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Save failed: $e")),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  fetchTeachers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Save"),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // 🔷 HEADER
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Manage Teachers",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔷 LIST
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: teachers.isEmpty
                      ? const Center(child: Text("No teachers found"))
                      : ListView.builder(
                          itemCount: teachers.length,
                          itemBuilder: (_, i) {
                            final t = teachers[i];

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF0288D1),
                                  child: Icon(Icons.person,
                                      color: Colors.white),
                                ),
                                title: Text(
                                  t['username'] ??
                                      t['email'] ??
                                      'Unknown',
                                ),
                                subtitle: Text(
                                  "${t['subject'] ?? ''}\nDept: ${t['department'] ?? ''} | Phone: ${t['phone'] ?? ''}",
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => openForm(data: t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          deleteTeacher(t['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0288D1),
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}