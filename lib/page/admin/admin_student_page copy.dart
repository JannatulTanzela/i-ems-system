// import 'package:flutter/material.dart';
// import '../../db_con.dart'; // supabase instance

// class AdminStudentPage extends StatefulWidget {
//   const AdminStudentPage({super.key});

//   @override
//   State<AdminStudentPage> createState() => _AdminStudentPageState();
// }

// class _AdminStudentPageState extends State<AdminStudentPage> {
//   List<Map<String, dynamic>> students = [];

//   Future<void> fetchStudents() async {
//     final res = await DBCon.supabase.from('students').select();
//     setState(() => students = List<Map<String, dynamic>>.from(res));
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchStudents();
//   }

//   void openForm({Map<String, dynamic>? data}) {
//     final username = TextEditingController(text: data?['username']);
//     final fullName = TextEditingController(text: data?['full_name']);
//     final email = TextEditingController(text: data?['email']);
//     final studentUid = TextEditingController(text: data?['student_uid']);
//     final dob = TextEditingController(text: data?['date_of_birth']?.toString());
//     final department = TextEditingController(text: data?['department']);
//     final blood = TextEditingController(text: data?['blood']);
//     final fatherName = TextEditingController(text: data?['father_name']);
//     final fatherPhone = TextEditingController(text: data?['father_phone']);
//     final motherName = TextEditingController(text: data?['mother_name']);
//     final motherPhone = TextEditingController(text: data?['mother_phone']);
//     final nidNumber = TextEditingController(text: data?['nid_number']);
//     final address = TextEditingController(text: data?['address']);

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(data == null ? "Add Student" : "Edit Student"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: username,
//                 decoration: const InputDecoration(labelText: "Username"),
//               ),
//               TextField(
//                 controller: fullName,
//                 decoration: const InputDecoration(labelText: "Full Name"),
//               ),
//               TextField(
//                 controller: email,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: const InputDecoration(labelText: "Email"),
//               ),
//               TextField(
//                 controller: studentUid,
//                 decoration: const InputDecoration(labelText: "Student UID"),
//               ),
//               TextField(
//                 controller: dob,
//                 keyboardType: TextInputType.datetime,
//                 decoration: const InputDecoration(
//                   labelText: "Date of Birth (YYYY-MM-DD)",
//                 ),
//               ),
//               TextField(
//                 controller: department,
//                 decoration: const InputDecoration(labelText: "Department"),
//               ),
//               TextField(
//                 controller: blood,
//                 decoration: const InputDecoration(labelText: "Blood Group"),
//               ),
//               TextField(
//                 controller: fatherName,
//                 decoration: const InputDecoration(labelText: "Father's Name"),
//               ),
//               TextField(
//                 controller: fatherPhone,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(labelText: "Father's Phone"),
//               ),
//               TextField(
//                 controller: motherName,
//                 decoration: const InputDecoration(labelText: "Mother's Name"),
//               ),
//               TextField(
//                 controller: motherPhone,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(labelText: "Mother's Phone"),
//               ),
//               TextField(
//                 controller: nidNumber,
//                 decoration: const InputDecoration(labelText: "NID Number"),
//               ),
//               TextField(
//                 controller: address,
//                 decoration: const InputDecoration(labelText: "Address"),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               final dateOfBirthText = dob.text.trim();
//               if (dateOfBirthText.isNotEmpty &&
//                   DateTime.tryParse(dateOfBirthText) == null) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Invalid date format. Use YYYY-MM-DD.'),
//                   ),
//                 );
//                 return;
//               }

//               final payload = {
//                 'username': username.text.trim(),
//                 'full_name': fullName.text.trim(),
//                 'email': email.text.trim(),
//                 'student_uid': studentUid.text.trim(),
//                 'date_of_birth': dateOfBirthText.isEmpty
//                     ? null
//                     : dateOfBirthText,
//                 'department': department.text.trim(),
//                 'blood': blood.text.trim(),
//                 'father_name': fatherName.text.trim(),
//                 'father_phone': fatherPhone.text.trim(),
//                 'mother_name': motherName.text.trim(),
//                 'mother_phone': motherPhone.text.trim(),
//                 'nid_number': nidNumber.text.trim(),
//                 'address': address.text.trim(),
//               };

//               try {
//                 if (data == null) {
//                   await DBCon.supabase.from('students').insert(payload);
//                 } else {
//                   await DBCon.supabase
//                       .from('students')
//                       .update(payload)
//                       .eq('id', data['id']);
//                 }
//               } catch (error) {
//                 ScaffoldMessenger.of(
//                   context,
//                 ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
//                 return;
//               }

//               Navigator.pop(context);
//               fetchStudents();
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }

//   void deleteStudent(String id) async {
//     await DBCon.supabase.from('students').delete().eq('id', id);
//     fetchStudents();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Admin - Students")),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => openForm(),
//         child: const Icon(Icons.add),
//       ),
//       body: ListView.builder(
//         itemCount: students.length,
//         itemBuilder: (_, i) {
//           final s = students[i];
//           return ListTile(
//             title: Text(s['full_name'] ?? s['username'] ?? 'Unknown'),
//             subtitle: Text(
//               "UID: ${s['student_uid'] ?? ''} • Dept: ${s['department'] ?? ''} • Blood: ${s['blood'] ?? ''}",
//             ),
//             isThreeLine: true,
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () => openForm(data: s),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => deleteStudent(s['id'] as String),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
