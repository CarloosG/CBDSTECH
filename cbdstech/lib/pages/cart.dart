import 'package:flutter/material.dart';
import 'home_page.dart'; // aquí está definido Producto

class CartItem {
  final Producto producto;
  int cantidad;

  CartItem({required this.producto, this.cantidad = 1});
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void add(Producto producto) {
    final index = _items.indexWhere((item) => item.producto == producto);
    if (index != -1) {
      _items[index].cantidad++;
    } else {
      _items.add(CartItem(producto: producto));
    }
    notifyListeners();
  }

  void decrease(Producto producto) {
    final index = _items.indexWhere((item) => item.producto == producto);
    if (index != -1) {
      if (_items[index].cantidad > 1) {
        _items[index].cantidad--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void remove(Producto producto) {
    _items.removeWhere((item) => item.producto == producto);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// Carrito global para acceder fácil sin provider
final CartModel cart = CartModel();
