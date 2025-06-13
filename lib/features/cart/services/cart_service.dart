// lib/features/cart/services/cart_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_java_project/features/cart/models/cart_item_model.dart';
import 'package:flutter_java_project/features/home/models/product_model.dart';

class CartService extends ChangeNotifier {
  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addProduct(Product product) {
    // Cek apakah produk sudah ada di keranjang
    for (var item in _items) {
      if (item.product.id == product.id) {
        item.quantity++;
        notifyListeners(); // Memberi tahu widget yang listen bahwa ada perubahan
        return;
      }
    }
    // Jika tidak ada, tambahkan item baru
    _items.add(CartItem(product: product));
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }
  
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(productId);
      return;
    }
    for (var item in _items) {
      if (item.product.id == productId) {
        item.quantity = newQuantity;
        notifyListeners();
        return;
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}