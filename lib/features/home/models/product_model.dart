import 'package:pocketbase/pocketbase.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String category;
  final int stock;
  final bool isAvailable;
  final String createdBy; // <-- Properti baru

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.category,
    required this.stock,
    required this.isAvailable,
    required this.createdBy, // <-- Tambahkan di constructor
  });

  factory Product.fromRecord(RecordModel record, String baseUrl) {
    final imageUrl = baseUrl + 'api/files/' + record.collectionId + '/' + record.id + '/' + record.getStringValue('image');
    
    String creatorName = 'N/A';
    // Ambil data dari 'expand' jika ada
    if (record.expand.containsKey('created_by') && record.expand['created_by']!.isNotEmpty) {
      creatorName = record.expand['created_by']!.first.getStringValue('name');
    }

    return Product(
      id: record.id,
      name: record.getStringValue('name'),
      description: record.getStringValue('description'),
      price: record.getDoubleValue('price'),
      imagePath: imageUrl,
      category: record.getStringValue('category'),
      stock: record.getIntValue('stock'),
      isAvailable: record.getBoolValue('is_available'),
      createdBy: creatorName, // <-- Masukkan nama kreator
    );
  }
}