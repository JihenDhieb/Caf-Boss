// lib/views/historique_screen.dart
import 'package:cafeboss/core/app_colors.dart';
import 'package:cafeboss/models/session_model.dart';
import 'package:cafeboss/services/AuthService.dart';

import 'package:cafeboss/services/firebase_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  List<Session> sessions = [];
  bool isLoading = true;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final service = context.read<FirebaseService>();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;

    List<Session> data;

    if (auth.isChef) {
      // Chef voit toutes les sessions de tous ses serveurs
      data = await service.getAllSessionsSemaine(user.uid);
    } else {
      // Serveur voit uniquement ses propres sessions
      final chefId = user.chefId ?? '';
      data = await service.getSessionsSemaine(chefId, user.uid);
    }

    setState(() {
      sessions = data;
      isLoading = false;
    });
  }

  Map<String, List<Session>> get sessionsByDay {
    final Map<String, List<Session>> map = {};
    for (final s in sessions) {
      final key = '${s.date.day}/${s.date.month}/${s.date.year}';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  List<BarChartGroupData> get barGroups {
    final days = sessionsByDay.entries.toList();
    return List.generate(days.length, (i) {
      final total = days[i].value.fold(0.0, (s, e) => s + e.total);
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            color: AppColors.cafeBrown,
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cafeCream,
      appBar: AppBar(
        backgroundColor: AppColors.cafeBrown,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '📈 Historique',
              style: TextStyle(
                color: AppColors.cafeWhite,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '7 derniers jours',
              style: TextStyle(
                color: AppColors.cafeGrey,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cafeBrown))
          : sessions.isEmpty
              ? _buildEmpty()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChart(),
                      const SizedBox(height: 24),
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _sectionLabel('Détail par jour'),
                      const SizedBox(height: 12),
                      ...sessionsByDay.entries.map(
                        (entry) => _buildDayCard(entry.key, entry.value),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('📋', style: TextStyle(fontSize: 52)),
          SizedBox(height: 14),
          Text(
            'Aucune session trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeBrown,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Les sessions validées apparaîtront ici',
            style: TextStyle(color: AppColors.cafeGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.cafeWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cafeBrown.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeBrown.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.cafeBrown.withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = sessionsByDay.keys.toList();
                  if (value.toInt() >= days.length) return const Text('');
                  final parts = days[value.toInt()].split('/');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${parts[0]}/${parts[1]}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.cafeGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalSemaine = sessions.fold(0.0, (sum, s) => sum + s.total);
    final totalSessions = sessions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cafeBrown,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeBrown.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              label: 'Total semaine',
              value: '${totalSemaine.toStringAsFixed(3)} DT',
            ),
          ),
          Container(
              width: 1, height: 44, color: AppColors.cafeWhite.withOpacity(0.15)),
          Expanded(
            child: _summaryItem(
              label: 'Sessions',
              value: '$totalSessions',
              center: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    bool center = false,
  }) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.cafeWhite.withOpacity(0.6),
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.cafeWhite,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(String day, List<Session> daySessions) {
    final totalJour = daySessions.fold(0.0, (s, e) => s + e.total);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cafeWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cafeBrown.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeBrown.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cafeBrown.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                  bottom:
                      BorderSide(color: AppColors.cafeBrown.withOpacity(0.12))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      day,
                      style: const TextStyle(
                        color: AppColors.cafeBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.cafeBrown,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${totalJour.toStringAsFixed(3)} DT',
                    style: const TextStyle(
                      color: AppColors.cafeWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...daySessions.map((s) => _buildSessionTile(s)),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Session s) {
    final sessionId = '${s.type}_${s.date.millisecondsSinceEpoch}';
    final isExpanded = _expanded.contains(sessionId);
    final totalArticles = s.produits.values.fold(0, (sum, qty) => sum + qty);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() {
            isExpanded
                ? _expanded.remove(sessionId)
                : _expanded.add(sessionId);
          }),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.cafeCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.cafeBrown.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      s.type == 'matin' ? '☀️' : '🌤️',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.type == 'matin' ? 'Service Matin' : 'Service Midi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.cafeDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Afficher le nom du serveur si chef
                      if (s.serveurNom.isNotEmpty)
                        Text(
                          '👤 ${s.serveurNom}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.cafeGrey,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        children: [
                          _chip(
                            '💰 Fond: ${s.fondCaisse.toStringAsFixed(2)} DT',
                            color: AppColors.cafeBrown.withOpacity(0.1),
                            textColor: AppColors.cafeBrown,
                          ),
                          _chip(
                            '$totalArticles articles',
                            color: AppColors.cafeYellow.withOpacity(0.15),
                            textColor: AppColors.cafeYellow,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${s.total.toStringAsFixed(3)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.cafeGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppColors.cafeBrown.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: _buildProduitsDetail(s),
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: AppColors.cafeBrown.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildProduitsDetail(Session s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cafeCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cafeBrown.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cafeBrown.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 4,
                    child: Text('PRODUIT',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.cafeBrown))),
                Expanded(
                    flex: 2,
                    child: Text('QTÉ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.cafeBrown))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(
              children: [
                ...s.produits.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cafeDark,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.cafeBrown.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '×${entry.value}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cafeBrown,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                Divider(
                    color: AppColors.cafeBrown.withOpacity(0.15), height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total session',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cafeDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.cafeGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${s.total.toStringAsFixed(3)} DT',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text,
      {required Color color, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.cafeBrown,
      ),
    );
  }
}