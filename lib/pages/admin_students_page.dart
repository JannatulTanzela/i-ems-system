import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await _supabase.from('students').select(
        '*, profiles:user_id(email, full_name, role)',
      );

      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to load students: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _addStudent() {
    showDialog(
      context: context,
      builder: (context) => _StudentFormDialog(
        onSubmit: (data) async {
          try {
            // Create auth user
            final authResponse = await _supabase.auth.signUp(
              email: data['email'],
              password: data['password'],
            );

            if (authResponse.user != null) {
              // Create profile
              await _supabase.from('profiles').insert({
                'id': authResponse.user!.id,
                'email': data['email'],
                'role': 'Student',
                'full_name': data['full_name'],
                'username': data['username'],
              });

              // Create student record
              await _supabase.from('students').insert({
                'user_id': authResponse.user!.id,
                'registration_number': data['registration_number'],
                'roll_number': data['roll_number'],
                'class': data['class'],
                'date_of_birth': data['date_of_birth'],
                'guardian_name': data['guardian_name'],
                'guardian_phone': data['guardian_phone'],
                'address': data['address'],
              });

              _showSuccess('Student added successfully!');
              _fetchStudents();
            }
          } catch (e) {
            _showError('Error adding student: $e');
          }
        },
      ),
    );
  }

  void _editStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => _StudentFormDialog(
        isEdit: true,
        student: student,
        onSubmit: (data) async {
          try {
            await _supabase.from('students').update({
              'registration_number': data['registration_number'],
              'roll_number': data['roll_number'],
              'class': data['class'],
              'date_of_birth': data['date_of_birth'],
              'guardian_name': data['guardian_name'],
              'guardian_phone': data['guardian_phone'],
              'address': data['address'],
            }).eq('id', student['id']);

            _showSuccess('Student updated successfully!');
            _fetchStudents();
          } catch (e) {
            _showError('Error updating student: $e');
          }
        },
      ),
    );
  }

  void _deleteStudent(String studentId, String userId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabase.from('students').delete().eq('id', studentId);
                _showSuccess('Student deleted successfully!');
                _fetchStudents();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                _showError('Error deleting student: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addStudent,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Text(
                          'No students found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return _buildStudentCard(student);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['profiles']?['full_name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Reg: ${student['registration_number']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                      onPressed: () => _editStudent(student),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () =>
                          _deleteStudent(student['id'], student['user_id']),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Roll', student['roll_number'] ?? 'N/A'),
                _buildInfoItem('Class', student['class'] ?? 'N/A'),
                _buildInfoItem('Guardian', student['guardian_name'] ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _StudentFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? student;
  final Function(Map<String, dynamic>) onSubmit;

  const _StudentFormDialog({
    this.isEdit = false,
    this.student,
    required this.onSubmit,
  });

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _registrationController;
  late TextEditingController _rollController;
  late TextEditingController _classController;
  late TextEditingController _dobController;
  late TextEditingController _guardianController;
  late TextEditingController _guardianPhoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.student != null) {
      _fullNameController = TextEditingController(
        text: widget.student!['profiles']?['full_name'] ?? '',
      );
      _emailController = TextEditingController(
        text: widget.student!['profiles']?['email'] ?? '',
      );
      _usernameController = TextEditingController(
        text: widget.student!['profiles']?['username'] ?? '',
      );
      _passwordController = TextEditingController();
      _registrationController =
          TextEditingController(text: widget.student!['registration_number'] ?? '');
      _rollController = TextEditingController(text: widget.student!['roll_number'] ?? '');
      _classController = TextEditingController(text: widget.student!['class'] ?? '');
      _dobController = TextEditingController(text: widget.student!['date_of_birth'] ?? '');
      _guardianController =
          TextEditingController(text: widget.student!['guardian_name'] ?? '');
      _guardianPhoneController =
          TextEditingController(text: widget.student!['guardian_phone'] ?? '');
      _addressController = TextEditingController(text: widget.student!['address'] ?? '');
    } else {
      _fullNameController = TextEditingController();
      _emailController = TextEditingController();
      _usernameController = TextEditingController();
      _passwordController = TextEditingController();
      _registrationController = TextEditingController();
      _rollController = TextEditingController();
      _classController = TextEditingController();
      _dobController = TextEditingController();
      _guardianController = TextEditingController();
      _guardianPhoneController = TextEditingController();
      _addressController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _registrationController.dispose();
    _rollController.dispose();
    _classController.dispose();
    _dobController.dispose();
    _guardianController.dispose();
    _guardianPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Student' : 'Add New Student'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Full Name', _fullNameController),
            _buildTextField('Email', _emailController),
            _buildTextField('Username', _usernameController),
            if (!widget.isEdit) _buildTextField('Password', _passwordController),
            _buildTextField('Registration Number', _registrationController),
            _buildTextField('Roll Number', _rollController),
            _buildTextField('Class', _classController),
            _buildTextField('Date of Birth (YYYY-MM-DD)', _dobController),
            _buildTextField('Guardian Name', _guardianController),
            _buildTextField('Guardian Phone', _guardianPhoneController),
            _buildTextField('Address', _addressController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSubmit({
              'full_name': _fullNameController.text,
              'email': _emailController.text,
              'username': _usernameController.text,
              'password': _passwordController.text,
              'registration_number': _registrationController.text,
              'roll_number': _rollController.text,
              'class': _classController.text,
              'date_of_birth': _dobController.text,
              'guardian_name': _guardianController.text,
              'guardian_phone': _guardianPhoneController.text,
              'address': _addressController.text,
            });
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
