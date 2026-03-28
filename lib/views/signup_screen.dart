// lib/views/signup_screen.dart
import 'package:cafeboss/core/app_colors.dart';
import 'package:cafeboss/services/AuthService.dart';

import 'package:cafeboss/views/role_router_screen.dart';
import 'package:cafeboss/views/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _cafeCtrl  = TextEditingController();
  final _chefCtrl  = TextEditingController();
  bool _loading    = false;
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _cafeCtrl.dispose();
    _chefCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    final cafe  = _cafeCtrl.text.trim();
    final chef  = _chefCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || cafe.isEmpty || chef.isEmpty) {
      _showSnack('Veuillez remplir tous les champs.');
      return;
    }
    if (pass.length < 6) {
      _showSnack('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() => _loading = true);
    final error = await context.read<AuthService>().signup(
      email: email,
      password: pass,
      nomCafe: cafe,
      nomChef: chef,
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleRouterScreen()),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cafeCream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Image.asset('assets/images/logo.png', width: 120, height: 120),
            const SizedBox(height: 16),
            const Text(
              'Créer mon café',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.cafeBrown,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vous serez le chef — ajoutez vos serveurs ensuite',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.cafeGrey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _field(_cafeCtrl, 'Nom du café', Icons.store),
            const SizedBox(height: 12),
            _field(_chefCtrl, 'Votre prénom', Icons.person),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Email', Icons.email,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _passwordField(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cafeBrown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CRÉER MON CAFÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SigninScreen()),
              ),
              child: const Text(
                'Déjà un compte ? Se connecter',
                style: TextStyle(color: AppColors.cafeBrown),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.cafeBrown.withOpacity(0.3)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.cafeBrown),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cafeBrown.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _passCtrl,
        obscureText: _obscure,
        decoration: InputDecoration(
          icon: const Icon(Icons.lock, color: AppColors.cafeBrown),
          hintText: 'Mot de passe (min. 6 caractères)',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.cafeGrey,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}