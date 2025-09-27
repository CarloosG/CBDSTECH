import 'package:cbdstech/auth/auth_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  void logout() async {
    await authService.signOut();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUserEmail = authService.getCurrentUserEmail();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout
          ),
        ],
      ),
      body:  Center(
        child: Text(currentUserEmail.toString()),
      ),
    );
  }
}