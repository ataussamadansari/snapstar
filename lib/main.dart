import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:snapstar/app/data/services/storage_services.dart';
import 'package:snapstar/firebase_options.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hide nav bar + status bar (immersive sticky)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Token listener: Jab bhi token refresh hoga, ye auto-run karega
  FirebaseAuth.instance.idTokenChanges().listen((User? user) async {
    if (user != null) {
      String? token = await user.getIdToken();
      if (token != null) {
        StorageServices.to.setToken(token);
      }
    }
  });

  runApp(const MyApp());
}
