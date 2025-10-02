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
                final item = cart.items[index]; // CartItem
                final producto = item.producto; // Producto dentro del CartItem

                return ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(producto.nombre),
                  subtitle: Text(
                    "\$${producto.precio.toStringAsFixed(2)} x ${item.cantidad}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            cart.decrease(producto);
                          });
                        },
                      ),
                      Text("${item.cantidad}"),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            cart.add(producto);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            cart.remove(producto);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "${producto.nombre} eliminado del carrito"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
