// lib/features/admin/screens/create_product_screen.dart

import 'dart:io'; // Tetap impor untuk pengecekan platform
import 'package:flutter/foundation.dart'; // Impor untuk kIsWeb dan Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import 'package:image_picker/image_picker.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _pocketBaseService = PocketBaseService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  // --- PERUBAHAN STATE ---
  // Kita akan menyimpan data gambar dalam bentuk byte untuk web
  File? _mobileImageFile; // Untuk mobile
  Uint8List? _webImageBytes; // Untuk web
  String? _imageName;
  
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = ['Minuman', 'Roti', 'Kue', 'Pastry'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // --- PERUBAHAN LOGIKA PICKER ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      // Simpan nama file
      _imageName = pickedFile.name;
      if (kIsWeb) { // Jika platformnya adalah web
        setState(() async {
          _webImageBytes = await pickedFile.readAsBytes();
        });
      } else { // Jika platformnya adalah mobile
        setState(() {
          _mobileImageFile = File(pickedFile.path);
        });
      }
    }
  }

  // --- PERUBAHAN LOGIKA SUBMIT ---
  Future<void> _submitForm() async {
    // Validasi dasar
    if (!_formKey.currentState!.validate() || _imageName == null || _selectedCategory == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua field dan pilih gambar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil service yang sesuai dengan platform
      if (kIsWeb) {
        // Panggil fungsi khusus web
        await _pocketBaseService.createProductFromWeb(
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          category: _selectedCategory!,
          imageBytes: _webImageBytes!,
          imageName: _imageName!,
        );
      } else {
        // Panggil fungsi asli untuk mobile
        await _pocketBaseService.createProduct(
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          category: _selectedCategory!,
          imageFile: _mobileImageFile!,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah produk: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Produk Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PERUBAHAN TAMPILAN GAMBAR ---
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: (_webImageBytes != null || _mobileImageFile != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // Tampilkan gambar dari byte jika di web, dari file jika di mobile
                          child: kIsWeb
                              ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                              : Image.file(_mobileImageFile!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), Text('Pilih Gambar Produk')],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Form Fields (tidak ada perubahan)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Nama produk tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedCategory = newValue),
                validator: (value) => value == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder(), prefixText: 'Rp '), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (value) => value!.isEmpty ? 'Harga tidak boleh kosong' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (value) => value!.isEmpty ? 'Stok tidak boleh kosong' : null)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN PRODUK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}