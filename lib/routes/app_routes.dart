import 'package:flutter/material.dart';
import 'package:flutter_java_project/features/admin/screens/admin_dashboard_screen.dart';
import 'package:flutter_java_project/features/admin/screens/create_product_screen.dart';
import 'package:flutter_java_project/features/admin/screens/edit_product_screen.dart';
import 'package:flutter_java_project/features/auth/screens/login_screen.dart';
import 'package:flutter_java_project/features/auth/screens/register_screen.dart';
import 'package:flutter_java_project/features/home/models/product_model.dart';
// import 'package:flutter_java_project/features/home/screens/home_screen.dart'; // tidak perlu lagi
import 'package:flutter_java_project/features/main/screens/main_screen.dart'; // <-- Impor baru
import 'package:flutter_java_project/features/home/screens/product_detail_screen.dart';
// import 'package:flutter_java_project/features/cart/screens/cart_screen.dart'; // tidak perlu lagi
import 'package:flutter_java_project/features/checkout/screens/checkout_screen.dart';
import 'package:flutter_java_project/features/checkout/screens/order_success_screen.dart';
// import 'package:roti_app/features/profile/screens/profile_screen.dart'; // tidak perlu lagi

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  
  // Rute home sekarang akan mengarah ke MainScreen
  static const String home = '/home'; 
  
  static const String productDetail = '/product-detail';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  
  static const String adminDashboard = '/admin-dashboard';
  static const String createProduct = '/create-product';
  static const String editProduct = '/edit-product';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      
      // --- PERUBAHAN DI SINI ---
      case home:
        return MaterialPageRoute(builder: (_) => MainScreen());
      
      case checkout:
        return MaterialPageRoute(builder: (_) => CheckoutScreen());
      case orderSuccess:
        return MaterialPageRoute(builder: (_) => OrderSuccessScreen());
      
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
      case createProduct:
        return MaterialPageRoute(builder: (_) => CreateProductScreen());

      case productDetail:
        final product = settings.arguments as Product;
        return MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product));
      
      case editProduct:
        final product = settings.arguments as Product;
        return MaterialPageRoute(builder: (_) => EditProductScreen(product: product));

      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}