import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_java_project/features/admin/screens/create_product_screen.dart';
import 'package:flutter_java_project/features/home/models/product_model.dart';
import 'package:flutter_java_project/features/home/screens/product_detail_screen.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import 'package:flutter_java_project/core/theme.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PocketBaseService _pbService = PocketBaseService();
  
  String _searchQuery = '';
  String? _selectedCategory;
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isAdmin = false;

  final List<String> _categories = ['Roti', 'Kue', 'Pastry', 'Minuman'];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

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

  void _refreshProducts() {
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Refined color scheme (matching LoginScreen and RegisterScreen)
    final primaryColor = Colors.amber[700]!;
    final secondaryColor = Color(0xFF6D4C41); // Richer brown
    final backgroundColor = Color(0xFFFFF3E0); // Softer cream
    final cardColor = Color(0xFFF8EDEB); // Subtle cream

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Toko Roti Bahagia',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFD180), // Warm amber
              Color(0xFFFFAB40), // Deep amber
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async => _refreshProducts(),
          color: primaryColor,
          backgroundColor: cardColor,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header Section
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        children: [
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari roti atau kue...',
                              prefixIcon: Icon(Icons.search, color: primaryColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: secondaryColor),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              filled: true,
                              fillColor: cardColor,
                              contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              hintStyle: TextStyle(color: secondaryColor.withOpacity(0.6)),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Category Filters
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _categories.map((category) {
                                final isSelected = _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = selected ? category : null;
                                      });
                                    },
                                    backgroundColor: cardColor,
                                    selectedColor: primaryColor.withOpacity(0.9),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : secondaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    checkmarkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Product Grid
                  Expanded(
                    child: FutureBuilder(
                      key: ValueKey('$_searchQuery$_selectedCategory'),
                      future: _pbService.getProducts(searchQuery: _searchQuery, category: _selectedCategory),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              backgroundColor: cardColor.withOpacity(0.5),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error: ${snapshot.error}",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              "Produk tidak ditemukan.",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          );
                        }

                        final products = snapshot.data!.map((record) => Product.fromRecord(record, _pbService.baseUrl)).toList();
                        
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.7,
                          ),
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
          ),
        ),
      ),
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
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add, size: 24),
              label: Text(
                "Tambah Produk",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            )
          : null,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.amber[700]!;
    final secondaryColor = Color(0xFF6D4C41);
    final cardColor = Color(0xFFF8EDEB);
    final formattedPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.price);
    final isOutOfStock = product.stock == 0 || !product.isAvailable;

    return GestureDetector(
      onTap: isOutOfStock
          ? null
          : () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
            },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: cardColor,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: product.imagePath.isNotEmpty
                        ? Image.network(
                            product.imagePath,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                  color: primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (c, e, s) => Icon(Icons.image_not_supported, size: 50, color: secondaryColor.withOpacity(0.6)),
                          )
                        : Icon(Icons.image_not_supported, size: 50, color: secondaryColor.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: secondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isOutOfStock)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'STOK HABIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}