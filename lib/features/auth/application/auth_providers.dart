import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_role.dart';
import '../../../shared/models/people.dart';
import '../data/auth_repository.dart';

/// The Supabase client, initialised in main().
final Provider<SupabaseClient> supabaseClientProvider =
    Provider<SupabaseClient>((Ref ref) => Supabase.instance.client);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
  (Ref ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

/// Raw auth events from Supabase. The session is persisted by the SDK, so
/// this fires with the restored session on a cold start too.
final StreamProvider<AuthState> authStateChangesProvider =
    StreamProvider<AuthState>(
  (Ref ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
);

/// Who is signed in, and what they are allowed to be.
class AppSession {
  const AppSession({
    required this.user,
    required this.profile,
    required this.roles,
  });

  final User user;

  /// Null only in the moment between sign-up and the profile trigger
  /// committing; the UI shows a loading state rather than guessing.
  final AppUser? profile;

  final List<AppRole> roles;

  /// The role whose area the user lands in.
  AppRole? get primaryRole => AppRole.highest(roles);

  bool get isAdmin => roles.contains(AppRole.admin);
  bool get isMentor => roles.contains(AppRole.mentor);
  bool get isGraduate => roles.contains(AppRole.graduate);

  /// Name for the header. Falls back to the email local part so the greeting
  /// is never blank while a profile is still filling in.
  String get displayName {
    final String? name = profile?.fullName;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final String email = user.email ?? '';
    return email.contains('@') ? email.split('@').first : email;
  }
}

/// The signed-in session, or null when signed out.
///
/// Rebuilds whenever Supabase reports an auth change, so signing out
/// anywhere in the app immediately invalidates every dependent screen.
class AppSessionNotifier extends AsyncNotifier<AppSession?> {
  @override
  Future<AppSession?> build() async {
    // Re-run on every auth event.
    ref.watch(authStateChangesProvider);

    final AuthRepository repository = ref.watch(authRepositoryProvider);
    final User? user = repository.currentUser;
    if (user == null) {
      return null;
    }

    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      repository.loadProfile(user.id),
      repository.loadRoles(user.id),
    ]);

    return AppSession(
      user: user,
      profile: results[0] as AppUser?,
      roles: (results[1] as List<AppRole>?) ?? const <AppRole>[],
    );
  }

  /// Re-reads the profile and roles, for example after editing the profile.
  Future<void> refresh() async {
    state = const AsyncValue<AppSession?>.loading();
    state = await AsyncValue.guard(build);
  }

  Future<void> signIn({required String email, required String password}) async {
    await ref.read(authRepositoryProvider).signIn(
          email: email,
          password: password,
        );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String registrationNumber,
  }) async {
    await ref.read(authRepositoryProvider).signUp(
          email: email,
          password: password,
          fullName: fullName,
          registrationNumber: registrationNumber,
        );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final AsyncNotifierProvider<AppSessionNotifier, AppSession?> appSessionProvider =
    AsyncNotifierProvider<AppSessionNotifier, AppSession?>(
  AppSessionNotifier.new,
);

/// The current user's role, or null when signed out or still loading.
final Provider<AppRole?> currentRoleProvider = Provider<AppRole?>(
  (Ref ref) => ref.watch(appSessionProvider).value?.primaryRole,
);

/// The current user's profile, or null when signed out or still loading.
final Provider<AppUser?> currentProfileProvider = Provider<AppUser?>(
  (Ref ref) => ref.watch(appSessionProvider).value?.profile,
);
