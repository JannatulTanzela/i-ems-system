import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('students').select(
        '*, profiles:user_id(email, full_name, username)',
      ).order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _allStudents = List<Map<String, dynamic>>.from(response);
        _filterStudents(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch Error: $e');
      _showError('Failed to load students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) {
          final fullName = (student['profiles']?['full_name'] ?? '').toString().toLowerCase();
          final regNo = (student['registration_number'] ?? '').toString().toLowerCase();
          final rollNo = (student['roll_number'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          
          return fullName.contains(searchLower) || 
                 regNo.contains(searchLower) || 
                 rollNo.contains(searchLower);
        }).toList();
      }
    });
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

  void _addStudent() {
    showDialog(
      context: context,
      builder: (context) => _StudentFormDialog(
        onSubmit: (data) async {
          try {
            final authResponse = await _supabase.auth.signUp(
              email: data['email'],
              password: data['password'],
            );

            if (authResponse.user != null) {
              await _supabase.from('profiles').insert({
                'id': authResponse.user!.id,
                'email': data['email'],
                'role': 'Student',
                'full_name': data['full_name'],
                'username': data['username'],
              });

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
            await _supabase.from('profiles').update({
              'full_name': data['full_name'],
              'username': data['username'],
            }).eq('id', student['user_id']);

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
        content: const Text('Are you sure you want to delete this student? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
        onRefresh: _fetchStudents,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Students',
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _searchController,
                    onChanged: _filterStudents,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Reg No or Roll No...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _allStudents.isEmpty ? 'No students found' : 'No matching students',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return _buildStudentCard(student);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
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
                        student['profiles']?['full_name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Reg: ${student['registration_number'] ?? 'N/A'}',
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
                      onPressed: () => _editStudent(student),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade700,
                      onPressed: () =>
                          _deleteStudent(student['id'], student['user_id']),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
  final _formKey = GlobalKey<FormState>();
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
    final s = widget.student;
    final p = s?['profiles'];
    
    _fullNameController = TextEditingController(text: p?['full_name'] ?? '');
    _emailController = TextEditingController(text: p?['email'] ?? '');
    _usernameController = TextEditingController(text: p?['username'] ?? '');
    _passwordController = TextEditingController();
    _registrationController = TextEditingController(text: s?['registration_number'] ?? '');
    _rollController = TextEditingController(text: s?['roll_number'] ?? '');
    _classController = TextEditingController(text: s?['class'] ?? '');
    _dobController = TextEditingController(text: s?['date_of_birth'] ?? '');
    _guardianController = TextEditingController(text: s?['guardian_name'] ?? '');
    _guardianPhoneController = TextEditingController(text: s?['guardian_phone'] ?? '');
    _addressController = TextEditingController(text: s?['address'] ?? '');
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
                'registration_number': _registrationController.text.trim(),
                'roll_number': _rollController.text.trim(),
                'class': _classController.text.trim(),
                'date_of_birth': _dobController.text.trim(),
                'guardian_name': _guardianController.text.trim(),
                'guardian_phone': _guardianPhoneController.text.trim(),
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
