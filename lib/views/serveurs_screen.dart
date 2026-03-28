// lib/views/serveurs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeboss/services/AuthService.dart';
import 'package:cafeboss/core/app_colors.dart';

class ServeursScreen extends StatefulWidget {
  const ServeursScreen({super.key});
  @override
  State<ServeursScreen> createState() => _ServeursScreenState();
}

class _ServeursScreenState extends State<ServeursScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nomCtrl   = TextEditingController();
  bool _loading = false;

  Future<void> _creerServeur() async {
    setState(() => _loading = true);
    final error = await context.read<AuthService>().creerServeur(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      nomServeur: _nomCtrl.text.trim(),
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _emailCtrl.clear();
      _passCtrl.clear();
      _nomCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serveur créé avec succès ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      backgroundColor: AppColors.cafeCream,
      appBar: AppBar(
        backgroundColor: AppColors.cafeBrown,
        title: const Text('👥 Mes Serveurs', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajouter un serveur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: AppColors.cafeBrown)),
            const SizedBox(height: 16),
            _field(_nomCtrl, 'Prénom du serveur', Icons.person),
            const SizedBox(height: 10),
            _field(_emailCtrl, 'Email', Icons.email,
              keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _field(_passCtrl, 'Mot de passe', Icons.lock, obscure: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _creerServeur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cafeBrown,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Créer le compte serveur',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Serveurs actifs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: AppColors.cafeBrown)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: auth.streamServeurs(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(
                    child: CircularProgressIndicator());
                  final serveurs = snap.data!;
                  if (serveurs.isEmpty) return const Text('Aucun serveur');
                  return ListView.builder(
                    itemCount: serveurs.length,
                    itemBuilder: (_, i) {
                      final s = serveurs[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(s.nomChef),
                        subtitle: Text(s.email),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, TextInputType? keyboard}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cafeBrown.withOpacity(0.3)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.cafeBrown),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}