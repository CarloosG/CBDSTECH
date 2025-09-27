import 'package:cbdstech/pages/register_page.dart';
import 'package:cbdstech/pages/profile_page.dart'; // Agrega esta importación
import 'package:flutter/material.dart';

import 'package:cbdstech/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    try {
        await authService.signInWithEmailPassword(email, password);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
    }

    catch (e) {
      if(mounted) {ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ha ocurrido un error: $e')),
      );
    }
  }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: login,
            child: const Text('Login'),
          ),

          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => const RegisterPage()
              )),
            child:const Center(child: Text("No tienes cuenta? Registrate"))

          )




        ],
      ),
    );
  }
}