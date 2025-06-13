// lib/features/home/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_java_project/features/admin/screens/create_product_screen.dart';
import 'package:flutter_java_project/features/home/models/product_model.dart';
import 'package:flutter_java_project/features/home/screens/product_detail_screen.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  
  String _searchQuery = '';
  String? _selectedCategory;
  final _searchController = TextEditingController();
  Timer? _debounce;
  
  // --- PENAMBAHAN STATE UNTUK ADMIN ---
  bool _isAdmin = false;

  final List<String> _categories = ['Roti', 'Kue', 'Pastry', 'Minuman'];
  
  @override
  void initState() {
    super.initState();
    _checkUserRole(); // <-- Panggil pengecekan role
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }
  
  // --- PENAMBAHAN FUNGSI UNTUK CEK ROLE ---
  void _checkUserRole() {
    if (_pbService.isSignedIn) {
      final user = _pbService.pb.authStore.model;
      if (mounted) {
        setState(() {
          _isAdmin = (user?.data['role'] == 'admin');
        });
      }
    }
  }
  
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  // --- PENAMBAHAN FUNGSI UNTUK REFRESH ---
  void _refreshProducts() {
    setState(() {
      // Cukup setState kosong, karena FutureBuilder akan otomatis
      // membangun ulang Future-nya berdasarkan key yang berubah atau state yang di-refresh.
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Roti Bahagia'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshProducts(),
        child: Column(
          children: [
            // Bagian UI untuk Search dan Filter (kode Anda sudah bagus)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari roti atau kue...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0)
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 35,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : null;
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: AppTheme.accentColor.withOpacity(0.8),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                            checkmarkColor: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bagian Daftar Produk
            Expanded(
              child: FutureBuilder(
                key: ValueKey('$_searchQuery$_selectedCategory'),
                future: _pbService.getProducts(searchQuery: _searchQuery, category: _selectedCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); // Bisa diganti shimmer
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Produk tidak ditemukan."));
                  }

                  // Konversi RecordModel ke Product model
                  final products = snapshot.data!.map((record) => Product.fromRecord(record, _pbService.baseUrl)).toList();
                  
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 0.68),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _ProductCard(product: products[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // --- PENAMBAHAN FLOATING ACTION BUTTON UNTUK ADMIN ---
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateProductScreen()),
                );
                if (result == true) {
                  _refreshProducts();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Tambah Produk"),
            )
          : null,
    );
  }
}

/// Widget Kartu Produk (menggunakan Product model)
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.price);
    final isOutOfStock = product.stock == 0 || !product.isAvailable;

    return GestureDetector(
      onTap: isOutOfStock ? null : () {
        // Navigasi ke detail, sekarang menggunakan Product model
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: product.imagePath.isNotEmpty
                        ? Image.network(product.imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 40, color: Colors.grey))
                        : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(formattedPrice, style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            if (isOutOfStock)
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('STOK HABIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              ),
          ],
        ),
      ),
    );
  }
}