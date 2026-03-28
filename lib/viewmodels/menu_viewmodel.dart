// lib/viewmodels/menu_viewmodel.dart
import 'package:cafeboss/models/produit_model.dart';
import 'package:cafeboss/services/firebase_service.dart';
import 'package:flutter/material.dart';

class MenuViewModel extends ChangeNotifier {
  final FirebaseService _firebase;
  final String chefId;

  MenuViewModel({required FirebaseService firebase, required this.chefId})
      : _firebase = firebase;

  List<Produit> _produits = [];
  List<Produit> get produits => List.unmodifiable(_produits);

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadProduit() async {
    _loading = true;
    notifyListeners();
    _produits = await _firebase.getProduits(chefId);
    _loading = false;
    notifyListeners();
  }

  // ✅ Fixed: accepts (nom, prix, emoji) to match MenuScreen call
  Future<void> addProduit(String nom, double prix, String emoji) async {
    final p = Produit(
      id: '',
      nom: nom,
      prix: prix,
      emoji: emoji,
    );
    await _firebase.addProduit(chefId, p);
    await loadProduit();
  }

  Future<void> deleteProduit(String id) async {
    await _firebase.deleteProduit(chefId, id);
    await loadProduit();
  }
}