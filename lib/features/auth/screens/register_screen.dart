// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import 'package:flutter_java_project/routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk mengambil data dari TextField
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Instance dari service PocketBase
  final _pocketBaseService = PocketBaseService();

  // State untuk menampilkan loading indicator
  bool _isLoading = false;

  // Fungsi untuk menjalankan proses registrasi
  Future<void> _register() async {
    // Validasi sederhana, pastikan semua field terisi
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field wajib diisi.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await _pocketBaseService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // Jika registrasi berhasil, service akan otomatis login.
      // Langsung navigasi ke halaman utama.
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);

    } catch (e) {
      // Tangani error yang mungkin terjadi
      String errorMessage = 'Terjadi kesalahan. Coba lagi.';
      if (e.toString().contains('already exists')) {
        errorMessage = 'Email yang Anda masukkan sudah terdaftar.';
      } else if (e.toString().contains('Failed to create record')) {
         errorMessage = 'Password terlalu lemah atau tidak valid.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      // Pastikan loading indicator berhenti
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    // Hapus controller saat widget tidak digunakan untuk menghindari memory leak
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Akun Baru"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bread_bg.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buat Akun',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
                ),
                SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('DAFTAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}