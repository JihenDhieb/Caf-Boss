// lib/screens/menu_screen.dart
import 'package:cafeboss/core/app_strings.dart';
import 'package:cafeboss/models/produit_model.dart'; // ✅ import typed
import 'package:cafeboss/viewmodels/menu_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const _brown900 = Color(0xFF2C1A0E);
  static const _brown500 = Color(0xFFA08060);
  static const _cream    = Color(0xFFF5EFE6);
  static const _card     = Color(0xFFFBF6EF);
  static const _border   = Color(0xFFE8DCCF);
  static const _gold     = Color(0xFFC4851A);

  void _showAddDialog() {
    final nomController   = TextEditingController();
    final prixController  = TextEditingController();
    final emojiController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: _brown900.withOpacity(0.55),
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
        actionsPadding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
        title: Text(
          AppString.ajouterProduit,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _brown900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(nomController,   AppString.nomProduit,  'ex : Café Crème'),
            _buildField(prixController,  AppString.prixProduit, '0.00',
                inputType: TextInputType.number),
            _buildField(emojiController, 'Emoji', '☕'),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _brown500,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(AppString.annuler),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown900,
              foregroundColor: const Color(0xFFE8D8C3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              final nom   = nomController.text.trim();
              final prix  = double.tryParse(prixController.text) ?? 0;
              final emoji = emojiController.text.trim();

              if (nom.isEmpty) return; // ✅ garde-fou basique

              // ✅ Fixed: signature (nom, prix, emoji) correspond au ViewModel
              await context.read<MenuViewModel>().addProduit(nom, prix, emoji);
              if (mounted) Navigator.pop(context);
            },
            child: const Text(AppString.ajouter),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: _brown500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: inputType,
            style: const TextStyle(color: _brown900, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _brown500.withOpacity(0.6)),
              filled: true,
              fillColor: const Color(0xFFF0E6D6),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _gold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MenuViewModel>();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _brown900,
        elevation: 0,
        titleSpacing: 24,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '☕ Menu',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: _cream,
              ),
            ),
            Text(
              'Gestion des produits',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: _brown500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              '${vm.produits.length} article${vm.produits.length > 1 ? 's' : ''}',
              style: const TextStyle(color: _brown500, fontSize: 13),
            ),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C1A0E)),
            ) // ✅ Affiche loader pendant chargement
          : vm.produits.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  itemCount: vm.produits.length,
                  itemBuilder: (context, index) {
                    final p = vm.produits[index];
                    return _ProductCard(
                      produit: p,
                      onDelete: () =>
                          context.read<MenuViewModel>().deleteProduit(p.id),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _gold,
        foregroundColor: _card,
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('☕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Aucun produit',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, color: _brown900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Appuie sur + pour en ajouter un',
              style: TextStyle(color: _brown500, fontSize: 14),
            ),
          ],
        ),
      );
}

// ── Widget carte produit ──────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Produit produit; // ✅ Fixed: typed Produit au lieu de dynamic
  final VoidCallback onDelete;

  const _ProductCard({required this.produit, required this.onDelete});

  static const _brown900 = Color(0xFF2C1A0E);
  static const _brown500 = Color(0xFFA08060);
  static const _card     = Color(0xFFFBF6EF);
  static const _border   = Color(0xFFE8DCCF);
  static const _cream    = Color(0xFFF0E6D6);
  static const _red      = Color(0xFFC0503A);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Center(
                child: Text(produit.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nom,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _brown900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${produit.prix} DT',
                    style: const TextStyle(fontSize: 13, color: _brown500),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _brown900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${produit.prix} DT',
                style: const TextStyle(
                  color: Color(0xFFE8D8C3),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, size: 14, color: _red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}