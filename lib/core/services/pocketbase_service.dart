import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  // Instance singleton untuk memastikan hanya ada satu koneksi di seluruh aplikasi
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  // Inisialisasi koneksi ke server PocketBase Anda
  final pb = PocketBase('https://ahmadlazim.works/');

  // =======================================================================
  // BAGIAN AUTENTIKASI & PROFIL
  // =======================================================================

  /// Fungsi untuk login pengguna
  Future<RecordAuth> login(String email, String password) async {
    try {
      final authData = await pb.collection('users').authWithPassword(email, password);
      return authData;
    } catch (e) {
      print('Error saat login: $e');
      rethrow;
    }
  }

  /// Fungsi untuk mendaftarkan pengguna baru
  Future<RecordModel> register(String name, String email, String password) async {
    try {
      final body = <String, dynamic>{
        "name": name, "email": email, "emailVisibility": true,
        "password": password, "passwordConfirm": password, "role": "customer"
      };
      final record = await pb.collection('users').create(body: body);
      await login(email, password);
      return record;
    } catch (e) {
      print('Error saat registrasi: $e');
      rethrow;
    }
  }
  
  /// Fungsi untuk memperbarui data profil pengguna (nama, username, avatar)
  Future<RecordModel> updateUserProfile({
    required String name, required String username, File? newAvatarFile,
  }) async {
    if (!isSignedIn) throw Exception('Pengguna belum login.');
    final userId = pb.authStore.model.id;
    final body = <String, dynamic>{'name': name, 'username': username};
    try {
      List<http.MultipartFile> files = []; // <-- SUDAH DIPERBAIKI
      if (newAvatarFile != null) {
        files = [await http.MultipartFile.fromPath('avatar', newAvatarFile.path)];
      }
      final updatedRecord = await pb.collection('users').update(userId, body: body, files: files);
      pb.authStore.save(pb.authStore.token, updatedRecord);
      return updatedRecord;
    } catch (e) {
      print('Error saat update profil: $e');
      rethrow;
    }
  }
  
  /// Fungsi untuk logout
  void logout() => pb.authStore.clear();

  /// Properti untuk memeriksa status login
  bool get isSignedIn => pb.authStore.isValid;
  
  /// Properti untuk mendapatkan URL dasar
  String get baseUrl => pb.baseUrl;

  // =======================================================================
  // BAGIAN MANAJEMEN PRODUK (CRUD)
  // =======================================================================
  
  /// Read: Fungsi untuk mengambil produk dengan filter opsional
  Future<List<RecordModel>> getProducts({String? searchQuery, String? category}) async {
    try {
      final filterParts = <String>[];
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filterParts.add('(name ~ "$searchQuery" || description ~ "$searchQuery")');
      }
      if (category != null && category.isNotEmpty) {
        filterParts.add('category = "$category"');
      }
      final filterString = filterParts.join(' && ');
      return await pb.collection('products').getFullList(
        sort: '-created',
        filter: filterString.isNotEmpty ? filterString : null,
      );
    } catch (e) {
      print('Error mengambil produk: $e');
      rethrow;
    }
  }

  /// Create: Fungsi untuk membuat produk baru dari Mobile (menggunakan File)
  Future<RecordModel> createProduct({
    required String name, required String description, required double price,
    required int stock, required String category, required File imageFile,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name, 'description': description, 'price': price,
        'stock': stock, 'category': category, 'is_available': true,
      };
      final files = [await http.MultipartFile.fromPath('image', imageFile.path)];
      return await pb.collection('products').create(body: body, files: files);
    } catch (e) {
      print('Error membuat produk: $e');
      rethrow;
    }
  }

  /// Create: Fungsi untuk membuat produk baru dari Web (menggunakan data byte)
  Future<RecordModel> createProductFromWeb({
    required String name, required String description, required double price,
    required int stock, required String category,
    required Uint8List imageBytes, required String imageName,
  }) async {
    try {
      final imageFile = http.MultipartFile.fromBytes('image', imageBytes, filename: imageName);
      final body = <String, dynamic>{
        'name': name, 'description': description, 'price': price,
        'stock': stock, 'category': category, 'is_available': true,
      };
      return await pb.collection('products').create(body: body, files: [imageFile]);
    } catch (e) {
      print('Error membuat produk dari web: $e');
      rethrow;
    }
  }

  /// Update: Fungsi untuk memperbarui produk
  Future<RecordModel> updateProduct(
    String productId, {
    required String name, required String description, required double price,
    required int stock, required String category, File? newImageFile,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name, 'description': description, 'price': price,
        'stock': stock, 'category': category,
      };
      List<http.MultipartFile> files = []; // <-- SUDAH DIPERBAIKI
      if (newImageFile != null) {
        files = [await http.MultipartFile.fromPath('image', newImageFile.path)];
      }
      return await pb.collection('products').update(productId, body: body, files: files);
    } catch (e) {
      print('Error update produk: $e');
      rethrow;
    }
  }

  /// Delete: Fungsi untuk menghapus produk
  Future<void> deleteProduct(String productId) async {
    try {
      await pb.collection('products').delete(productId);
    } catch (e) {
      print('Error hapus produk: $e');
      rethrow;
    }
  }

  // =======================================================================
  // BAGIAN MANAJEMEN PESANAN
  // =======================================================================
  
  /// Fungsi untuk membuat pesanan baru
  Future<RecordModel> createOrder({
    required String userId, required List<Map<String, dynamic>> orderedItems,
    required double totalPrice, required String deliveryAddress,
    required double lat, required double long,
  }) async {
    try {
      final body = <String, dynamic>{
        "user": userId, "ordered_items": jsonEncode(orderedItems),
        "total_price": totalPrice, "delivery_address": deliveryAddress,
        "gps_latitude": lat, "gps_longitude": long, "status": "pending"
      };
      return await pb.collection('orders').create(body: body);
    } catch (e) {
      print('Error membuat pesanan: $e');
      rethrow;
    }
  }

  /// Fungsi untuk mengambil riwayat pesanan pengguna
  Future<List<RecordModel>> getUserOrders() async {
    if (!isSignedIn) return [];
    try {
      final String userId = pb.authStore.model.id;
      return await pb.collection('orders').getFullList(
        sort: '-created', filter: 'user = "$userId"',
      );
    } catch (e) {
      print('Error mengambil riwayat pesanan: $e');
      rethrow;
    }
  }

  /// Fungsi untuk admin: mengambil semua pesanan
  Future<List<RecordModel>> getAllOrders() async {
    try {
      return await pb.collection('orders').getFullList(sort: '-created', expand: 'user');
    } catch (e) {
      print('Error mengambil semua pesanan: $e');
      rethrow;
    }
  }

  /// Fungsi untuk admin: mengambil pesanan yang bisa dilacak
  Future<List<RecordModel>> getTrackableOrders() async {
    try {
      const filter = "status != 'completed' && status != 'cancelled'";
      return await pb.collection('orders').getFullList(sort: '-created', expand: 'user', filter: filter);
    } catch (e) {
      print('Error mengambil pesanan yang bisa dilacak: $e');
      rethrow;
    }
  }

  /// Fungsi untuk admin: update status pesanan
  Future<RecordModel> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final body = <String, dynamic>{"status": newStatus};
      return await pb.collection('orders').update(orderId, body: body);
    } catch (e) {
      print('Error update status pesanan: $e');
      rethrow;
    }
  }

  // =======================================================================
  // BAGIAN REAL-TIME
  // =======================================================================
  
  /// Fungsi untuk berlangganan perubahan data pesanan pengguna
  Stream<List<RecordModel>> subscribeToUserOrders() {
    final controller = StreamController<List<RecordModel>>.broadcast();
    if (!isSignedIn) {
      controller.close();
      return controller.stream;
    }
    
    getUserOrders().then((orders) {
      if (!controller.isClosed) controller.add(orders);
    });

    final unsubscribeCallback = pb.collection('orders').subscribe('*', (e) {
      if (e.record != null) {
        getUserOrders().then((orders) {
          if (!controller.isClosed) controller.add(orders);
        });
      }
    });

    controller.onCancel = () {
      print('Membatalkan langganan ke orders...');
      unsubscribeCallback;
    };
    return controller.stream;
  }

  /// Fungsi untuk membatalkan semua langganan yang aktif
  Future<void> unsubscribeAll() async {
    await pb.realtime.unsubscribe();
    print('Semua langganan realtime telah dibatalkan.');
  }
}