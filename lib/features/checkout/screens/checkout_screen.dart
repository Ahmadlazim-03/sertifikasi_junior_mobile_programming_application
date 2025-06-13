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
          _showErrorDialog('Izin lokasi ditolak.');
          setState(() => _isLoadingLocation = false);
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
      _showErrorDialog('Gagal mendapatkan lokasi: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty || _latitude == null) {
      _showErrorDialog('Alamat dan lokasi GPS wajib diisi.', title: 'Data Tidak Lengkap', color: Colors.orange);
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final orderedItems = _cartService.items.map((item) => {
        'productId': item.product.id,
        'name': item.product.name,
        'quantity': item.quantity,
        'price_at_purchase': item.product.price,
      }).toList();

      await _pbService.createOrder(
        userId: _pbService.pb.authStore.model.id,
        orderedItems: orderedItems,
        totalPrice: _cartService.totalPrice,
        deliveryAddress: _addressController.text,
        lat: _latitude!,
        long: _longitude!,
      );

      _cartService.clearCart();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.orderSuccess, (route) => false);
    } catch (e) {
      _showErrorDialog('Gagal membuat pesanan: $e', color: Colors.red);
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  void _showErrorDialog(String message, {String title = 'Error', Color? color}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: color ?? Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Form Alamat ---
            Text(
              'Alamat Pengiriman',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Alamat Lengkap',
                hintText: 'Masukkan alamat pengiriman Anda',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: _isLoadingLocation
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : Icon(Icons.my_location),
              label: Text(_isLoadingLocation ? 'Mencari Lokasi...' : 'Gunakan Lokasi Saat Ini'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size(double.infinity, 50),
                elevation: 2,
              ),
            ),
            SizedBox(height: 8),
            if (_coordinates.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Koordinat GPS: $_coordinates',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            SizedBox(height: 32),

            // --- Ringkasan Pesanan ---
            Text(
              'Ringkasan Pesanan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ..._cartService.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${(item.product.price * item.quantity).toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ),
                    )).toList(),
                    Divider(height: 24, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Rp ${_cartService.totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          child: _isPlacingOrder
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
                  'BUAT PESANAN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 56),
            elevation: 3,
          ),
        ),
      ),
    );
  }
}