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
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('teachers').select(
        '*, profiles:user_id(email, full_name, username)',
      ).order('created_at', ascending: false);

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
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
            // Update profile
            await _supabase.from('profiles').update({
              'full_name': data['full_name'],
              'username': data['username'],
            }).eq('id', teacher['user_id']);

            // Update teacher record
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
        content: const Text('Are you sure you want to delete this teacher? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchTeachers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Teachers',
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: CircularProgressIndicator(),
                    ))
                  : _teachers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50.0),
                            child: Column(
                              children: [
                                Icon(Icons.supervisor_account_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No teachers found',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
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
                        'Emp ID: ${teacher['employee_id'] ?? 'N/A'}',
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
                      icon: const Icon(Icons.edit_outlined),
                      color: Colors.blue.shade700,
                      onPressed: () => _editTeacher(teacher),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade700,
                      onPressed: () =>
                          _deleteTeacher(teacher['id'], teacher['user_id']),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Subject', teacher['subject'] ?? 'N/A'),
                _buildInfoItem('Qualification', teacher['qualification'] ?? 'N/A'),
                _buildInfoItem('Experience', '${teacher['experience_years'] ?? 0} yrs'),
              ],
            ),
            const SizedBox(height: 12),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
  final _formKey = GlobalKey<FormState>();
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
    final t = widget.teacher;
    final p = t?['profiles'];

    _fullNameController = TextEditingController(text: p?['full_name'] ?? '');
    _emailController = TextEditingController(text: p?['email'] ?? '');
    _usernameController = TextEditingController(text: p?['username'] ?? '');
    _passwordController = TextEditingController();
    _employeeIdController = TextEditingController(text: t?['employee_id'] ?? '');
    _subjectController = TextEditingController(text: t?['subject'] ?? '');
    _qualificationController = TextEditingController(text: t?['qualification'] ?? '');
    _experienceController = TextEditingController(text: t?['experience_years']?.toString() ?? '');
    _departmentController = TextEditingController(text: t?['department'] ?? '');
    _phoneController = TextEditingController(text: t?['phone'] ?? '');
    _addressController = TextEditingController(text: t?['address'] ?? '');
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
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Full Name', _fullNameController, required: true),
                _buildTextField('Email', _emailController, required: true, enabled: !widget.isEdit),
                _buildTextField('Username', _usernameController, required: true),
                if (!widget.isEdit) 
                  _buildTextField('Password', _passwordController, required: true, isPassword: true),
                const Divider(height: 30),
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit({
                'full_name': _fullNameController.text.trim(),
                'email': _emailController.text.trim(),
                'username': _usernameController.text.trim(),
                'password': _passwordController.text.trim(),
                'employee_id': _employeeIdController.text.trim(),
                'subject': _subjectController.text.trim(),
                'qualification': _qualificationController.text.trim(),
                'experience_years': _experienceController.text.trim(),
                'department': _departmentController.text.trim(),
                'phone': _phoneController.text.trim(),
                'address': _addressController.text.trim(),
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, bool isPassword = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: !enabled,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          if (isPassword && value != null && value.isNotEmpty && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }
}
