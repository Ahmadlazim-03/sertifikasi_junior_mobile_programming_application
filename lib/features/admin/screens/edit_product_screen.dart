import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import 'package:flutter_java_project/features/home/models/product_model.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  EditProductScreen({required this.product});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pbService = PocketBaseService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  String? _selectedCategory;
  File? _imageFile;

  final List<String> _categories = ['Roti', 'Kue', 'Pastry', 'Minuman'];
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _selectedCategory = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _pbService.updateProduct(
          widget.product.id,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          category: _selectedCategory!,
          newImageFile: _imageFile,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui produk: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Produk')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : (widget.product.imagePath.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.product.imagePath, fit: BoxFit.cover))
                          : Center(child: Text('Ketuk untuk pilih gambar baru'))
                        ),
                ),
              ),
              SizedBox(height: 8),
              Center(child: Text('Ketuk gambar untuk mengganti', style: TextStyle(color: Colors.grey[600]))),
              SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: InputDecoration(labelText: 'Nama Produk'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Kategori'),
                items: _categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Wajib dipilih' : null,
              ),
              SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Deskripsi'), maxLines: 3, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              SizedBox(height: 16),
              TextFormField(controller: _priceController, decoration: InputDecoration(labelText: 'Harga', prefixText: 'Rp '), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              SizedBox(height: 16),
              TextFormField(controller: _stockController, decoration: InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('SIMPAN PERUBAHAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}