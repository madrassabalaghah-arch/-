import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

/// Application entry point.
///
/// Supabase is initialised before the first frame so a persisted session is
/// already restored by the time the router evaluates its first redirect.
/// Only the publishable key is compiled in; the service role key must never
/// appear in this application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      // Sessions survive a restart, which is what keeps the user signed in.
      autoRefreshToken: true,
    ),
  );

  runApp(
    const ProviderScope(
      child: MadrassaApp(),
    ),
  );
}
