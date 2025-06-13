import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_java_project/features/admin/screens/admin_dashboard_screen.dart'; // Pastikan impor ini benar
import 'package:flutter_java_project/features/auth/screens/login_screen.dart';
import 'package:flutter_java_project/features/profile/screens/edit_profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart'; // Sesuaikan path jika perlu

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _pbService = PocketBaseService();
  late Stream<List<RecordModel>> _ordersStream;

  @override
  void initState() {
    super.initState();
    // Inisialisasi format tanggal untuk Bahasa Indonesia
    initializeDateFormatting('id_ID', null);
    _ordersStream = _pbService.subscribeToUserOrders();
  }

  void _logout() {
    _pbService.unsubscribeAll(); // Hentikan langganan realtime saat logout
    _pbService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false);
    }
  }

  // Helper untuk mendapatkan warna berdasarkan status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'processing':
      case 'out_for_delivery':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'pending':
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _pbService.pb.authStore.model;

    // Pengaman jika user null (misalnya token expired)
    if (user == null) {
      // Menggunakan addPostFrameCallback untuk menunda navigasi setelah build selesai
      WidgetsBinding.instance.addPostFrameCallback((_) => _logout());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pesanan'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Cukup panggil setState untuk membangun ulang widget dengan data terbaru dari authStore
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- KARTU PROFIL PENGGUNA ---
            _buildUserProfileCard(user),
            const SizedBox(height: 24),

            // --- HEADER RIWAYAT PESANAN ---
            Text('Riwayat Pesanan Anda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // --- DAFTAR RIWAYAT PESANAN (REAL-TIME) ---
            StreamBuilder<List<RecordModel>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat pesanan: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text('Anda belum pernah membuat pesanan.'),
                  ));
                }
                final orders = snapshot.data!;
                // Menggunakan Column karena ListView sudah menyediakan fungsi scroll
                return Column(
                  children: orders.map((order) => _buildOrderItemCard(order)).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),
            // --- TOMBOL ADMIN & LOGOUT ---
            if (user.data['role'] == 'admin')
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('PANEL ADMIN'),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('LOGOUT'),
                onPressed: _logout,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.grey.shade400)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk kartu profil pengguna
  Widget _buildUserProfileCard(RecordModel user) {
    final avatarUrl = user.data['avatar'] != '' && user.data['avatar'] != null
        ? _pbService.pb.getFileUrl(user, user.data['avatar']).toString()
        : null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, size: 35, color: Colors.grey) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.data['name'] ?? 'Nama Pengguna',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.data['email'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                child: const Text('Edit Profil'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget helper untuk kartu riwayat pesanan
  Widget _buildOrderItemCard(RecordModel order) {
    final status = order.data['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    String itemSummary = 'Detail pesanan tidak tersedia.';

    try {
      final List<dynamic> items = jsonDecode(order.data['ordered_items']);
      if (items.isNotEmpty) {
        itemSummary = '${items[0]['name']}';
        if (items.length > 1) {
          itemSummary += ' dan ${items.length - 1} lainnya';
        }
      }
    } catch (e) {
      print('Gagal parse item: $e');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.substring(0, 7)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(itemSummary, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.data['total_price']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(DateFormat('d MMM yyyy').format(DateTime.parse(order.created)), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}