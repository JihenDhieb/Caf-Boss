import 'package:cafeboss/services/AuthService.dart';
import 'package:cafeboss/services/firebase_service.dart';

import 'package:flutter/material.dart';

class ActivateViewModel extends ChangeNotifier {
final FirebaseService _service ;
final AuthService _authservice;
  ActivateViewModel(this._service , this._authservice);
  bool isLoading = false;
  String? erreur;
  Future<bool> verifierCode(String code , AuthService prefs) async {
    isLoading = true ;
    erreur = null ;
  
    notifyListeners();
    final valide = await _service.verifierCode(code);
    if(valide) {
      await _authservice.activate(180);
    }else{
      erreur = 'Code invalide';
    }
    isLoading = false ;
    notifyListeners();
    return valide ;
      }










}