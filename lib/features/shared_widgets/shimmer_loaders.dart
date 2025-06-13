import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Widget Shimmer untuk tampilan Grid seperti di Halaman Utama
class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.75,
        ),
        itemCount: 6, // Tampilkan 6 placeholder
        itemBuilder: (context, index) {
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(color: Colors.white), // Placeholder untuk gambar
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 16.0, color: Colors.white),
                      SizedBox(height: 8),
                      Container(width: 80, height: 14.0, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget Shimmer untuk tampilan List seperti di Riwayat Pesanan
class OrderListShimmer extends StatelessWidget {
  const OrderListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 3, // Tampilkan 3 placeholder
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 120, height: 16, color: Colors.white),
                      Container(width: 80, height: 24, color: Colors.white),
                    ],
                  ),
                  Divider(height: 20),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 150, height: 14, color: Colors.white),
                      Container(width: 100, height: 14, color: Colors.white),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}