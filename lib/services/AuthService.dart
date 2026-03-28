// lib/services/auth_service.dart
import 'package:cafeboss/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isChef => _currentUser?.isChef ?? false;
  bool get isServeur => _currentUser?.isServeur ?? false;

  /// Retourne l'uid du chef (soi-même si chef, chefId si serveur)
  String? get chefId =>
      isChef ? _currentUser!.uid : _currentUser?.chefId;

  // =====================================================================
  // INSCRIPTION CHEF
  // =====================================================================
Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
  _currentUser = null;
  notifyListeners();
}

  Future<String?> signup({
    required String email,
    required String password,
    required String nomCafe,
    required String nomChef,
    DateTime? premiumUntil,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final user = UserModel(
        uid: uid,
        email: email,
        nomCafe: nomCafe,
        nomChef: nomChef,
        role: 'chef',
        chefId: null,
        premiumUntil: premiumUntil,
      );

      await _db.collection('chefs').doc(uid).set(user.toJson());

      _currentUser = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // =====================================================================
  // CONNEXION (chef ou serveur)
  // =====================================================================

  Future<String?> signin({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // Chercher dans chefs
      final chefDoc = await _db.collection('chefs').doc(uid).get();
      if (chefDoc.exists) {
        _currentUser = UserModel.fromJson(chefDoc.data()!, uid);
        notifyListeners();
        return null;
      }

      // Chercher dans users (serveurs)
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _currentUser = UserModel.fromJson(userDoc.data()!, uid);
        notifyListeners();
        return null;
      }

      return 'Utilisateur non trouvé';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // =====================================================================
  // CRÉER UN SERVEUR (appelé par le chef connecté)
  // =====================================================================

  Future<String?> creerServeur({
    required String email,
    required String password,
    required String nomServeur,
  }) async {
    if (_currentUser == null || !_currentUser!.isChef) return 'Non autorisé';

    try {
      // Créer le compte Firebase Auth via une app secondaire
      // pour ne pas déconnecter le chef
      final secondaryApp = await Firebase.initializeApp(
        name: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      final serveur = UserModel(
        uid: uid,
        email: email,
        nomCafe: _currentUser!.nomCafe,
        nomChef: nomServeur,
        role: 'serveur',
        chefId: _currentUser!.uid,
      );

      // Stocker dans chefs/{chefId}/serveurs/{serveurId}
      await _db
          .collection('chefs')
          .doc(_currentUser!.uid)
          .collection('serveurs')
          .doc(uid)
          .set(serveur.toJson());

      // Aussi dans collection globale pour le login
      await _db.collection('users').doc(uid).set(serveur.toJson());

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // =====================================================================
  // STREAM SERVEURS (pour ServeursScreen)
  // =====================================================================

  Stream<List<UserModel>> streamServeurs() {
    if (_currentUser == null || !_currentUser!.isChef) {
      return const Stream.empty();
    }
    return _db
        .collection('chefs')
        .doc(_currentUser!.uid)
        .collection('serveurs')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // =====================================================================
  // CHARGEMENT AUTO AU DÉMARRAGE
  // =====================================================================

  Future<bool> tryAutoLogin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final chefDoc = await _db.collection('chefs').doc(user.uid).get();
    if (chefDoc.exists) {
      _currentUser = UserModel.fromJson(chefDoc.data()!, user.uid);
      notifyListeners();
      return true;
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      _currentUser = UserModel.fromJson(userDoc.data()!, user.uid);
      notifyListeners();
      return true;
    }

    return false;
  }

  // =====================================================================
  // ACTIVATION PREMIUM
  // =====================================================================

  Future<void> activate(int dureeMinutes) async {
    if (_currentUser == null) return;
    final dateFin = DateTime.now().add(Duration(minutes: dureeMinutes));
    await _db.collection('chefs').doc(_currentUser!.uid).update({
      'premiumUntil': dateFin.toIso8601String(),
    });
    _currentUser = _currentUser!.copyWith(premiumUntil: dateFin);
    notifyListeners();
  }

  bool get isPremium {
    if (_currentUser?.premiumUntil == null) return false;
    return DateTime.now().isBefore(_currentUser!.premiumUntil!);
  }

  // =====================================================================
  // DÉCONNEXION
  // =====================================================================

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}