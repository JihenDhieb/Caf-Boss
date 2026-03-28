import 'package:cafeboss/models/produit_model.dart';
import 'package:cafeboss/models/session_model.dart';
import 'package:cafeboss/models/user_model.dart';
import 'package:cafeboss/models/vente_model.dart';
import 'package:cafeboss/services/firebase_service.dart';
import 'package:flutter/material.dart';

class CaisseViewModel extends ChangeNotifier {
  final FirebaseService _firebase;
  final UserModel serveur;

  CaisseViewModel({required FirebaseService firebase, required this.serveur})
      : _firebase = firebase;

  List<Produit> _produits = [];
  List<Produit> get produits => _produits;

  // panier courant : nom produit → quantité
  final Map<String, int> _panier = {};
  Map<String, int> get panier => Map.unmodifiable(_panier);

  String _typeSession = 'matin';
  String get typeSession => _typeSession;

  double _fondCaisse = 0;
  double get fondCaisse => _fondCaisse;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Session> _sessionsJour = [];
  List<Session> get sessionsJour => _sessionsJour;

  // Calcul du total du panier
  double get totalPanier {
    double total = 0;
    for (final entry in _panier.entries) {
      final produit = _produits.firstWhere(
        (p) => p.nom == entry.key,
        orElse: () => Produit(id: '', nom: '', prix: 0, categorie: ''),
      );
      total += produit.prix * entry.value;
    }
    return total;
  }

  bool get sessionMatinFaite =>
      _sessionsJour.any((s) => s.type == 'matin');
  bool get sessionMidiFaite =>
      _sessionsJour.any((s) => s.type == 'midi');

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _loadProduits();
    await _loadSessionsJour();

    // Pré-sélectionner le type selon l'heure
    final h = DateTime.now().hour;
    _typeSession = h < 14 ? 'matin' : 'midi';

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProduits() async {
    if (serveur.chefId == null) return;
    _produits = await _firebase.getProduits(serveur.chefId!);
  }

  Future<void> _loadSessionsJour() async {
    if (serveur.chefId == null) return;
    _sessionsJour = await _firebase.getSessionsServeurJour(
      serveur.chefId!,
      serveur.uid,
      DateTime.now(),
    );
  }

  void setTypeSession(String type) {
    _typeSession = type;
    notifyListeners();
  }

  void setFondCaisse(double montant) {
    _fondCaisse = montant;
    notifyListeners();
  }

  void ajouterAuPanier(String nomProduit) {
    _panier[nomProduit] = (_panier[nomProduit] ?? 0) + 1;
    notifyListeners();
  }

  void retirerDuPanier(String nomProduit) {
    if ((_panier[nomProduit] ?? 0) > 0) {
      _panier[nomProduit] = _panier[nomProduit]! - 1;
      if (_panier[nomProduit] == 0) _panier.remove(nomProduit);
      notifyListeners();
    }
  }

  void viderPanier() {
    _panier.clear();
    notifyListeners();
  }

  /// Valide la caisse → écrit Session + Vente dans Firestore
  Future<String?> validerCaisse() async {
    if (_panier.isEmpty) return 'Le panier est vide.';
    if (serveur.chefId == null) return 'ChefId manquant.';

    // Empêcher double session du même type
    final dejaFaite = _sessionsJour.any((s) => s.type == _typeSession);
    if (dejaFaite) return 'Session $_typeSession déjà validée aujourd\'hui.';

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final panierCopie = Map<String, int>.from(_panier);
      final total = totalPanier;

      // 1. Enregistrer la Session
      final session = Session(
        id: '',
        type: _typeSession,
        fondCaisse: _fondCaisse,
        total: total,
        date: now,
        serveurId: serveur.uid,
        serveurNom: serveur.nomChef,
        produits: panierCopie,
      );
      await _firebase.addSession(serveur.chefId!, serveur.uid, session);

      // 2. Enregistrer la Vente (pour top produits chef)
      final vente = Vente(
        serveurId: serveur.uid,
        serveurNom: serveur.nomChef,
        produits: panierCopie,
        total: total,
        date: now,
        typeSession: _typeSession,
      );
      await _firebase.addVente(serveur.chefId!, serveur.uid, vente);

      // Reset
      _panier.clear();
      _fondCaisse = 0;
      await _loadSessionsJour();

      _isLoading = false;
      notifyListeners();
      return null; // succès
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }
}