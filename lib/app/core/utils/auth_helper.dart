import 'package:supabase_flutter/supabase_flutter.dart';

class AuthHelper {
  static String get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';
}
