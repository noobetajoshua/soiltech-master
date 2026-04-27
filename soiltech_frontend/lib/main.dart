import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://gsrmmkazxenliwxppivo.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdzcm1ta2F6eGVubGl3eHBwaXZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MzgxMjMsImV4cCI6MjA5MjExNDEyM30.KiSDWLCbET70FumEDEp56KKD6Xa6atsr1feRO3UR9ow',
    );
  } catch (e) {
    debugPrint('[Supabase] Initialization failed: $e');
  }

  runApp(const SoilTechApp());
}
