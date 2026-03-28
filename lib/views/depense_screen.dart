import 'package:cafeboss/core/app_colors.dart';
import 'package:cafeboss/viewmodels/depense_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DepenseScreen extends StatefulWidget {
  const DepenseScreen({super.key});

  @override
  State<DepenseScreen> createState() => _DepenseScreenState();
}

class _DepenseScreenState extends State<DepenseScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<DepenseViewModel>().loadDepenses());
  }

  void _showAddDialog() {
    final montantController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '💸 Ajouter Dépense',
          style: TextStyle(
            color: AppColors.cafeBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant (DT)',
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: AppColors.cafeRed,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Note (optionnel)',
                prefixIcon: const Icon(
                  Icons.note,
                  color: AppColors.cafeBrown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.cafeGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cafeRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final montant =
                  double.tryParse(montantController.text) ?? 0;
              final note = noteController.text;

              if (montant <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Montant invalide'),
                  ),
                );
                return;
              }

              await context
                  .read<DepenseViewModel>()
                  .addDepense(montant, note);

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Dépense enregistrée'),
                  backgroundColor: AppColors.cafeGreen,
                ),
              );
            },
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DepenseViewModel>();

    return Scaffold(
      backgroundColor: AppColors.cafeCream,
      appBar: AppBar(
        backgroundColor: AppColors.cafeRed,
        title: const Text(
          '💸 Dépenses',
          style: TextStyle(color: AppColors.cafeWhite),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.depenses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('💸', style: TextStyle(fontSize: 60)),
                      SizedBox(height: 16),
                      Text(
                        'Aucune dépense aujourd\'hui',
                        style: TextStyle(
                          color: AppColors.cafeGrey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Total dépenses
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cafeRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '💸 Total dépenses :',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${vm.depenses.fold(0.0, (s, e) => s + e.montant).toStringAsFixed(3)} DT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Liste dépenses
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: vm.depenses.length,
                        itemBuilder: (context, index) {
                          final d = vm.depenses[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.cafeRed
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.money_off,
                                        color: AppColors.cafeRed,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.note.isEmpty
                                              ? 'Dépense'
                                              : d.note,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.cafeDark,
                                          ),
                                        ),
                                        Text(
                                          '${d.date.hour}:${d.date.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: AppColors.cafeGrey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  '${d.montant.toStringAsFixed(3)} DT',
                                  style: const TextStyle(
                                    color: AppColors.cafeRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.cafeRed,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}