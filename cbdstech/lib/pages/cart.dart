import 'package:flutter/material.dart';
import 'home_page.dart'; // porque ahí está definido Producto

class CartModel extends ChangeNotifier {
  final List<Producto> _items = [];

  List<Producto> get items => _items;

  void add(Producto producto) {
    _items.add(producto);
    notifyListeners();
  }

  void remove(Producto producto) {
    _items.remove(producto);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// Carrito global para acceder fácil sin provider (más sencillo por ahora)
final CartModel cart = CartModel();
