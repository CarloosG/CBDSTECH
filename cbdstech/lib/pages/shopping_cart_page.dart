import 'package:flutter/material.dart';
import 'cart.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carrito de Compras"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                "Aquí aparecerán los productos que agregues al carrito",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final producto = cart.items[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(producto.nombre),
                  subtitle: Text("\$${producto.precio.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        cart.remove(producto); // refresca solo la lista
                      });

                      // SnackBar para confirmación
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${producto.nombre} eliminado del carrito"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}