import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart'; // Sesuaikan path jika perlu
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final PocketBaseService _pocketBaseService = PocketBaseService();
  final MapController _mapController = MapController();

  List<Marker> _orderMarkers = [];
  latlong.LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    await _fetchOrdersAndCreateMarkers();
    await _determinePosition();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrdersAndCreateMarkers() async {
    try {
      final orders = await _pocketBaseService.getTrackableOrders();
      final List<Marker> markers = [];
      for (final order in orders) {
        final double? lat = order.data['gps_latitude']?.toDouble();
        final double? lng = order.data['gps_longitude']?.toDouble();
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              width: 80.0, height: 80.0,
              point: latlong.LatLng(lat, lng),
              child: GestureDetector(
                onTap: () => _showOrderDetailsBottomSheet(order),
                child: Tooltip(
                  message: 'Pesanan oleh: ${order.expand['user']?.first.data['name'] ?? ''}',
                  child: Icon(Icons.location_on, color: _getStatusColor(order.data['status']), size: 40),
                ),
              ),
            ),
          );
        }
      }
      if (mounted) setState(() => _orderMarkers = markers);
    } catch (e) {
      print("Gagal memuat marker pesanan: $e");
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Servis lokasi tidak aktif.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak permanen, harap aktifkan di pengaturan aplikasi.')));
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = latlong.LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentPosition!, 15.0);
      }
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
    }
  }

  void _showOrderDetailsBottomSheet(RecordModel order) {
    final user = order.expand['user']?.first;
    final status = order.data['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final orderDate = DateTime.parse(order.created);

    // =======================================================
    // PERBAIKAN UTAMA ADA DI BARIS INI
    // =======================================================
    final formattedDate = DateFormat('d MMMM y, HH:mm', 'id_ID').format(orderDate.toLocal());
    
    final formattedPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.data['total_price']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Text('Detail Pesanan #${order.id.substring(0, 7)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, "Pemesan", user?.data['name'] ?? 'Tidak Diketahui'),
              _buildDetailRow(Icons.flag, "Status", status.replaceAll('_', ' ').toUpperCase(), valueColor: statusColor),
              _buildDetailRow(Icons.location_city, "Alamat", order.data['delivery_address']),
              _buildDetailRow(Icons.calendar_today, "Tanggal", formattedDate), // <-- Menggunakan hasil format yang benar
              _buildDetailRow(Icons.monetization_on, "Total", formattedPrice),
              const SizedBox(height: 8),
              const Text("Item Dipesan:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildOrderedItems(order.data['ordered_items'] as List<dynamic>),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Ubah Status"),
                      onPressed: () { Navigator.pop(context); _showStatusChanger(order); },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Theme.of(context).primaryColor)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text("Navigasi"),
                      onPressed: () => _launchMaps(order.data['gps_latitude']?.toDouble(), order.data['gps_longitude']?.toDouble()),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showStatusChanger(RecordModel order) {
    final List<String> statuses = ['pending', 'processing', 'out_for_delivery', 'completed', 'cancelled'];
    String currentStatus = order.data['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ubah Status Order #${order.id.substring(0, 7)}", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Status Pesanan'),
                    items: statuses.map((String status) => DropdownMenuItem<String>(value: status, child: Text(status.replaceAll('_', ' ').toUpperCase()))).toList(),
                    onChanged: (String? newValue) { if (newValue != null) setModalState(() => currentStatus = newValue); },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                      child: const Text("SIMPAN PERUBAHAN"),
                      onPressed: () async {
                        try {
                          await _pocketBaseService.updateOrderStatus(order.id, currentStatus);
                          Navigator.pop(context);
                          _initializeMap();
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diperbarui!'), backgroundColor: Colors.green));
                        } catch(e) {
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update status: $e'), backgroundColor: Colors.red));
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

  Widget _buildDetailRow(IconData icon, String title, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text('$title:', style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor))),
      ],
    ),
  );

  Widget _buildOrderedItems(List<dynamic> items) {
    try {
      if (items.isEmpty) return const Text('Tidak ada item dalam pesanan ini.');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final name = item['name'] ?? 'Item tidak diketahui';
          final quantity = item['quantity'] ?? 0;
          return Text(' • $name (x$quantity)');
        }).toList(),
      );
    } catch (e) {
      print("Error saat memproses item pesanan: $e");
      return const Text('Gagal memuat detail item.');
    }
  }

  Future<void> _launchMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data lokasi tidak valid.')));
      return;
    }
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final Uri uri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka aplikasi peta.')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.shade700;
      case 'processing': case 'out_for_delivery': return Colors.blue.shade700;
      case 'cancelled': return Colors.red.shade700;
      case 'pending': default: return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Pelacakan (Live)')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: latlong.LatLng(-7.257472, 112.752088), zoom: 12.0, maxZoom: 18.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.app'),
              MarkerLayer(markers: [
                ..._orderMarkers,
                if (_currentPosition != null)
                  Marker(
                    width: 80.0, height: 80.0,
                    point: _currentPosition!,
                    child: Icon(Icons.my_location, color: Theme.of(context).primaryColor, size: 30.0),
                  ),
              ]),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        tooltip: 'Lokasi Saya',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}