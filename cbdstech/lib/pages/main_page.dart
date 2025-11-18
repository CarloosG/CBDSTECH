import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'shopping_cart_page.dart';
import 'admin_orders_page.dart';
import 'client_orders_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        final response =
            await Supabase.instance.client
                .from('usuario')
                .select('rol')
                .eq('id', userId)
                .single();

        setState(() {
          _userRole = response['rol'] as String?;
          _isLoadingRole = false;
          if (_userRole == 'admin') {
            _selectedIndex = 0; // Admin tab por defecto
          }
        });
      } else {
        setState(() {
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRole = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar rol: $e')));
      }
    }
  }

  // Lista de páginas según el rol
  List<Widget> get _pages {
    if (_userRole == 'admin') {
      return const [
        AdminOrdersPage(), // Vista de administrador
        ProfilePage(),
      ];
    } else {
      return const [
        HomePage(),
        ShoppingCartPage(),
        ClientOrdersPage(),
        ProfilePage(),
      ];
    }
  }

  // Items del BottomNavigationBar según el rol
  List<BottomNavigationBarItem> get _navigationItems {
    if (_userRole == 'admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Carrito',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: _navigationItems,
      ),
    );
  }
}
