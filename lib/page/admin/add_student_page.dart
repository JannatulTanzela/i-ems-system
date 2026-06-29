import 'package:flutter/material.dart';
import '../../services/student_auth_service.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();
  final departmentController = TextEditingController();
  final universityDepartmentController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  DateTime? selectedDateOfBirth;

  bool isLoading = false;

  Future<void> addStudent() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        fullNameController.text.isEmpty ||
        departmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await StudentAuthService.addStudentWithAuth(
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      fullName: fullNameController.text.trim(),
      department: departmentController.text.trim(),
      universityDepartment: universityDepartmentController.text.trim().isEmpty ? null : universityDepartmentController.text.trim(),
      bloodGroup: bloodGroupController.text.trim().isEmpty ? null : bloodGroupController.text.trim(),
      dateOfBirth: selectedDateOfBirth,
      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Student added successfully!")),
      );
      // Clear fields
      usernameController.clear();
      emailController.clear();
      fullNameController.clear();
      departmentController.clear();
      universityDepartmentController.clear();
      bloodGroupController.clear();
      phoneController.clear();
      addressController.clear();
      selectedDateOfBirth = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to add student")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.person_add_alt_1, color: Color(0xFF1976D2), size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Create student account',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a new student and create their login access in one step.',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: const [
                            Chip(label: Text('Required fields')),
                            Chip(label: Text('Instant access')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _buildTextField(usernameController, 'Username *', 'Enter username (will be password)', Icons.person),
                        const SizedBox(height: 14),
                        _buildTextField(emailController, 'Email *', 'Enter student email', Icons.email),
                        const SizedBox(height: 14),
                        _buildTextField(fullNameController, 'Full Name *', 'Enter student full name', Icons.badge),
                        const SizedBox(height: 14),
                        _buildTextField(departmentController, 'Department *', 'Enter department (CSE, EEE, etc)', Icons.school),
                        const SizedBox(height: 14),
                        _buildTextField(universityDepartmentController, 'University Department', 'e.g. Computer Science & Engineering', Icons.account_balance),
                        const SizedBox(height: 14),
                        _buildDatePickerField(),
                        const SizedBox(height: 14),
                        _buildTextField(bloodGroupController, 'Blood Group', 'e.g. O+, AB-', Icons.bloodtype),
                        const SizedBox(height: 14),
                        _buildTextField(phoneController, 'Phone (Optional)', 'Enter phone number', Icons.phone),
                        const SizedBox(height: 14),
                        _buildTextField(addressController, 'Address (Optional)', 'Enter address', Icons.location_on),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: Color(0xFF1976D2)),
                            SizedBox(width: 8),
                            Text('What happens next?', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Auth account is created with the email you enter.'),
                        _buildInfoRow('The username becomes the initial password for login.'),
                        _buildInfoRow('Student details are added to the database instantly.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : addStudent,
                    icon: isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(isLoading ? 'Creating...' : 'Add Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2)),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDateOfBirth ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => selectedDateOfBirth = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          hintText: 'Select date of birth',
          prefixIcon: const Icon(Icons.cake, color: Color(0xFF1976D2)),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2)),
        ),
        child: Text(
          selectedDateOfBirth == null
              ? 'Select date of birth'
              : '${selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${selectedDateOfBirth!.year}',
          style: TextStyle(color: selectedDateOfBirth == null ? Colors.grey.shade600 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    fullNameController.dispose();
    departmentController.dispose();
    universityDepartmentController.dispose();
    bloodGroupController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
