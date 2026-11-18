import 'dart:math';

import 'package:flutter/material.dart';

import 'theme.dart';

// ---------- Regiões ----------

/// Território monitorado. Só guarda dados agregados (nunca de cidadãos).
class Region {
  const Region({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.population,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final int population;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
        'population': population,
      };

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: j['id'] as String,
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        population: (j['population'] as num).toInt(),
      );
}

/// Regiões de exemplo (as cadastradas pelo gestor são somadas a estas).
const kRegions = [
  Region(
      id: 'sp-se',
      name: 'Sé — São Paulo/SP',
      lat: -23.55,
      lon: -46.63,
      population: 24000),
  Region(
      id: 'recife',
      name: 'Recife/PE',
      lat: -8.05,
      lon: -34.88,
      population: 1490000),
  Region(
      id: 'eldorado',
      name: 'Comunidade rural — Eldorado/SP',
      lat: -24.52,
      lon: -48.11,
      population: 3200),
];

// ---------- Indicadores ----------

enum IndicatorType { water, energy, waste, services }

extension IndicatorInfo on IndicatorType {
  String get label => switch (this) {
        IndicatorType.water => 'Água',
        IndicatorType.energy => 'Energia',
        IndicatorType.waste => 'Resíduos',
        IndicatorType.services => 'Chamados',
      };

  String get unit => switch (this) {
        IndicatorType.water => 'm³/dia',
        IndicatorType.energy => 'MWh/dia',
        IndicatorType.waste => 't/dia',
        IndicatorType.services => 'chamados/dia',
      };

  IconData get icon => switch (this) {
        IndicatorType.water => Icons.water_drop_outlined,
        IndicatorType.energy => Icons.bolt_outlined,
        IndicatorType.waste => Icons.delete_outline,
        IndicatorType.services => Icons.support_agent_outlined,
      };

  int get decimals => switch (this) {
        IndicatorType.energy || IndicatorType.waste => 1,
        _ => 0,
      };

  /// Consumo/demanda por habitante por dia (usado na simulação).
  double get perCapita => switch (this) {
        IndicatorType.water => 0.15, // 150 L
        IndicatorType.energy => 0.0055, // 5,5 kWh
        IndicatorType.waste => 0.00105, // 1,05 kg
        IndicatorType.services => 0.0022, // 2,2 chamados / mil hab.
      };
}

/// Série de 14 dias de um indicador + projeção simples para a próxima semana.
class Indicator {
  Indicator({
    required this.type,
    required this.history,
    required this.capacity,
  });

  final IndicatorType type;

  /// Valores diários, do mais antigo para o mais recente.
  final List<double> history;
  final double capacity;

  static double _mean(Iterable<double> v) =>
      v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

  double get lastWeek => _mean(history.skip(history.length - 7));
  double get previousWeek => _mean(history.take(history.length - 7));

  /// Variação da última semana em relação à anterior.
  double get weeklyChange =>
      previousWeek == 0 ? 0 : (lastWeek - previousWeek) / previousWeek;

  /// Média esperada da próxima semana se a tendência continuar.
  double get projection => lastWeek * (1 + weeklyChange);

  double get usage => lastWeek / capacity;
  double get projectedUsage => projection / capacity;

  /// Próximos 7 dias seguindo a mesma tendência diária.
  List<double> get projectedDays {
    final perDay = (lastWeek - previousWeek) / 7;
    return [for (var i = 1; i <= 7; i++) max(0.0, history.last + perDay * i)];
  }

  /// Instabilidade da série: desvio das variações diárias / média.
  double get noise {
    if (history.length < 3) return 1;
    final diffs = [
      for (var i = 1; i < history.length; i++) history[i] - history[i - 1]
    ];
    final m = _mean(diffs);
    final variance = _mean(diffs.map((d) => (d - m) * (d - m)));
    final mean = _mean(history);
    return mean == 0 ? 1 : sqrt(variance) / mean;
  }
}

// ---------- Clima ----------

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.tMax,
    required this.rain,
  });

  final DateTime date;
  final double tMax;

  /// mm no dia
  final double rain;

  Map<String, dynamic> toJson() =>
      {'date': date.toIso8601String(), 'tMax': tMax, 'rain': rain};

  factory DailyWeather.fromJson(Map<String, dynamic> j) => DailyWeather(
        date: DateTime.parse(j['date'] as String),
        tMax: (j['tMax'] as num).toDouble(),
        rain: (j['rain'] as num).toDouble(),
      );
}

// ---------- Alertas ----------

enum Level { watch, warning, critical }

extension LevelInfo on Level {
  String get label => switch (this) {
        Level.watch => 'Observação',
        Level.warning => 'Atenção',
        Level.critical => 'Crítico',
      };

  Color get color => switch (this) {
        Level.watch => AppColors.blue,
        Level.warning => AppColors.amber,
        Level.critical => AppColors.red,
      };

  IconData get icon => switch (this) {
        Level.watch => Icons.visibility_outlined,
        Level.warning => Icons.warning_amber_rounded,
        Level.critical => Icons.report_outlined,
      };
}

class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.summary,
    required this.level,
    required this.icon,
    required this.justification,
    required this.confidence,
    required this.confidenceNote,
    required this.limitations,
    required this.options,
    required this.highImpact,
  });

  final String id;
  final String title;
  final String summary;
  final Level level;
  final IconData icon;
  final List<String> justification;

  /// 0 a 1
  final double confidence;
  final String confidenceNote;
  final List<String> limitations;

  /// Respostas sugeridas ao gestor. O app nunca as executa.
  final List<String> options;

  /// Decisão que afeta diretamente a população (rodízio, alerta público…).
  final bool highImpact;
}

// ---------- Decisões ----------

enum Choice { adopt, monitor, dismiss }

extension ChoiceInfo on Choice {
  String get label => switch (this) {
        Choice.adopt => 'Adotar ação',
        Choice.monitor => 'Monitorar',
        Choice.dismiss => 'Descartar',
      };

  Color get color => switch (this) {
        Choice.adopt => AppColors.green,
        Choice.monitor => AppColors.blue,
        Choice.dismiss => AppColors.muted,
      };
}

/// Decisão registrada por um gestor humano.
class Decision {
  const Decision({
    required this.id,
    required this.alertId,
    required this.alertTitle,
    required this.regionName,
    required this.choice,
    required this.sector,
    required this.justification,
    required this.createdAt,
    this.option,
    this.deadlineDays,
  });

  final String id;
  final String alertId;
  final String alertTitle;
  final String regionName;
  final Choice choice;
  final String? option;

  /// Cargo ou setor — nunca o nome de uma pessoa.
  final String sector;
  final String justification;
  final int? deadlineDays;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'alertId': alertId,
        'alertTitle': alertTitle,
        'regionName': regionName,
        'choice': choice.name,
        'option': option,
        'sector': sector,
        'justification': justification,
        'deadlineDays': deadlineDays,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Decision.fromJson(Map<String, dynamic> j) => Decision(
        id: j['id'] as String,
        alertId: j['alertId'] as String,
        alertTitle: j['alertTitle'] as String,
        regionName: j['regionName'] as String,
        choice: Choice.values.byName(j['choice'] as String),
        option: j['option'] as String?,
        sector: j['sector'] as String,
        justification: j['justification'] as String,
        deadlineDays: j['deadlineDays'] as int?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
