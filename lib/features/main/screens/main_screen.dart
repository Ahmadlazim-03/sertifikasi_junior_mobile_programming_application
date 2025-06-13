// lib/features/main/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_java_project/features/admin/screens/admin_dashboard_screen.dart';
import 'package:flutter_java_project/features/admin/screens/admin_map_page.dart';
import 'package:flutter_java_project/features/cart/screens/cart_screen.dart';
import 'package:flutter_java_project/features/cart/services/cart_service.dart';
import 'package:flutter_java_project/features/home/screens/home_screen.dart';
import 'package:flutter_java_project/features/profile/screens/profile_screen.dart';
import '../../../core/services/pocketbase_service.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final CartService _cartService = CartService();
  final PocketBaseService _pocketBaseService = PocketBaseService();

  bool _isAdmin = false;
  bool _isLoading = true;

  // Daftar halaman untuk customer
  static final List<Widget> _customerPages = <Widget>[
    HomeScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  // Daftar halaman untuk admin
  // <-- PERUBAHAN DI SINI
  static final List<Widget> _adminPages = <Widget>[
    HomeScreen(), // Admin bisa lihat Beranda/Daftar Produk
    AdminDashboardScreen(), 
    AdminMapPage(),
    ProfileScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    if (_pocketBaseService.isSignedIn) {
      final user = _pocketBaseService.pb.authStore.model;
      setState(() {
        _isAdmin = (user?.data['role'] == 'admin');
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<BottomNavigationBarItem> _buildCustomerNavBarItems() {
    return <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Beranda',
      ),
      BottomNavigationBarItem(
        icon: AnimatedBuilder(
          animation: _cartService,
          builder: (context, child) {
            return Badge(
              label: Text('${_cartService.totalItems}'),
              isLabelVisible: _cartService.totalItems > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            );
          },
        ),
        activeIcon: const Icon(Icons.shopping_cart),
        label: 'Keranjang',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  // <-- PERUBAHAN DI SINI
  List<BottomNavigationBarItem> _buildAdminNavBarItems() {
    return const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Beranda',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Peta Pesanan',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> currentPages = _isAdmin ? _adminPages : _customerPages;
    final List<BottomNavigationBarItem> currentNavBarItems = _isAdmin ? _buildAdminNavBarItems() : _buildCustomerNavBarItems();

    return Scaffold(
      body: Center(
        child: currentPages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: currentNavBarItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}