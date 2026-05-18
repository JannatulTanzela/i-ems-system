// import 'package:flutter/material.dart';
// import '../../db_con.dart';

// class AdminTeacherPage extends StatefulWidget {
//   const AdminTeacherPage({super.key});

//   @override
//   State<AdminTeacherPage> createState() => _AdminTeacherPageState();
// }

// class _AdminTeacherPageState extends State<AdminTeacherPage> {
//   List<Map<String, dynamic>> teachers = [];

//   Future<void> fetchTeachers() async {
//     final res = await DBCon.supabase.from('teachers').select();
//     setState(() => teachers = List<Map<String, dynamic>>.from(res));
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchTeachers();
//   }

//   void openForm({Map<String, dynamic>? data}) {
//     final username = TextEditingController(text: data?['username']);
//     final email = TextEditingController(text: data?['email']);
//     final employeeId = TextEditingController(text: data?['employee_id']);
//     final subject = TextEditingController(text: data?['subject']);
//     final qualification = TextEditingController(text: data?['qualification']);
//     final experienceYears = TextEditingController(
//       text: data?['experience_years']?.toString(),
//     );
//     final department = TextEditingController(text: data?['department']);
//     final phone = TextEditingController(text: data?['phone']);
//     final address = TextEditingController(text: data?['address']);

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(data == null ? "Add Teacher" : "Edit Teacher"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: username,
//                 decoration: const InputDecoration(labelText: "Username"),
//               ),
//               TextField(
//                 controller: email,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: const InputDecoration(labelText: "Email"),
//               ),
//               TextField(
//                 controller: employeeId,
//                 decoration: const InputDecoration(labelText: "Employee ID"),
//               ),
//               TextField(
//                 controller: subject,
//                 decoration: const InputDecoration(labelText: "Subject"),
//               ),
//               TextField(
//                 controller: qualification,
//                 decoration: const InputDecoration(labelText: "Qualification"),
//               ),
//               TextField(
//                 controller: experienceYears,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(
//                   labelText: "Experience Years",
//                 ),
//               ),
//               TextField(
//                 controller: department,
//                 decoration: const InputDecoration(labelText: "Department"),
//               ),
//               TextField(
//                 controller: phone,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(labelText: "Phone"),
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
//               final payload = {
//                 'username': username.text.trim(),
//                 'email': email.text.trim(),
//                 'employee_id': employeeId.text.trim(),
//                 'subject': subject.text.trim(),
//                 'qualification': qualification.text.trim(),
//                 'experience_years': int.tryParse(experienceYears.text) ?? 0,
//                 'department': department.text.trim(),
//                 'phone': phone.text.trim(),
//                 'address': address.text.trim(),
//               };

//               if (data == null) {
//                 await DBCon.supabase.from('teachers').insert(payload);
//               } else {
//                 await DBCon.supabase
//                     .from('teachers')
//                     .update(payload)
//                     .eq('id', data['id']);
//               }

//               Navigator.pop(context);
//               fetchTeachers();
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }

//   void deleteTeacher(String id) async {
//     await DBCon.supabase.from('teachers').delete().eq('id', id);
//     fetchTeachers();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Admin - Teachers")),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => openForm(),
//         child: const Icon(Icons.add),
//       ),
//       body: ListView.builder(
//         itemCount: teachers.length,
//         itemBuilder: (_, i) {
//           final t = teachers[i];
//           return ListTile(
//             title: Text(t['username'] ?? t['email'] ?? 'Unknown'),
//             subtitle: Text(
//               "${t['subject'] ?? ''} • ${t['department'] ?? ''} • ${t['phone'] ?? ''}",
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () => openForm(data: t),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => deleteTeacher(t['id'] as String),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
