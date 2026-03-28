import 'package:cafeboss/core/app_colors.dart';
import 'package:cafeboss/models/session_model.dart';
import 'package:cafeboss/models/user_model.dart';
import 'package:cafeboss/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoriqueServeurScreen extends StatefulWidget {
  final UserModel serveur;
  const HistoriqueServeurScreen({super.key, required this.serveur});

  @override
  State<HistoriqueServeurScreen> createState() =>
      _HistoriqueServeurScreenState();
}

class _HistoriqueServeurScreenState extends State<HistoriqueServeurScreen> {
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.serveur.chefId == null) return;
    setState(() => _loading = true);
    final sessions = await context.read<FirebaseService>().getSessionsSemaine(
          widget.serveur.chefId!,
          widget.serveur.uid,
        );
    // Trier du plus récent au plus ancien
    sessions.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatHeure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cafeCream,
      appBar: AppBar(
        backgroundColor: AppColors.cafeBrown,
        title: const Text(
          '📋 Mon historique',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (_, i) => _buildSessionCard(_sessions[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Aucune session cette semaine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.cafeBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vos caisses validées apparaîtront ici',
              style: TextStyle(color: AppColors.cafeGrey, fontSize: 14),
            ),
          ],
        ),
      );

  Widget _buildSessionCard(Session session) {
    final isToday = _isToday(session.date);
    final typeColor =
        session.type == 'matin' ? const Color(0xFFF59E0B) : AppColors.cafeBrown;
    final typeEmoji = session.type == 'matin' ? '☀️' : '🌤️';
    final typeLabel = session.type == 'matin' ? 'Matin' : 'Midi';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppColors.cafeBrown, width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          // ── En-tête ──
          title: Row(
            children: [
              // Badge type session
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: typeColor.withOpacity(0.4)),
                ),
                child: Text(
                  '$typeEmoji $typeLabel',
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cafeGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Aujourd'hui",
                    style: TextStyle(
                      color: AppColors.cafeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatDate(session.date)} · ${_formatHeure(session.date)}',
                  style: const TextStyle(
                    color: AppColors.cafeGrey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${session.total.toStringAsFixed(3)} DT',
                  style: const TextStyle(
                    color: AppColors.cafeBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // ── Détail déroulable ──
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Fond de caisse
            _detailRow(
              Icons.account_balance_wallet_outlined,
              'Fond de caisse',
              '${session.fondCaisse.toStringAsFixed(3)} DT',
              AppColors.cafeGrey,
            ),
            const SizedBox(height: 8),

            // Produits vendus
            if (session.produits.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Produits vendus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.cafeBrown,
                    fontSize: 13,
                  ),
                ),
              ),
              ...session.produits.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: AppColors.cafeGrey),
                          const SizedBox(width: 8),
                          Text(
                            e.key,
                            style: const TextStyle(
                              color: AppColors.cafeDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cafeBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '×${e.value}',
                          style: const TextStyle(
                            color: AppColors.cafeBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16),
            ],

            // Total
            _detailRow(
              Icons.payments_outlined,
              'Total session',
              '${session.total.toStringAsFixed(3)} DT',
              AppColors.cafeGreen,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.cafeGrey,
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}