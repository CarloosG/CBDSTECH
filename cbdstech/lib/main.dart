import 'package:cbdstech/auth/auth_gate.dart';
import 'package:cbdstech/pages/home_page.dart';
import 'package:cbdstech/pages/login_page.dart';
import 'package:cbdstech/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {

  await Supabase.initialize(
    url: 'https://cxhydqqntjyqypdvoael.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4aHlkcXFudGp5cXlwZHZvYWVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5MjIzOTUsImV4cCI6MjA3NDQ5ODM5NX0.GnSljXy6_hhzEND1MvPAftwXYSDf5NU56bJq-HBo3pE', 
    );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     home: const LoginPage(),
     routes: {

      '/profile': (context) => const ProfilePage(),
      '/home': (context) => const HomePage(),
     },
    );
  }
}

