// lib/features/checkout/screens/order_success_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_java_project/core/theme.dart';
import 'package:flutter_java_project/routes/app_routes.dart';

class OrderSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 120),
              SizedBox(height: 24),
              Text(
                'Pesanan Berhasil!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              SizedBox(height: 12),
              Text(
                'Terima kasih telah berbelanja. Pesanan Anda sedang kami siapkan dan akan segera diantar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                  },
                  child: Text('KEMBALI KE BERANDA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}