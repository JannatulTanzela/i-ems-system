import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminTeachersPage extends StatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  State<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends State<AdminTeachersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      final response = await _supabase.from('teachers').select(
        '*, profiles:user_id(email, full_name, role)',
      );

      setState(() {
        _teachers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to load teachers: $e');
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

  void _addTeacher() {
    showDialog(
      context: context,
      builder: (context) => _TeacherFormDialog(
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
                'role': 'Teacher',
                'full_name': data['full_name'],
                'username': data['username'],
              });

              // Create teacher record
              await _supabase.from('teachers').insert({
                'user_id': authResponse.user!.id,
                'employee_id': data['employee_id'],
                'subject': data['subject'],
                'qualification': data['qualification'],
                'experience_years': int.tryParse(data['experience_years'] ?? '0') ?? 0,
                'department': data['department'],
                'phone': data['phone'],
                'address': data['address'],
              });

              _showSuccess('Teacher added successfully!');
              _fetchTeachers();
            }
          } catch (e) {
            _showError('Error adding teacher: $e');
          }
        },
      ),
    );
  }

  void _editTeacher(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => _TeacherFormDialog(
        isEdit: true,
        teacher: teacher,
        onSubmit: (data) async {
          try {
            await _supabase.from('teachers').update({
              'employee_id': data['employee_id'],
              'subject': data['subject'],
              'qualification': data['qualification'],
              'experience_years': int.tryParse(data['experience_years'] ?? '0') ?? 0,
              'department': data['department'],
              'phone': data['phone'],
              'address': data['address'],
            }).eq('id', teacher['id']);

            _showSuccess('Teacher updated successfully!');
            _fetchTeachers();
          } catch (e) {
            _showError('Error updating teacher: $e');
          }
        },
      ),
    );
  }

  void _deleteTeacher(String teacherId, String userId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: const Text('Are you sure you want to delete this teacher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabase.from('teachers').delete().eq('id', teacherId);
                _showSuccess('Teacher deleted successfully!');
                _fetchTeachers();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                _showError('Error deleting teacher: $e');
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
                  'Teachers Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addTeacher,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
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
                : _teachers.isEmpty
                    ? Center(
                        child: Text(
                          'No teachers found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = _teachers[index];
                          return _buildTeacherCard(teacher);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
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
                        teacher['profiles']?['full_name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Emp ID: ${teacher['employee_id']}',
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
                      onPressed: () => _editTeacher(teacher),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () =>
                          _deleteTeacher(teacher['id'], teacher['user_id']),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Subject', teacher['subject'] ?? 'N/A'),
                _buildInfoItem('Qualification', teacher['qualification'] ?? 'N/A'),
                _buildInfoItem('Experience', '${teacher['experience_years'] ?? 0} yrs'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Department', teacher['department'] ?? 'N/A'),
                _buildInfoItem('Phone', teacher['phone'] ?? 'N/A'),
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

class _TeacherFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? teacher;
  final Function(Map<String, dynamic>) onSubmit;

  const _TeacherFormDialog({
    this.isEdit = false,
    this.teacher,
    required this.onSubmit,
  });

  @override
  State<_TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<_TeacherFormDialog> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _employeeIdController;
  late TextEditingController _subjectController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.teacher != null) {
      _fullNameController = TextEditingController(
        text: widget.teacher!['profiles']?['full_name'] ?? '',
      );
      _emailController = TextEditingController(
        text: widget.teacher!['profiles']?['email'] ?? '',
      );
      _usernameController = TextEditingController(
        text: widget.teacher!['profiles']?['username'] ?? '',
      );
      _passwordController = TextEditingController();
      _employeeIdController =
          TextEditingController(text: widget.teacher!['employee_id'] ?? '');
      _subjectController = TextEditingController(text: widget.teacher!['subject'] ?? '');
      _qualificationController =
          TextEditingController(text: widget.teacher!['qualification'] ?? '');
      _experienceController = TextEditingController(
        text: widget.teacher!['experience_years']?.toString() ?? '',
      );
      _departmentController =
          TextEditingController(text: widget.teacher!['department'] ?? '');
      _phoneController = TextEditingController(text: widget.teacher!['phone'] ?? '');
      _addressController = TextEditingController(text: widget.teacher!['address'] ?? '');
    } else {
      _fullNameController = TextEditingController();
      _emailController = TextEditingController();
      _usernameController = TextEditingController();
      _passwordController = TextEditingController();
      _employeeIdController = TextEditingController();
      _subjectController = TextEditingController();
      _qualificationController = TextEditingController();
      _experienceController = TextEditingController();
      _departmentController = TextEditingController();
      _phoneController = TextEditingController();
      _addressController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _subjectController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Teacher' : 'Add New Teacher'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Full Name', _fullNameController),
            _buildTextField('Email', _emailController),
            _buildTextField('Username', _usernameController),
            if (!widget.isEdit) _buildTextField('Password', _passwordController),
            _buildTextField('Employee ID', _employeeIdController),
            _buildTextField('Subject', _subjectController),
            _buildTextField('Qualification', _qualificationController),
            _buildTextField('Experience (Years)', _experienceController),
            _buildTextField('Department', _departmentController),
            _buildTextField('Phone', _phoneController),
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
              'employee_id': _employeeIdController.text,
              'subject': _subjectController.text,
              'qualification': _qualificationController.text,
              'experience_years': _experienceController.text,
              'department': _departmentController.text,
              'phone': _phoneController.text,
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
