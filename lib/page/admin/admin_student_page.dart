import 'package:flutter/material.dart';
import '../../db_con.dart';

class AdminStudentPage extends StatefulWidget {
  const AdminStudentPage({super.key});

  @override
  State<AdminStudentPage> createState() => _AdminStudentPageState();
}

class _AdminStudentPageState extends State<AdminStudentPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];

  Future<void> fetchStudents() async {
    final res = await DBCon.supabase.from('students').select();
    final data = List<Map<String, dynamic>>.from(res);
    setState(() {
      students = data;
      filteredStudents = data;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void updateFilter(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredStudents = students.where((student) {
        final fullName = (student['full_name'] ?? '').toString().toLowerCase();
        final username = (student['username'] ?? '').toString().toLowerCase();
        final uid = (student['student_uid'] ?? '').toString().toLowerCase();
        final department = (student['department'] ?? '').toString().toLowerCase();
        return fullName.contains(lowerQuery) ||
            username.contains(lowerQuery) ||
            uid.contains(lowerQuery) ||
            department.contains(lowerQuery);
      }).toList();
    });
  }

  String _formatDateValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      }
      return value;
    }
    return value.toString();
  }

  Future<void> _pickDate(BuildContext context, TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void openForm({Map<String, dynamic>? data}) {
    final username = TextEditingController(text: data?['username']);
    final fullName = TextEditingController(text: data?['full_name']);
    final email = TextEditingController(text: data?['email']);
    final studentUid = TextEditingController(text: data?['student_uid']);
    final dob = TextEditingController(text: _formatDateValue(data?['date_of_birth']));
    String selectedDepartment = (data?['department'] ?? 'CSE').toString();
    String selectedBloodGroup = (data?['blood'] ?? 'A+').toString();
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
                  data == null ? 'Add Student' : 'Edit Student',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _field('Username', username),
              _field('Full Name', fullName),
              _field('Email', email),
              _field('Student UID', studentUid),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: dob,
                  readOnly: true,
                  onTap: () => _pickDate(context, dob),
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'Pick a date',
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.6),
                    ),
                  ),
                ),
              ),
              _buildDropdownField(
                label: 'Department',
                value: selectedDepartment,
                items: const ['CSE', 'EEE', 'BBA', 'Civil', 'English', 'MBA', 'Other'],
                onChanged: (value) => selectedDepartment = value ?? 'CSE',
              ),
              _buildDropdownField(
                label: 'Blood Group',
                value: selectedBloodGroup,
                items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                onChanged: (value) => selectedBloodGroup = value ?? 'A+',
              ),
              _field('Father Name', fatherName),
              _field('Father Phone', fatherPhone),
              _field('Mother Name', motherName),
              _field('Mother Phone', motherPhone),
              _field('NID Number', nidNumber),
              _field('Address', address),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final dateOfBirthText = dob.text.trim();

                    if (dateOfBirthText.isNotEmpty && DateTime.tryParse(dateOfBirthText) == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid date format (YYYY-MM-DD)')),
                      );
                      return;
                    }

                    final payload = {
                      'username': username.text.trim(),
                      'full_name': fullName.text.trim(),
                      'email': email.text.trim(),
                      'student_uid': studentUid.text.trim(),
                      'date_of_birth': dateOfBirthText.isEmpty ? null : dateOfBirthText,
                      'department': selectedDepartment,
                      'blood': selectedBloodGroup,
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
                        await DBCon.supabase.from('students').update(payload).eq('id', data['id']);
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
                    fetchStudents();
                  },
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save Student'),
                ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.6),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
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
                            'Manage Students',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Search, edit, and organize student records',
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
                    hintText: 'Search by name, UID, or department',
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
                            const Icon(Icons.people_alt, color: Color(0xFF1E88E5)),
                            const SizedBox(width: 10),
                            Text('${students.length} students registered', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredStudents.isEmpty
                            ? const Center(child: Text('No students found'))
                            : ListView.builder(
                                itemCount: filteredStudents.length,
                                itemBuilder: (_, i) {
                                  final s = filteredStudents[i];
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
                                      title: Text(s['full_name'] ?? s['username'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('UID: ${s['student_uid'] ?? ''}\nDept: ${s['department'] ?? ''} • Blood: ${s['blood'] ?? ''}'),
                                      isThreeLine: true,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
                                            onPressed: () => openForm(data: s),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () => deleteStudent(s['id']),
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
        label: const Text('Add Student'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
    );
  }
}