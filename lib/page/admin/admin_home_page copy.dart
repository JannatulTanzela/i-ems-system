// import 'package:flutter/material.dart';
// import 'admin_student_page.dart';
// import 'admin_teacher_page.dart';

// class AdminHomePage extends StatelessWidget {
//   const AdminHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Admin Dashboard")),
//       body: Column(
//         children: [

//           ListTile(
//             title: const Text("Manage Students"),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const AdminStudentPage()),
//               );
//             },
//           ),

//           ListTile(
//             title: const Text("Manage Teachers"),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const AdminTeacherPage()),
//               );
//             },
//           ),

//         ],
//       ),
//     );
//   }
// }