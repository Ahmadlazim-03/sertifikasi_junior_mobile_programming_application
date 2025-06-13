import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import 'package:flutter_java_project/features/cart/services/cart_service.dart';
import 'package:flutter_java_project/routes/app_routes.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _cartService = CartService();
  final _pbService = PocketBaseService();

  String _coordinates = '';
  double? _latitude;
  double? _longitude;

  bool _isLoadingLocation = false;
  bool _isPlacingOrder = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Izin lokasi ditolak.')));
          setState(() { _isLoadingLocation = false; });
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _coordinates = 'Lat: ${_latitude!.toStringAsFixed(5)}, Long: ${_longitude!.toStringAsFixed(5)}';
      });
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _addressController.text = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty || _latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alamat dan lokasi GPS wajib diisi.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final orderedItems = _cartService.items.map((item) => {
                'productId': item.product.id, 'name': item.product.name,
                'quantity': item.quantity, 'price_at_purchase': item.product.price,
              }).toList();

      await _pbService.createOrder(
        userId: _pbService.pb.authStore.model.id, orderedItems: orderedItems,
        totalPrice: _cartService.totalPrice, deliveryAddress: _addressController.text,
        lat: _latitude!, long: _longitude!,
      );

      _cartService.clearCart();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.orderSuccess, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pesanan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      // === BODY YANG DIKEMBALIKAN ===
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Form Alamat ---
            Text('Alamat Pengiriman', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Alamat Lengkap',
                hintText: 'Masukkan alamat pengiriman Anda',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: _isLoadingLocation
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.my_location),
              label: Text(_isLoadingLocation ? 'Mencari Lokasi...' : 'Gunakan Lokasi Saat Ini'),
            ),
            SizedBox(height: 8),
            if (_coordinates.isNotEmpty)
              Text('Koordinat GPS: $_coordinates', style: Theme.of(context).textTheme.bodySmall),
            
            SizedBox(height: 32),

            // --- Ringkasan Pesanan ---
            Text('Ringkasan Pesanan', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ..._cartService.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.product.name} (x${item.quantity})')),
                          SizedBox(width: 16),
                          Text('Rp ${(item.product.price * item.quantity).toStringAsFixed(0)}')
                        ],
                      ),
                    )).toList(),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Rp ${_cartService.totalPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // === AKHIR BODY ===
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          child: _isPlacingOrder ? CircularProgressIndicator(color: Colors.white) : Text('BUAT PESANAN'),
        ),
      ),
    );
  }
}