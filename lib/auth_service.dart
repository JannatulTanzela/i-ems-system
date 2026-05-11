import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email, password, and role
  Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Store user role and full name in profiles table
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'role': role,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        });

        return {
          'success': true,
          'user': response.user,
          'role': role,
          'fullName': fullName,
        };
      }

      return {'success': false, 'message': 'Sign up failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch user profile to get role
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        return {
          'success': true,
          'user': response.user,
          'role': profileData['role'],
          'fullName': profileData['full_name'],
          'email': profileData['email'],
        };
      }

      return {'success': false, 'message': 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login with username/ID (email as fallback)
  Future<Map<String, dynamic>?> loginWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      // First, try to find user by username in profiles
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (profileData == null) {
        return {'success': false, 'message': 'User not found'};
      }

      // Then authenticate with email
      final response = await _supabase.auth.signInWithPassword(
        email: profileData['email'],
        password: password,
      );

      if (response.user != null) {
        return {
          'success': true,
          'user': response.user,
          'role': profileData['role'],
          'fullName': profileData['full_name'],
          'email': profileData['email'],
        };
      }

      return {'success': false, 'message': 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Get current user session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get user role from profiles
  Future<String?> getUserRole(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return data['role'];
    } catch (e) {
      return null;
    }
  }

  // Get full user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return data;
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentSession != null;
  }

  // Listen to auth state changes
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
}
