import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'decision_form_screen.dart';

/// Lista de alertas preditivos da região.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas preditivos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(s.region.name, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          if (s.alerts.isEmpty)
            EmptyMessage(
              icon: Icons.verified_outlined,
              text: s.loading
                  ? 'Carregando…'
                  : 'Nenhum alerta. Indicadores e previsão do tempo estão dentro dos limites.',
            )
          else
            for (final a in s.alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AlertTile(
                  alert: a,
                  decision: s.decisionFor(a.id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AlertDetailScreen(alertId: a.id)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Detalhe: justificativa, confiança, limitações e opções de resposta.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final alert = s.alertById(alertId);

    if (alert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerta')),
        body: const EmptyMessage(
          icon: Icons.update,
          text: 'Este alerta não está mais ativo após a atualização dos dados.',
        ),
      );
    }

    final decision = s.decisionFor(alert.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            Tag(alert.level.label,
                color: alert.level.color, icon: alert.level.icon),
            if (alert.highImpact)
              const Tag('Decisão de alto impacto',
                  color: AppColors.red, icon: Icons.gavel_outlined),
          ]),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(alert.title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
          ),
          const SizedBox(height: 6),
          Text(alert.summary,
              style: const TextStyle(fontSize: 16, color: AppColors.text)),

          const SectionTitle('Por que este alerta?'),
          BulletBox(items: alert.justification),

          const SectionTitle('Nível de confiança'),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConfidenceBar(value: alert.confidence),
                const SizedBox(height: 8),
                Text(alert.confidenceNote,
                    style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),

          const SectionTitle('Limitações'),
          BulletBox(color: AppColors.amber, items: alert.limitations),

          const SectionTitle('Opções de resposta',
              subtitle: 'Sugestões. O app não executa nenhuma delas.'),
          BulletBox(color: AppColors.blue, items: [
            ...alert.options,
            if (alert.highImpact)
              'Atenção: decisão de alto impacto. A execução depende da validação da instância competente (secretaria, comitê, Defesa Civil).',
          ]),

          if (decision != null) ...[
            const SectionTitle('Última decisão registrada'),
            DecisionCard(decision: decision),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DecisionFormScreen(alert: alert)),
              ),
              icon: const Icon(Icons.edit_note),
              label: Text(decision == null
                  ? 'Registrar decisão'
                  : 'Registrar nova decisão'),
            ),
          ),
        ],
      ),
    );
  }
}
