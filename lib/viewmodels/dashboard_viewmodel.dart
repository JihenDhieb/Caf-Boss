import 'package:cafeboss/models/depense_model.dart';
import 'package:cafeboss/models/session_model.dart';
import 'package:cafeboss/models/user_model.dart';
import 'package:cafeboss/models/vente_model.dart';
import 'package:cafeboss/services/firebase_service.dart';
import 'package:flutter/material.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseService _firebase;
  final String chefId;

  DashboardViewModel({required FirebaseService firebase, required this.chefId})
      : _firebase = firebase;

  List<Session> _sessions = [];
  List<Session> _sessionsSemaine = [];
  List<Depense> _depenses = [];
  List<UserModel> _serveurs = [];
  List<Vente> _ventesJour = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Session> get sessions => _sessions;
  List<Depense> get depenses => _depenses;
  List<Session> get sessionsSemaine => _sessionsSemaine;
  List<UserModel> get serveurs => _serveurs;
  List<Vente> get ventesJour => _ventesJour;

  List<Session> get sessionsMatin =>
      _sessions.where((s) => s.type == 'matin').toList();
  List<Session> get sessionsMidi =>
      _sessions.where((s) => s.type == 'midi').toList();

  double get totalMatin =>
      sessionsMatin.fold(0, (sum, s) => sum + s.total);
  double get totalMidi =>
      sessionsMidi.fold(0, (sum, s) => sum + s.total);
  double get totalRecettes =>
      _sessions.fold(0, (sum, s) => sum + s.total);
  double get totalDepenses =>
      _depenses.fold(0, (sum, d) => sum + d.montant);
  double get benefice => totalRecettes - totalDepenses;

  /// Top produits du jour : nom → quantité totale, trié par quantité desc
  Map<String, int> get topProduits {
    final Map<String, int> totaux = {};
    for (final v in _ventesJour) {
      v.produits.forEach((nom, qty) {
        totaux[nom] = (totaux[nom] ?? 0) + qty;
      });
    }
    final sorted = Map.fromEntries(
      totaux.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final date = DateTime.now();

    _serveurs = await _firebase.getServeurs(chefId);
    _sessions = await _firebase.getAllSessionsChefJour(chefId, date);
    _sessionsSemaine = await _firebase.getAllSessionsSemaine(chefId);
    _depenses = await _firebase.getDepensesJour(date, chefId);
    _ventesJour = await _firebase.getAllVentesChefJour(chefId, date);

    _isLoading = false;
    notifyListeners();
  }

  List<Session> getSessionsParServeur(String serveurId) =>
      _sessions.where((s) => s.serveurId == serveurId).toList();

  double getTotalParServeur(String serveurId) =>
      getSessionsParServeur(serveurId).fold(0, (sum, s) => sum + s.total);
}