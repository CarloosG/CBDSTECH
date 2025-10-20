import 'package:cbdstech/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  DateTime? _fechaNacimiento;
  String _rolSeleccionado = 'cliente'; // Por defecto cliente
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _ciudadController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  void signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Registrar usuario en Auth
      final authResponse = await authService.signUpWithEmailPassword(email, password);
      
      // 2. Insertar datos en la tabla usuario CON EL ROL SELECCIONADO
      final userId = authResponse.user?.id;
      
      if (userId != null) {
        await Supabase.instance.client.from('usuario').insert({
          'id': userId,
          'nombre': _nombreController.text.trim(),
          'email': email,
          'ciudad': _ciudadController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'fecha_nacimiento': _fechaNacimiento?.toIso8601String(),
          'rol': _rolSeleccionado, 
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Cuenta creada exitosamente como $_rolSeleccionado!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ha ocurrido un error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_alt_1,
                    size: 100, color: Colors.blue),
                const SizedBox(height: 24),

                Text(
                  "Crear cuenta",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 32),

                // Nombre completo
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: "Nombre completo",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de cuenta',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Row(
                                children: [
                                  Icon(Icons.person, 
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Cliente'),
                                ],
                              ),
                              value: 'cliente',
                              groupValue: _rolSeleccionado,
                              onChanged: (value) {
                                setState(() {
                                  _rolSeleccionado = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Admin'),
                                ],
                              ),
                              value: 'admin',
                              groupValue: _rolSeleccionado,
                              onChanged: (value) {
                                setState(() {
                                  _rolSeleccionado = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ciudad
                TextFormField(
                  controller: _ciudadController,
                  decoration: InputDecoration(
                    labelText: "Ciudad",
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Dirección
                TextFormField(
                  controller: _direccionController,
                  decoration: InputDecoration(
                    labelText: "Dirección",
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Fecha de nacimiento
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Fecha de nacimiento",
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    child: Text(
                      _fechaNacimiento == null
                          ? 'Selecciona tu fecha de nacimiento'
                          : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                      style: TextStyle(
                        color: _fechaNacimiento == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirmar contraseña",
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Indicador visual del rol seleccionado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _rolSeleccionado == 'admin'
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _rolSeleccionado == 'admin'
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _rolSeleccionado == 'admin'
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: _rolSeleccionado == 'admin'
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _rolSeleccionado == 'admin'
                              ? ' Registrándote como Administrador\nTendrás acceso al panel de administración'
                              : ' Registrándote como Cliente\nPodrás realizar compras en la tienda',
                          style: TextStyle(
                            fontSize: 12,
                            color: _rolSeleccionado == 'admin'
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: _rolSeleccionado == 'admin'
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _rolSeleccionado == 'admin'
                              ? "Crear cuenta de Admin"
                              : "Crear cuenta de Cliente",
                        ),
                      ),
                const SizedBox(height: 16),

                // Link al login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿Ya tienes cuenta? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        "Inicia sesión",
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}