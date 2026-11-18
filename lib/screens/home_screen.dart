import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'decisions_screen.dart';

/// Navegação principal: 3 abas, troca instantânea.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pending = context.select<AppState, int>((s) => s.pendingCount);

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardScreen(onOpenAlerts: () => setState(() => _tab = 1)),
          const AlertsScreen(),
          const DecisionsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.warning_amber_outlined),
            ),
            label: 'Alertas',
            tooltip: pending > 0 ? 'Alertas: $pending sem decisão' : 'Alertas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Decisões',
          ),
        ],
      ),
    );
  }
}

/// Ajustes: acessibilidade, privacidade, fontes de dados e apagar tudo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const textSizes = [
    (scale: 1.0, label: 'Normal'),
    (scale: 1.2, label: 'Grande'),
    (scale: 1.4, label: 'Muito grande'),
  ];

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar dados salvos?'),
        content: const Text(
            'Decisões, regiões cadastradas, preferências e clima salvo serão apagados deste aparelho.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Apagar', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final state = context.read<AppState>();
      Navigator.pop(context);
      await state.clearData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SectionTitle('Acessibilidade',
              subtitle: 'Tamanho do texto, somado ao ajuste do celular'),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final size in textSizes)
                      ChoiceChip(
                        label: Text(size.label),
                        selected: state.textScale == size.scale,
                        onSelected: (_) => state.setTextScale(size.scale),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Exemplo: assim fica o texto dos alertas e indicadores.',
                  style: TextStyle(color: AppColors.text),
                ),
              ],
            ),
          ),
          const SectionTitle('Proteção dos cidadãos'),
          const BulletBox(items: [
            'O app não coleta dados pessoais: usa apenas totais por região (consumo, população).',
            'Contagens menores que 5 aparecem como "<5", para ninguém ser identificado em comunidades pequenas.',
            'Os campos de texto recusam CPF, e-mail e telefone. O responsável é registrado por cargo ou setor, nunca por nome.',
            'Para buscar o clima, só o ponto central da região é enviado, arredondado (~1 km).',
            'Regiões, decisões e preferências ficam salvas apenas neste aparelho.',
          ]),
          const SectionTitle('Fontes de dados'),
          const BulletBox(color: AppColors.blue, items: [
            'Clima (temperatura e chuva): API pública Open-Meteo, open-meteo.com.',
            'Água, energia, resíduos e chamados: dados simulados, calculados a partir da população e do clima real.',
            'População: estimativas aproximadas para as 3 regiões de exemplo.',
          ]),
          const SectionTitle('Limitações'),
          const BulletBox(color: AppColors.amber, items: kLimitations),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                minimumSize: const Size(64, 52),
              ),
              onPressed: () => _clear(context),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Apagar dados salvos'),
            ),
          ),
        ],
      ),
    );
  }
}
