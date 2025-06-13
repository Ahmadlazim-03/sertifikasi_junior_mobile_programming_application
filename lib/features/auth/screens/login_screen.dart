// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_java_project/core/services/pocketbase_service.dart';
import 'package:flutter_java_project/routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pocketBaseService = PocketBaseService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() { _isLoading = true; });
    try {
      await _pocketBaseService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: Email atau password salah.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Text('Selamat Datang!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white)),
                SizedBox(height: 48),
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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('LOGIN'),
                ),
                SizedBox(height: 16),

                // =======================================================
                // === TOMBOL KE HALAMAN REGISTER ADA DI SINI ===
                // =======================================================
                TextButton(
                  // Aksi yang dijalankan saat tombol ditekan
                  onPressed: () {
                    // Perintah untuk navigasi ke rute '/register'
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  // Tampilan tombol berupa teks
                  child: Text(
                    'Belum punya akun? Daftar di sini', 
                    style: TextStyle(color: Colors.white)
                  ),
                ),
                // =======================================================

              ],
            ),
          ),
        ),
      ),
    );
  }
}