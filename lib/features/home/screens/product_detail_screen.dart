import 'package:flutter/material.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import 'package:flutter_java_project/core/theme.dart';
import 'package:flutter_java_project/features/cart/services/cart_service.dart';
import 'package:flutter_java_project/features/home/models/product_model.dart';
import 'package:flutter_java_project/routes/app_routes.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  
  ProductDetailScreen({required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();
  final PocketBaseService _pbService = PocketBaseService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    if (_pbService.isSignedIn) {
      _isAdmin = _pbService.pb.authStore.model.getStringValue('role') == 'admin';
    }
  }
  
  void _deleteProduct() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus produk "${widget.product.name}"?'),
          actions: <Widget>[
            TextButton(child: Text('Batal'), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(child: Text('Hapus', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _pbService.deleteProduct(widget.product.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil dihapus'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus produk: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'product_image_${widget.product.id}',
              child: Image.network(
                widget.product.imagePath,
                height: MediaQuery.of(context).size.height * 0.45,
                fit: BoxFit.cover,
                 errorBuilder: (c, e, s) => Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Deskripsi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isAdmin
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.delete_outline),
                      label: Text('HAPUS'),
                      onPressed: _deleteProduct,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.edit_outlined),
                      label: Text('EDIT'),
                      onPressed: () {
                        // --- PERBAIKAN ERROR 3 ---
                        // Menggunakan nama rute yang benar
                        Navigator.pushNamed(context, AppRoutes.editProduct, arguments: widget.product);
                      },
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                icon: Icon(Icons.add_shopping_cart),
                label: Text('TAMBAH KE KERANJANG'),
                onPressed: () {
                  _cartService.addProduct(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.product.name} telah ditambahkan'), backgroundColor: AppTheme.primaryColor),
                  );
                },
              ),
      ),
    );
  }
}