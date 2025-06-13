// lib/features/admin/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../../../core/services/pocketbase_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _pbService = PocketBaseService();
  late Future<List<RecordModel>> _allOrdersFuture;

  @override
  void initState() {
    super.initState();
    // Inisialisasi lokalisasi untuk format tanggal
    initializeDateFormatting('id_ID', null);
    _allOrdersFuture = _pbService.getAllOrders();
  }

  void _refreshOrders() {
    setState(() {
      _allOrdersFuture = _pbService.getAllOrders();
    });
  }
  
  // --- FUNGSI BARU: Mendapatkan warna berdasarkan status ---
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
  
  void _showStatusChanger(RecordModel order) {
    final List<String> statuses = ['pending', 'processing', 'out_for_delivery', 'completed', 'cancelled'];
    String currentStatus = order.data['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ubah Status Order #${order.id.substring(0, 7)}", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Status Pesanan',
                    ),
                    items: statuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          currentStatus = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("SIMPAN PERUBAHAN"),
                      onPressed: () async {
                        try {
                          await _pbService.updateOrderStatus(order.id, currentStatus);
                          Navigator.pop(context); 
                          _refreshOrders();
                           if(mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Status berhasil diperbarui!'), backgroundColor: Colors.green),
                            );
                           }
                        } catch(e) {
                           if(mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Gagal update status: $e'), backgroundColor: Colors.red),
                             );
                           }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Pesanan Pelanggan'),
      ),
      body: FutureBuilder<List<RecordModel>>(
        future: _allOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada pesanan yang masuk."));
          }

          final orders = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                // Kirim order ke widget kartu yang baru dan lebih baik
                return _buildOrderCard(order);
              },
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BARU: Kartu Pesanan yang Lebih Informatif ---
  Widget _buildOrderCard(RecordModel order) {
    final user = order.expand['user']?.first;
    final status = order.data['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    
    // Format tanggal dan harga
    final orderDate = DateTime.parse(order.created);
    final formattedDate = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(orderDate.toLocal());
    final formattedPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.data['total_price']);

    // Decode item yang dipesan
    List<Widget> orderedItemsWidgets = [];
    try {
      final List<dynamic> items = jsonDecode(order.data['ordered_items']);
      orderedItemsWidgets = items.map((item) => 
        Text('• ${item['name']} (x${item['quantity']})')
      ).toList();
    } catch(e) {
      orderedItemsWidgets.add(const Text('Gagal memuat item'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showStatusChanger(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Kartu ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #${order.id.substring(0, 7)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              // --- Detail Pesanan ---
              Text(
                "Oleh: ${user?.data['name'] ?? 'N/A'}",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              Text(
                "Tanggal: $formattedDate",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text("Item Dipesan:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...orderedItemsWidgets,
              const SizedBox(height: 12),
              // --- Total Harga ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Total: ", style: TextStyle(fontSize: 16)),
                  Text(
                    formattedPrice,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}