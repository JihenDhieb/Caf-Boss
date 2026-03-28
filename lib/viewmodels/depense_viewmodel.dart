// lib/viewmodels/depense_viewmodel.dart
import 'package:cafeboss/models/depense_model.dart';
import 'package:cafeboss/services/AuthService.dart';

import 'package:cafeboss/services/firebase_service.dart';
import 'package:flutter/material.dart';

class DepenseViewModel extends ChangeNotifier {
  final FirebaseService _service;
  final AuthService _auth;

  DepenseViewModel(this._service, this._auth);

  List<Depense> depenses = [];
  bool isLoading = false;

  String get _chefId => _auth.chefId ?? '';

  // ── Charger les dépenses du jour ──
  Future<void> loadDepenses() async {
    if (_chefId.isEmpty) return;
    isLoading = true;
    notifyListeners();

    depenses = await _service.getDepensesJour(DateTime.now(), _chefId);

    isLoading = false;
    notifyListeners();
  }

  // ── Ajouter une dépense ──
  Future<void> addDepense(double montant, String note) async {
    if (_chefId.isEmpty) return;
    isLoading = true;
    notifyListeners();

    final d = Depense(
      id: '',
      montant: montant,
      note: note,
      date: DateTime.now(),
      chefId: _chefId,
    );

    await _service.addDepense(_chefId, d);
    await loadDepenses();

    isLoading = false;
    notifyListeners();
  }
}