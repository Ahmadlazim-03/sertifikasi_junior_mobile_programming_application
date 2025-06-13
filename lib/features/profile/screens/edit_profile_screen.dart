// lib/features/profile/screens/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/pocketbase_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _pocketBaseService = PocketBaseService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;

  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = _pocketBaseService.pb.authStore.model;
    _nameController = TextEditingController(text: currentUser?.data['name'] ?? '');
    _usernameController = TextEditingController(text: currentUser?.data['username'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
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
        await _pocketBaseService.updateUserProfile(
          name: _nameController.text,
          username: _usernameController.text,
          newAvatarFile: _imageFile,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
          );
          // Kembali ke halaman sebelumnya dan kirim sinyal bahwa update berhasil
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui profil: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _pocketBaseService.pb.authStore.model;
    final avatarUrl = currentUser?.data['avatar'] != ''
        ? _pocketBaseService.pb.getFileUrl(currentUser!, currentUser.data['avatar']).toString()
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Picker
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (avatarUrl != null ? NetworkImage(avatarUrl) : null) as ImageProvider?,
                    child: _imageFile == null && avatarUrl == null ? const Icon(Icons.person, size: 60) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.edit, size: 20),
                      ),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Username tidak boleh kosong' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN PERUBAHAN'),
                ),
              ),
              const SizedBox(height: 16),
              // Tombol untuk ubah password (disarankan di halaman terpisah)
              OutlinedButton(
                onPressed: () {
                  // TODO: Navigasi ke halaman ganti password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur ganti password akan datang!')),
                  );
                },
                child: const Text('Ubah Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}