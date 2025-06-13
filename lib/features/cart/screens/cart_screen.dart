import 'package:flutter/material.dart';
import 'package:flutter_java_project/core/theme.dart';
import 'package:flutter_java_project/features/cart/models/cart_item_model.dart';
import 'package:flutter_java_project/features/cart/services/cart_service.dart';
import 'package:flutter_java_project/routes/app_routes.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    // Listen perubahan di service agar UI di-rebuild
    _cartService.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang Belanja'),
      ),
      body: _cartService.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('Keranjang Anda masih kosong.', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text('Ayo, isi dengan roti favoritmu!', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _cartService.items.length,
              itemBuilder: (context, index) {
                final cartItem = _cartService.items[index];
                return _buildCartItemTile(cartItem);
              },
            ),
      bottomNavigationBar: _cartService.items.isEmpty ? null : _buildCheckoutSection(context),
    );
  }

  // --- WIDGET INI YANG KITA PERBAIKI ---
  Widget _buildCartItemTile(CartItem cartItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Gambar Produk
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            // Menggunakan Image.network dan menambahkan errorBuilder
            child: Image.network(
              cartItem.product.imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, color: Colors.grey[400]),
                );
              },
            ),
          ),
          SizedBox(width: 16),
          
          // 2. Nama dan Harga Produk (Dibungkus Expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2, // Batasi 2 baris jika nama terlalu panjang
                  overflow: TextOverflow.ellipsis, // Tampilkan '...' jika terpotong
                ),
                SizedBox(height: 4),
                Text(
                  'Rp ${cartItem.product.price.toStringAsFixed(0)}',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),

          // 3. Tombol Pengatur Jumlah
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.remove_circle_outline),
                onPressed: () => _cartService.updateQuantity(cartItem.product.id, cartItem.quantity - 1),
              ),
              Text(
                '${cartItem.quantity}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.add_circle_outline),
                onPressed: () => _cartService.updateQuantity(cartItem.product.id, cartItem.quantity + 1),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildCheckoutSection(BuildContext context) {
    // Widget ini tidak ada perubahan
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 5, offset: Offset(0, -3),) ],
        borderRadius: BorderRadius.only( topLeft: Radius.circular(20), topRight: Radius.circular(20),),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Harga:', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Rp ${_cartService.totalPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pushNamed(context, AppRoutes.checkout); },
              child: Text('LANJUT KE CHECKOUT'),
            ),
          ),
        ],
      ),
    );
  }
}