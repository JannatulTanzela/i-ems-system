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
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

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
      phoneController.clear();
      addressController.clear();
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
        title: const Text('Add New Student'),
        backgroundColor: const Color(0xFF0288D1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Student",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Required Fields (*):",
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 15),

            // Username
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: "Username *",
                hintText: "Enter username (will be password)",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Email
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email *",
                hintText: "Enter student email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Full Name
            TextField(
              controller: fullNameController,
              decoration: InputDecoration(
                labelText: "Full Name *",
                hintText: "Enter student full name",
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Department
            TextField(
              controller: departmentController,
              decoration: InputDecoration(
                labelText: "Department *",
                hintText: "Enter department (CSE, EEE, etc)",
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Phone (Optional)
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Phone (Optional)",
                hintText: "Enter phone number",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Address (Optional)
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "Address (Optional)",
                hintText: "Enter address",
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Info Box
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "What happens when you add a student:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("1. Auth account created with:"),
                  Text("   • Email = the email you enter"),
                  Text("   • Password = the username you enter"),
                  SizedBox(height: 10),
                  Text("2. Student added to database with all info"),
                  SizedBox(height: 10),
                  Text("3. Student can now login with email + username"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : addStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Add Student",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    fullNameController.dispose();
    departmentController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
