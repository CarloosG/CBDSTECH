import 'package:cbdstech/auth/auth_service.dart';
import 'package:flutter/material.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPaswordController = TextEditingController();

  void signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPaswordController.text;
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
      .showSnackBar( const SnackBar(content: Text('Las contraseñas no coinciden')));
      
      return;
    }
    try {
      await authService.signUpWithEmailPassword(email, password);
      Navigator.pop(context);
    
    }
    catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Ha ocurrido un error: $e')));
    }
  }
}

  @override
  Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
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
          TextField(
            controller: _confirmPaswordController,
            decoration: const InputDecoration(labelText: 'Confirmar Password'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: signUp,
            child: const Text('Rregistrarse'),
          ),






        ],
      ),
    );
  }
}