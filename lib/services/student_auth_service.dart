import 'package:supabase_flutter/supabase_flutter.dart';
import '../db_con.dart';

class StudentAuthService {
  /// Add Student to Database + Create Auth Account
  /// Email = student's email
  /// Password = student's username
  static Future<bool> addStudentWithAuth({
    required String username,
    required String email,
    required String fullName,
    required String department,
    String? universityDepartment,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? phone,
    String? address,
  }) async {
    try {
      // Step 1: Create Auth Account first
      print('Step 1: Creating auth account for $email...');
      final authResponse = await DBCon.supabase.auth.signUp(
        email: email,
        password: username, // password = username
      );

      if (authResponse.user == null) {
        print('Error: Auth account creation failed');
        return false;
      }

      print('✅ Auth account created: $email');
      final userId = authResponse.user!.id;

      // Step 2: Add to students table
      print('Step 2: Adding student to database...');
      await DBCon.supabase.from('students').insert({
        'user_id': userId,
        'username': username,
        'email': email,
        'full_name': fullName,
        'department': department,
        'university_department': universityDepartment,
        'blood': bloodGroup,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'phone': phone,
        'address': address,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Student added to database');
      return true;

    } catch (e) {
      print('❌ Error adding student: $e');
      return false;
    }
  }

  /// Get all students
  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await DBCon.supabase
          .from('students')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  /// Delete student and their auth account
  static Future<bool> deleteStudentWithAuth(String userId, String email) async {
    try {
      // Step 1: Delete from students table
      await DBCon.supabase
          .from('students')
          .delete()
          .eq('user_id', userId);

      print('✅ Student deleted from database');

      // Note: Auth user deletion should be done from admin panel
      // as it requires special permissions
      return true;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  /// Update student info
  static Future<bool> updateStudent({
    required String userId,
    String? fullName,
    String? phone,
    String? address,
    String? department,
  }) async {
    try {
      await DBCon.supabase
          .from('students')
          .update({
            if (fullName != null) 'full_name': fullName,
            if (phone != null) 'phone': phone,
            if (address != null) 'address': address,
            if (department != null) 'department': department,
          })
          .eq('user_id', userId);

      print('✅ Student updated');
      return true;
    } catch (e) {
      print('Error updating student: $e');
      return false;
    }
  }
}
