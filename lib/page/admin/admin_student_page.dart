import 'package:flutter/material.dart';
import '../../db_con.dart';

class AdminStudentPage extends StatefulWidget {
  const AdminStudentPage({super.key});

  @override
  State<AdminStudentPage> createState() => _AdminStudentPageState();
}

class _AdminStudentPageState extends State<AdminStudentPage> {
  List<Map<String, dynamic>> students = [];

  Future<void> fetchStudents() async {
    final res = await DBCon.supabase.from('students').select();
    setState(() => students = List<Map<String, dynamic>>.from(res));
  }

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  void openForm({Map<String, dynamic>? data}) {
    final username = TextEditingController(text: data?['username']);
    final fullName = TextEditingController(text: data?['full_name']);
    final email = TextEditingController(text: data?['email']);
    final studentUid = TextEditingController(text: data?['student_uid']);
    final dob = TextEditingController(text: data?['date_of_birth']?.toString());
    final department = TextEditingController(text: data?['department']);
    final blood = TextEditingController(text: data?['blood']);
    final fatherName = TextEditingController(text: data?['father_name']);
    final fatherPhone = TextEditingController(text: data?['father_phone']);
    final motherName = TextEditingController(text: data?['mother_name']);
    final motherPhone = TextEditingController(text: data?['mother_phone']);
    final nidNumber = TextEditingController(text: data?['nid_number']);
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
                data == null ? "Add Student" : "Edit Student",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              _field("Username", username),
              _field("Full Name", fullName),
              _field("Email", email),
              _field("Student UID", studentUid),
              _field("Date of Birth (YYYY-MM-DD)", dob),
              _field("Department", department),
              _field("Blood Group", blood),
              _field("Father Name", fatherName),
              _field("Father Phone", fatherPhone),
              _field("Mother Name", motherName),
              _field("Mother Phone", motherPhone),
              _field("NID Number", nidNumber),
              _field("Address", address),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  final dateOfBirthText = dob.text.trim();

                  if (dateOfBirthText.isNotEmpty &&
                      DateTime.tryParse(dateOfBirthText) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid date format (YYYY-MM-DD)'),
                      ),
                    );
                    return;
                  }

                  final payload = {
                    'username': username.text.trim(),
                    'full_name': fullName.text.trim(),
                    'email': email.text.trim(),
                    'student_uid': studentUid.text.trim(),
                    'date_of_birth':
                        dateOfBirthText.isEmpty ? null : dateOfBirthText,
                    'department': department.text.trim(),
                    'blood': blood.text.trim(),
                    'father_name': fatherName.text.trim(),
                    'father_phone': fatherPhone.text.trim(),
                    'mother_name': motherName.text.trim(),
                    'mother_phone': motherPhone.text.trim(),
                    'nid_number': nidNumber.text.trim(),
                    'address': address.text.trim(),
                  };

                  try {
                    if (data == null) {
                      await DBCon.supabase.from('students').insert(payload);
                    } else {
                      await DBCon.supabase
                          .from('students')
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
                  fetchStudents();
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

  void deleteStudent(dynamic id) async {
    await DBCon.supabase.from('students').delete().eq('id', id);
    fetchStudents();
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
                    Icon(Icons.school, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Manage Students",
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
                  child: students.isEmpty
                      ? const Center(child: Text("No students found"))
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (_, i) {
                            final s = students[i];

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF0288D1),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  s['full_name'] ??
                                      s['username'] ??
                                      'Unknown',
                                ),
                                subtitle: Text(
                                  "UID: ${s['student_uid'] ?? ''}\nDept: ${s['department'] ?? ''} | Blood: ${s['blood'] ?? ''}",
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => openForm(data: s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          deleteStudent(s['id']),
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