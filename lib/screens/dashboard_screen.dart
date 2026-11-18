import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'home_screen.dart';
import 'region_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  IndicatorType _selected = IndicatorType.water;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final chartIndicator =
        s.indicators.where((i) => i.type == _selected).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Territorial'),
        actions: [
          IconButton(
            tooltip: 'Ajustes, acessibilidade e privacidade',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: s.loading ? null : s.load,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ---- Região ----
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: s.region.id,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.surfaceHigh,
                  iconEnabledColor: AppColors.primary,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                  items: [
                    for (final r in s.regions)
                      DropdownMenuItem(
                        value: r.id,
                        child: Text(r.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (id) {
                    if (id != null) {
                      s.selectRegion(s.regions.firstWhere((r) => r.id == id));
                    }
                  },
                ),
                Text('${fmtNum(s.region.population.toDouble())} habitantes',
                    style: const TextStyle(color: AppColors.muted)),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegionFormScreen()),
                  ),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Cadastrar nova região'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SourceLine(state: s),

          if (s.indicators.isEmpty)
            const EmptyMessage(
                icon: Icons.hourglass_empty, text: 'Carregando dados…')
          else ...[
            // ---- Resumo de alertas ----
            const SectionTitle('Alertas'),
            Row(children: [
              for (final level in Level.values.reversed) ...[
                Expanded(
                  child: _CountBox(
                    level: level,
                    count: s.alerts.where((a) => a.level == level).length,
                    onTap: widget.onOpenAlerts,
                  ),
                ),
                if (level != Level.watch) const SizedBox(width: 8),
              ],
            ]),

            // ---- Indicadores ----
            const SectionTitle('Indicadores',
                subtitle: 'Média dos últimos 7 dias. Toque para ver o gráfico.'),
            LayoutBuilder(builder: (context, c) {
              final width = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final ind in s.indicators)
                    SizedBox(
                      width: width,
                      child: IndicatorTile(
                        indicator: ind,
                        selected: ind.type == _selected,
                        onTap: () => setState(() => _selected = ind.type),
                      ),
                    ),
                ],
              );
            }),

            // ---- Gráfico ----
            if (chartIndicator != null) ...[
              SectionTitle('Gráfico: ${chartIndicator.type.label}',
                  subtitle: 'Em ${chartIndicator.type.unit}'),
              Panel(child: BarChart(indicator: chartIndicator)),
            ],

            // ---- Clima ----
            SectionTitle('Clima: próximos dias',
                subtitle: s.source == DataSource.simulated
                    ? 'Simulado (sem internet)'
                    : 'Fonte: Open-Meteo'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final d in s.forecast) _WeatherBox(day: d),
              ]),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final when =
        state.updatedAt == null ? '' : ' (${fmtDateTime(state.updatedAt!)})';
    final (IconData icon, Color color, String text) = state.loading
        ? (Icons.sync, AppColors.blue, 'Atualizando dados…')
        : switch (state.source) {
            DataSource.live => (
                Icons.cloud_done_outlined,
                AppColors.green,
                'Clima ao vivo$when'
              ),
            DataSource.cache => (
                Icons.cloud_off_outlined,
                AppColors.amber,
                'Sem internet: clima salvo$when'
              ),
            DataSource.simulated => (
                Icons.cloud_off_outlined,
                AppColors.red,
                'Sem internet: clima simulado'
              ),
            DataSource.loading => (
                Icons.sync,
                AppColors.blue,
                'Atualizando dados…'
              ),
          };
    return Semantics(
      liveRegion: true,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox({required this.level, required this.count, this.onTap});

  final Level level;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$count alertas de nível ${level.label}',
      excludeSemantics: true,
      child: Panel(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: level.color)),
          Text(level.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: level.color)),
        ]),
      ),
    );
  }
}

class _WeatherBox extends StatelessWidget {
  const _WeatherBox({required this.day});

  final DailyWeather day;

  @override
  Widget build(BuildContext context) {
    final icon = day.rain >= 20
        ? Icons.thunderstorm_outlined
        : day.rain >= 2
            ? Icons.water_drop_outlined
            : day.tMax >= 30
                ? Icons.wb_sunny_outlined
                : Icons.cloud_outlined;
    return Semantics(
      label:
          '${weekday(day.date)}, ${fmtDate(day.date)}: máxima de ${day.tMax.round()} graus, ${fmtNum(day.rain, 1)} milímetros de chuva.',
      excludeSemantics: true,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Text(weekday(day.date),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.text)),
          Text(fmtDate(day.date),
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 6),
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 6),
          Text('${day.tMax.round()}°',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.text)),
          Text('${fmtNum(day.rain, 1)} mm',
              style: const TextStyle(fontSize: 12, color: AppColors.blue)),
        ]),
      ),
    );
  }
}
