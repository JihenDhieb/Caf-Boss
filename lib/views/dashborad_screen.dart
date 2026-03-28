import 'package:cafeboss/core/app_colors.dart';
import 'package:cafeboss/models/session_model.dart';
import 'package:cafeboss/services/AuthService.dart';
import 'package:cafeboss/viewmodels/dashboard_viewmodel.dart';
import 'package:cafeboss/views/depense_screen.dart';
import 'package:cafeboss/views/historiques_screen.dart';
import 'package:cafeboss/views/menu_screen.dart';
import 'package:cafeboss/views/serveurs_screen.dart';
import 'package:cafeboss/views/signin_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashbordScreen extends StatelessWidget {
  const DashbordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final user = context.read<AuthService>().currentUser;
    final date = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.cafeCream,
      appBar: AppBar(
        backgroundColor: AppColors.cafeBrown,
        elevation: 0,
        title: Text(
          '☕ ${user?.nomCafe}',
          style: const TextStyle(
            color: AppColors.cafeWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      actions: [
  Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Center(
      child: Text(
        '${date.day}/${date.month}/${date.year}',
        style: const TextStyle(
          color: AppColors.cafeWhite,
          fontSize: 13,
        ),
      ),
    ),
  ),
  IconButton(
    icon: const Icon(Icons.logout, color: AppColors.cafeWhite),
    tooltip: 'Déconnexion',
    onPressed: () async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cafeBrown,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Déconnecter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        await context.read<AuthService>().signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SigninScreen()),
          (route) => false,
        );
      }
    },
  ),
],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Salutation ──
                    Text(
                      'Bonjour ${user?.nomChef} 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cafeBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Voici le résumé de votre journée',
                      style: TextStyle(
                        color: AppColors.cafeGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Cards Résumé ──
                    Row(
                      children: [
                        _buildCard(
                          '💰',
                          'Recettes',
                          '${vm.totalRecettes.toStringAsFixed(3)} DT',
                          AppColors.cafeGreen,
                        ),
                        const SizedBox(width: 12),
                        _buildCard(
                          '💸',
                          'Dépenses',
                          '${vm.totalDepenses.toStringAsFixed(3)} DT',
                          AppColors.cafeRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCardFull(
                      '✅',
                      'Bénéfice Net',
                      '${vm.benefice.toStringAsFixed(3)} DT',
                      vm.benefice >= 0 ? AppColors.cafeBrown : AppColors.cafeRed,
                    ),
                    const SizedBox(height: 24),

                    // ── Services ──
                    const Text(
                      '📋 Services du jour',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cafeBrown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildService(
                          '☀️',
                          'Matin',
                          '${vm.totalMatin.toStringAsFixed(3)} DT',
                          vm.sessionsMatin.isEmpty,
                        ),
                        const SizedBox(width: 12),
                        _buildService(
                          '🌤️',
                          'Midi',
                          '${vm.totalMidi.toStringAsFixed(3)} DT',
                          vm.sessionsMidi.isEmpty,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Recettes par serveur ──
                    if (vm.serveurs.isNotEmpty) ...[
                      const Text(
                        '👥 Recettes par serveur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cafeBrown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...vm.serveurs.map((s) {
                        final total = vm.getTotalParServeur(s.uid);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.cafeBrown,
                                child: Text(
                                  s.nomChef.isNotEmpty
                                      ? s.nomChef[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.nomChef,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.cafeDark,
                                      ),
                                    ),
                                    Text(
                                      '${vm.getSessionsParServeur(s.uid).length} session(s)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.cafeGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(3)} DT',
                                style: TextStyle(
                                  color: total > 0
                                      ? AppColors.cafeGreen
                                      : AppColors.cafeGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // ── Top Produits ──
                    if (vm.topProduits.isNotEmpty) ...[
                      const Text(
                        '🏆 Top produits du jour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cafeBrown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...vm.topProduits.entries.take(5).toList().asMap().entries.map(
                        (entry) {
                          final rank = entry.key + 1;
                          final nom = entry.value.key;
                          final qty = entry.value.value;
                          final medals = ['🥇', '🥈', '🥉'];
                          final medal = rank <= 3 ? medals[rank - 1] : '▪️';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(medal,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nom,
                                    style: const TextStyle(
                                      color: AppColors.cafeDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.cafeBrown,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '×$qty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Graphique 7 jours ──
                    if (vm.sessionsSemaine.isNotEmpty) ...[
                      const Text(
                        '📊 7 derniers jours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cafeBrown,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 180,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _buildGraphique(vm.sessionsSemaine),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Dépenses du jour ──
                    if (vm.depenses.isNotEmpty) ...[
                      const Text(
                        '💸 Dépenses du jour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cafeBrown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...vm.depenses.map((d) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.money_off,
                                        color: AppColors.cafeRed),
                                    const SizedBox(width: 8),
                                    Text(
                                      d.note.isEmpty ? 'Dépense' : d.note,
                                      style: const TextStyle(
                                          color: AppColors.cafeDark),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${d.montant.toStringAsFixed(3)} DT',
                                  style: const TextStyle(
                                    color: AppColors.cafeRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

      // ── Bottom Nav ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildNavButton(
              context,
              '👥',
              'Serveurs',
              AppColors.cafeBrown,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ServeursScreen())),
            ),
            const SizedBox(width: 8),
            _buildNavButton(
              context,
              '💸',
              'Dépense',
              AppColors.cafeRed,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DepenseScreen())),
            ),
            const SizedBox(width: 8),
            _buildNavButton(
              context,
              '📋',
              'Menu',
              AppColors.cafeGreen,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MenuScreen())),
            ),
            const SizedBox(width: 8),
            _buildNavButton(
              context,
              '📈',
              'Historique',
              AppColors.cafeYellow,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoriqueScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget Card petite ──
  Widget _buildCard(String emoji, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget Card pleine largeur ──
  Widget _buildCardFull(
      String emoji, String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget Service ──
  Widget _buildService(
      String emoji, String label, String value, bool empty) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: empty ? Colors.grey[200] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: empty ? Colors.grey : AppColors.cafeBrown,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: empty ? AppColors.cafeGrey : AppColors.cafeBrown,
              ),
            ),
            Text(
              empty ? 'Pas encore' : value,
              style: TextStyle(
                color: empty ? AppColors.cafeGrey : AppColors.cafeGreen,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Graphique ──
  Widget _buildGraphique(List<Session> sessions) {
    final Map<String, double> parJour = {};
    for (final s in sessions) {
      final key = '${s.date.day}/${s.date.month}';
      parJour[key] = (parJour[key] ?? 0) + s.total;
    }
    final days = parJour.entries.toList();

    return BarChart(
      BarChartData(
        barGroups: List.generate(days.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: days[i].value,
                color: AppColors.cafeBrown,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= days.length) return const Text('');
                return Text(
                  days[value.toInt()].key,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.cafeBrown,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Nav Button ──
  Widget _buildNavButton(BuildContext context, String emoji, String label,
      Color color, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}