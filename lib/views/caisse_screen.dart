import 'package:cafeboss/core/app_colors.dart';
import 'package:cafeboss/models/produit_model.dart';
import 'package:cafeboss/models/user_model.dart';
import 'package:cafeboss/services/AuthService.dart';
import 'package:cafeboss/services/firebase_service.dart';
import 'package:cafeboss/viewmodels/caisse_viewmodel.dart';
import 'package:cafeboss/views/historique_serveur_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  late CaisseViewModel _vm;
  final _fondCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final serveur = context.read<AuthService>().currentUser!;
    _vm = CaisseViewModel(
      firebase: context.read<FirebaseService>(),
      serveur: serveur,
    );
    _vm.addListener(() {
      if (mounted) setState(() {});
    });
    _vm.init();
  }

  @override
  void dispose() {
    _fondCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final error = await _vm.validerCaisse();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.cafeRed),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Caisse validée avec succès !'),
          backgroundColor: AppColors.cafeGreen,
        ),
      );
    }
  }

  void _showFondDialog() {
    _fondCtrl.text = _vm.fondCaisse > 0 ? _vm.fondCaisse.toString() : '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fond de caisse'),
        content: TextField(
          controller: _fondCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Montant en DT',
            suffixText: 'DT',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cafeBrown),
            onPressed: () {
              final val = double.tryParse(_fondCtrl.text) ?? 0;
              _vm.setFondCaisse(val);
              Navigator.pop(context);
            },
            child: const Text('OK',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serveur = context.read<AuthService>().currentUser!;

    return Scaffold(
      backgroundColor: AppColors.cafeCream,
      appBar: AppBar(
  backgroundColor: AppColors.cafeBrown,
  title: Text(
    '☕ ${serveur.nomChef}',
    style: const TextStyle(color: Colors.white),
  ),
  actions: [
    // ✅ Bouton historique
    IconButton(
      icon: const Icon(Icons.history, color: Colors.white),
      tooltip: 'Mon historique',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HistoriqueServeurScreen(serveur: serveur),
        ),
      ),
    ),
    // Bouton logout
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      tooltip: 'Déconnexion',
      onPressed: () async {
        await context.read<AuthService>().signOut();
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
    ),
  ],
),
      body: _vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Sélecteur service + fond de caisse ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Toggle Matin / Midi
                      Expanded(
                        child: Row(
                          children: ['matin', 'midi'].map((type) {
                            final selected = _vm.typeSession == type;
                            final done = type == 'matin'
                                ? _vm.sessionMatinFaite
                                : _vm.sessionMidiFaite;
                            return Expanded(
                              child: GestureDetector(
                                onTap: done
                                    ? null
                                    : () => _vm.setTypeSession(type),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: done
                                        ? Colors.grey[300]
                                        : selected
                                            ? AppColors.cafeBrown
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      type == 'matin'
                                          ? done
                                              ? '☀️ Matin ✅'
                                              : '☀️ Matin'
                                          : done
                                              ? '🌤️ Midi ✅'
                                              : '🌤️ Midi',
                                      style: TextStyle(
                                        color: done
                                            ? AppColors.cafeGrey
                                            : selected
                                                ? Colors.white
                                                : AppColors.cafeDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Fond de caisse
                      TextButton.icon(
                        icon: const Icon(Icons.account_balance_wallet,
                            color: AppColors.cafeBrown),
                        label: Text(
                          _vm.fondCaisse > 0
                              ? '${_vm.fondCaisse.toStringAsFixed(3)} DT'
                              : 'Fond',
                          style:
                              const TextStyle(color: AppColors.cafeBrown),
                        ),
                        onPressed: _showFondDialog,
                      ),
                    ],
                  ),
                ),

                // ── Liste des produits ──
                Expanded(
                  child: _vm.produits.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun produit dans le menu.\nDemandez au chef d\'en ajouter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.cafeGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _vm.produits.length,
                          itemBuilder: (_, i) {
                            final p = _vm.produits[i];
                            final qty = _vm.panier[p.nom] ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nom,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.cafeDark)),
                                        Text(
                                          '${p.prix.toStringAsFixed(3)} DT',
                                          style: const TextStyle(
                                              color: AppColors.cafeGreen,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Contrôles quantité
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: AppColors.cafeRed),
                                        onPressed: qty > 0
                                            ? () =>
                                                _vm.retirerDuPanier(p.nom)
                                            : null,
                                      ),
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '$qty',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle,
                                            color: AppColors.cafeBrown),
                                        onPressed: () =>
                                            _vm.ajouterAuPanier(p.nom),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // ── Résumé panier + Valider ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, -2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Résumé panier
                      if (_vm.panier.isNotEmpty) ...[
                        ..._vm.panier.entries.map((e) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${e.key} ×${e.value}',
                                      style: const TextStyle(
                                          color: AppColors.cafeDark)),
                                  Text(
                                    '${(_vm.produits.firstWhere((p) => p.nom == e.key, orElse: () => Produit(id: '', nom: '', prix: 0, categorie: '')).prix * e.value).toStringAsFixed(3)} DT',
                                    style: const TextStyle(
                                        color: AppColors.cafeGrey),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total session',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cafeDark)),
                          Text(
                            '${_vm.totalPanier.toStringAsFixed(3)} DT',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cafeBrown,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _vm.panier.isEmpty
                                  ? null
                                  : _vm.viderPanier,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.cafeRed),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Vider',
                                  style:
                                      TextStyle(color: AppColors.cafeRed)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed:
                                  _vm.isLoading || _vm.panier.isEmpty
                                      ? null
                                      : _valider,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cafeBrown,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _vm.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      '✅ Valider la caisse',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}