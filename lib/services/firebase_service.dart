import 'package:cafeboss/models/depense_model.dart';
import 'package:cafeboss/models/produit_model.dart';
import 'package:cafeboss/models/session_model.dart';
import 'package:cafeboss/models/user_model.dart';
import 'package:cafeboss/models/vente_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =====================================================================
  // PRODUITS — chefs/{chefId}/menu
  // =====================================================================

  Future<List<Produit>> getProduits(String chefId) async {
    final snapshot = await _db
        .collection('chefs')
        .doc(chefId)
        .collection('menu')
        .get();
    return snapshot.docs
        .map((doc) => Produit.fromJson(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Produit>> streamProduits(String chefId) {
    return _db
        .collection('chefs')
        .doc(chefId)
        .collection('menu')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Produit.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> addProduit(String chefId, Produit p) async {
    await _db
        .collection('chefs')
        .doc(chefId)
        .collection('menu')
        .add(p.toJson());
  }

  Future<void> updateProduit(String chefId, Produit p) async {
    await _db
        .collection('chefs')
        .doc(chefId)
        .collection('menu')
        .doc(p.id)
        .update(p.toJson());
  }

  Future<void> deleteProduit(String chefId, String produitId) async {
    await _db
        .collection('chefs')
        .doc(chefId)
        .collection('menu')
        .doc(produitId)
        .delete();
  }

  // =====================================================================
  // SERVEURS — chefs/{chefId}/serveurs/{serveurId}
  // =====================================================================

  Stream<List<UserModel>> streamServeurs(String chefId) {
    return _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<List<UserModel>> getServeurs(String chefId) async {
    final snap = await _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .get();
    return snap.docs
        .map((doc) => UserModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> deleteServeur(String chefId, String serveurId) async {
    await _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .doc(serveurId)
        .delete();
    await _db.collection('users').doc(serveurId).delete();
  }

  // =====================================================================
  // SESSIONS — chefs/{chefId}/serveurs/{serveurId}/sessions/{id}
  // =====================================================================

  Future<void> addSession(String chefId, String serveurId, Session s) async {
    await _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .doc(serveurId)
        .collection('sessions')
        .add(s.toJson());
  }

  Future<List<Session>> getSessionsServeurJour(
      String chefId, String serveurId, DateTime date) async {
    final debut = DateTime(date.year, date.month, date.day);
    final fin = debut.add(const Duration(days: 1));
    final snap = await _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .doc(serveurId)
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: debut.toIso8601String())
        .where('date', isLessThan: fin.toIso8601String())
        .get();
    return snap.docs
        .map((doc) => Session.fromJson(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Session>> streamSessionsServeurJour(
      String chefId, String serveurId, DateTime date) {
    final debut = DateTime(date.year, date.month, date.day);
    final fin = debut.add(const Duration(days: 1));
    return _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .doc(serveurId)
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: debut.toIso8601String())
        .where('date', isLessThan: fin.toIso8601String())
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Session.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Toutes les sessions de tous les serveurs d'un chef — aujourd'hui
  Future<List<Session>> getAllSessionsChefJour(
      String chefId, DateTime date) async {
    final serveurs = await getServeurs(chefId);
    final List<Session> toutes = [];
    for (final serveur in serveurs) {
      final sessions =
          await getSessionsServeurJour(chefId, serveur.uid, date);
      toutes.addAll(sessions);
    }
    return toutes;
  }

  /// 7 derniers jours — toutes sessions de tous les serveurs
  Future<List<Session>> getAllSessionsSemaine(String chefId) async {
    final serveurs = await getServeurs(chefId);
    final debut = DateTime.now().subtract(const Duration(days: 7));
    final List<Session> toutes = [];
    for (final serveur in serveurs) {
      final snap = await _db
          .collection('chefs')
          .doc(chefId)
          .collection('serveurs')
          .doc(serveur.uid)
          .collection('sessions')
          .where('date', isGreaterThanOrEqualTo: debut.toIso8601String())
          .orderBy('date', descending: true)
          .get();
      toutes.addAll(snap.docs
          .map((doc) => Session.fromJson(doc.data(), doc.id))
          .toList());
    }
    return toutes;
  }

  /// Sessions d'un serveur spécifique — 7 derniers jours
  Future<List<Session>> getSessionsSemaine(
      String chefId, String serveurId) async {
    final debut = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .doc(serveurId)
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: debut.toIso8601String())
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((doc) => Session.fromJson(doc.data(), doc.id))
        .toList();
  }

  // =====================================================================
  // VENTES — chefs/{chefId}/serveurs/{serveurId}/ventes/{id}
  // =====================================================================

  Future<void> addVente(String chefId, String serveurId, Vente v) async {
    await _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .doc(serveurId)
        .collection('ventes')
        .add(v.toJson());
  }

  Future<List<Vente>> getVentesServeurJour(
      String chefId, String serveurId, DateTime date) async {
    final debut = DateTime(date.year, date.month, date.day);
    final fin = debut.add(const Duration(days: 1));
    final snap = await _db
        .collection('chefs')
        .doc(chefId)
        .collection('serveurs')
        .doc(serveurId)
        .collection('ventes')
        .where('date', isGreaterThanOrEqualTo: debut.toIso8601String())
        .where('date', isLessThan: fin.toIso8601String())
        .get();
    return snap.docs.map((doc) => Vente.fromJson(doc.data())).toList();
  }

  /// Toutes les ventes du jour de tous les serveurs — pour top produits
  Future<List<Vente>> getAllVentesChefJour(
      String chefId, DateTime date) async {
    final serveurs = await getServeurs(chefId);
    final List<Vente> toutes = [];
    for (final serveur in serveurs) {
      final ventes =
          await getVentesServeurJour(chefId, serveur.uid, date);
      toutes.addAll(ventes);
    }
    return toutes;
  }

  // =====================================================================
  // DÉPENSES — chefs/{chefId}/depenses/{id}
  // =====================================================================

  Future<void> addDepense(String chefId, Depense d) async {
    await _db
        .collection('chefs')
        .doc(chefId)
        .collection('depenses')
        .add(d.toJson());
  }

  Future<List<Depense>> getDepensesJour(DateTime date, String chefId) async {
    final debut = DateTime(date.year, date.month, date.day);
    final fin = debut.add(const Duration(days: 1));
    final snap = await _db
        .collection('chefs')
        .doc(chefId)
        .collection('depenses')
        .where('date', isGreaterThanOrEqualTo: debut.toIso8601String())
        .where('date', isLessThan: fin.toIso8601String())
        .get();
    return snap.docs.map((doc) => Depense.fromJson(doc.data())).toList();
  }

  Stream<List<Depense>> streamDepensesJour(String chefId, DateTime date) {
    final debut = DateTime(date.year, date.month, date.day);
    final fin = debut.add(const Duration(days: 1));
    return _db
        .collection('chefs')
        .doc(chefId)
        .collection('depenses')
        .where('date', isGreaterThanOrEqualTo: debut.toIso8601String())
        .where('date', isLessThan: fin.toIso8601String())
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Depense.fromJson(doc.data())).toList());
  }

  // =====================================================================
  // CODES D'ACTIVATION
  // =====================================================================

  Future<bool> verifierCode(String code) async {
    final doc = await _db.collection('codes').doc(code).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['utilise'] == false) {
        await _db.collection('codes').doc(code).update({'utilise': true});
        return true;
      }
    }
    return false;
  }
}