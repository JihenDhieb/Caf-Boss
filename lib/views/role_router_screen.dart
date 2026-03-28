// lib/views/role_router_screen.dart
import 'package:cafeboss/views/caisse_screen.dart';
import 'package:cafeboss/views/dashborad_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cafeboss/services/AuthService.dart';

import 'package:cafeboss/views/signin_screen.dart';

class RoleRouterScreen extends StatelessWidget {
  const RoleRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isLoggedIn) {
      return const SigninScreen();
    }

    // Chef → Dashboard complet
    if (auth.currentUser!.isChef) {
      return const DashbordScreen();
    }

    // Serveur → Caisse uniquement
    return const CaisseScreen();
  }
}