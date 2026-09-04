import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_role.dart';
import '../../../shared/models/people.dart';

/// All Supabase Auth and identity reads live here.
///
/// Nothing in this class trusts the client for authorisation. The role is
/// read from `user_roles`, which only an administrator can write, and every
/// query is additionally filtered by row level security in Postgres.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// Emits on sign in, sign out, token refresh and user updates.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Session? get currentSession => _auth.currentSession;

  User? get currentUser => _auth.currentUser;

  /// Signs in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Registers a new account.
  ///
  /// The database trigger creates the matching profile row and grants the
  /// default `graduate` role. The role is deliberately NOT taken from
  /// [fullName] or any other client-supplied metadata, so a new account can
  /// never sign itself up as a mentor or administrator.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String registrationNumber,
    String? gender,
    String? wifaqId,
    String? instituteName,
  }) {
    return _auth.signUp(
      email: email.trim(),
      password: password,
      // The registration number is re-verified by the signup trigger. The
      // check the app performs first is a courtesy; this is what the database
      // actually enforces, so calling the API directly cannot bypass it.
      // The trigger re-verifies the number AND the name, and reads the
      // category, wifaq and institution from here. None of it is trusted for
      // authorisation: the role is decided by the database, never sent.
      data: <String, dynamic>{
        'full_name': fullName.trim(),
        'registration_number': registrationNumber.trim(),
        'gender': gender,
        'wifaq_id': wifaqId,
        'institute_name': instituteName?.trim(),
      },
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email.trim());

  /// Loads the signed-in user's profile, with institute and wifaq names.
  ///
  /// Returns null when no row is visible yet — which happens for the brief
  /// moment between account creation and the trigger committing.
  Future<AppUser?> loadProfile(String userId) async {
    final Map<String, dynamic>? row = await _client
        .from('profiles')
        .select('*, institutes(name), wifaqs(name)')
        .eq('id', userId)
        .maybeSingle();

    return row == null ? null : AppUser.fromMap(row);
  }

  /// Loads every role granted to the user.
  ///
  /// A user may legitimately hold more than one; the caller decides which
  /// one to land on.
  Future<List<AppRole>> loadRoles(String userId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId);

    return rows
        .map((Map<String, dynamic> row) => AppRole.fromId(row['role'] as String?))
        .whereType<AppRole>()
        .toList();
  }
}
