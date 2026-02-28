import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseInstance = Supabase.instance.client.auth.currentSession;