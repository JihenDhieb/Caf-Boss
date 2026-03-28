import 'package:cafeboss/services/AuthService.dart';
import 'package:cafeboss/services/firebase_service.dart';
import 'package:cafeboss/viewmodels/dashboard_viewmodel.dart';
import 'package:cafeboss/viewmodels/depense_viewmodel.dart';
import 'package:cafeboss/viewmodels/menu_viewmodel.dart';
import 'package:cafeboss/views/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirebaseService()),

        // ✅ Se reconstruit automatiquement après login
        ChangeNotifierProxyProvider<AuthService, MenuViewModel>(
          create: (ctx) => MenuViewModel(
            firebase: ctx.read<FirebaseService>(),
            chefId: '',
          ),
          update: (ctx, auth, previous) {
            final chefId = auth.currentUser?.uid ?? '';
            // Pas de reconstruction inutile si le chefId n'a pas changé
            if (previous != null && previous.chefId == chefId) return previous;
            final vm = MenuViewModel(
              firebase: ctx.read<FirebaseService>(),
              chefId: chefId,
            );
            if (chefId.isNotEmpty) vm.loadProduit();
            return vm;
          },
        ),

        // ✅ Se reconstruit après login du chef
        ChangeNotifierProxyProvider<AuthService, DashboardViewModel>(
          create: (ctx) => DashboardViewModel(
            firebase: ctx.read<FirebaseService>(),
            chefId: '',
          ),
          update: (ctx, auth, previous) {
            final chefId = auth.currentUser?.uid ?? '';
            if (previous != null && previous.chefId == chefId) return previous;
            final vm = DashboardViewModel(
              firebase: ctx.read<FirebaseService>(),
              chefId: chefId,
            );
            if (chefId.isNotEmpty) vm.loadData();
            return vm;
          },
        ),

        // ✅ DepenseViewModel reçoit AuthService directement
        ChangeNotifierProxyProvider<AuthService, DepenseViewModel>(
          create: (ctx) => DepenseViewModel(
            ctx.read<FirebaseService>(),
            ctx.read<AuthService>(),
          ),
          update: (ctx, auth, previous) =>
              previous ??
              DepenseViewModel(
                ctx.read<FirebaseService>(),
                ctx.read<AuthService>(),
              ),
        ),

        // ❌ CaisseViewModel RETIRÉ des providers globaux
        // → Il est instancié localement dans CaisseScreen.initState()
      ],
      child: const CafeBossApp(),
    ),
  );
}

class CafeBossApp extends StatelessWidget {
  const CafeBossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CafeBoss',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}