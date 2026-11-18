import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

/// Histórico das decisões tomadas pelos gestores (salvo no aparelho).
class DecisionsScreen extends StatelessWidget {
  const DecisionsScreen({super.key});

  Future<void> _delete(BuildContext context, Decision d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text('A decisão sobre "${d.alertTitle}" será removida.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().removeDecision(d.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decisions = context.watch<AppState>().decisions;

    return Scaffold(
      appBar: AppBar(title: const Text('Decisões registradas')),
      body: decisions.isEmpty
          ? const EmptyMessage(
              icon: Icons.fact_check_outlined,
              text:
                  'Nenhuma decisão ainda. Abra um alerta e toque em "Registrar decisão".',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                for (final d in decisions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DecisionCard(
                      decision: d,
                      onDelete: () => _delete(context, d),
                    ),
                  ),
              ],
            ),
    );
  }
}
