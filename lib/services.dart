import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'utils.dart';

// =====================================================================
// API de clima — Open-Meteo (pública, gratuita, sem chave)
// =====================================================================

class WeatherApi {
  WeatherApi([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  /// 14 dias de histórico + 7 dias de previsão.
  Future<List<DailyWeather>> fetch(Region region) async {
    // Privacidade: só o centro da região, com 2 casas decimais (~1 km).
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': region.lat.toStringAsFixed(2),
      'longitude': region.lon.toStringAsFixed(2),
      'daily': 'temperature_2m_max,precipitation_sum',
      'past_days': '14',
      'forecast_days': '7',
      'timezone': 'auto',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('API de clima respondeu ${res.statusCode}');
    }
    final daily = (jsonDecode(res.body) as Map<String, dynamic>)['daily']
        as Map<String, dynamic>;
    final times = (daily['time'] as List).cast<String>();
    final tMax = daily['temperature_2m_max'] as List;
    final rain = daily['precipitation_sum'] as List;
    return [
      for (var i = 0; i < times.length; i++)
        DailyWeather(
          date: DateTime.parse(times[i]),
          tMax: (tMax[i] as num?)?.toDouble() ?? 25,
          rain: (rain[i] as num?)?.toDouble() ?? 0,
        ),
    ];
  }
}

// =====================================================================
// Persistência local (SharedPreferences) — nada sai do aparelho
// =====================================================================

typedef CachedWeather = ({DateTime savedAt, List<DailyWeather> days});

class Storage {
  Storage(this._prefs);

  static Future<Storage> open() async =>
      Storage(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  String? get regionId => _prefs.getString('region');

  Future<void> saveRegionId(String id) => _prefs.setString('region', id);

  List<Region> loadCustomRegions() {
    final raw = _prefs.getString('regions');
    if (raw == null) return [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          Region.fromJson(e as Map<String, dynamic>)
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomRegions(List<Region> list) => _prefs.setString(
      'regions', jsonEncode([for (final r in list) r.toJson()]));

  double get textScale => _prefs.getDouble('textScale') ?? 1.0;

  Future<void> saveTextScale(double value) =>
      _prefs.setDouble('textScale', value);

  List<Decision> loadDecisions() {
    final raw = _prefs.getString('decisions');
    if (raw == null) return [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          Decision.fromJson(e as Map<String, dynamic>)
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDecisions(List<Decision> list) => _prefs.setString(
      'decisions', jsonEncode([for (final d in list) d.toJson()]));

  CachedWeather? loadWeather(String regionId) {
    final raw = _prefs.getString('weather_$regionId');
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (
        savedAt: DateTime.parse(j['savedAt'] as String),
        days: [
          for (final d in j['days'] as List)
            DailyWeather.fromJson(d as Map<String, dynamic>)
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWeather(String regionId, List<DailyWeather> days) =>
      _prefs.setString(
          'weather_$regionId',
          jsonEncode({
            'savedAt': DateTime.now().toIso8601String(),
            'days': [for (final d in days) d.toJson()],
          }));

  Future<void> clear() => _prefs.clear();
}

// =====================================================================
// Dados sintéticos de consumo e demanda
// =====================================================================

enum DataSource { loading, live, cache, simulated }

int _seed(String s) => s.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff);

/// Clima inventado, usado só se não houver internet nem cache.
List<DailyWeather> simulatedWeather(Region region) {
  final rnd = Random(_seed(region.id));
  final now = DateTime.now();
  final start =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 14));
  return [
    for (var i = 0; i < 21; i++)
      DailyWeather(
        date: start.add(Duration(days: i)),
        tMax: 24 + rnd.nextDouble() * 4,
        rain: rnd.nextDouble() < 0.25 ? rnd.nextDouble() * 15 : 0,
      ),
  ];
}

/// Gera 14 dias de consumo/demanda a partir da população e do clima real.
/// Determinístico: a mesma região gera sempre a mesma tendência.
List<Indicator> buildIndicators(Region region, List<DailyWeather> past) {
  final rnd = Random(_seed(region.id));
  return [
    for (final type in IndicatorType.values) _indicator(type, region, past, rnd)
  ];
}

Indicator _indicator(
    IndicatorType type, Region region, List<DailyWeather> past, Random rnd) {
  final base = region.population * type.perCapita;
  final trend = rnd.nextDouble() * 0.016; // até +1,6% ao dia
  final values = <double>[];
  for (var i = 0; i < past.length; i++) {
    final w = past[i];
    final double climate = switch (type) {
      IndicatorType.water => 1 + 0.02 * (w.tMax - 25),
      IndicatorType.energy => 1 + 0.025 * max(0.0, w.tMax - 25),
      IndicatorType.waste => 1.0,
      IndicatorType.services => 1 + w.rain / 40,
    };
    final noise = 0.97 + rnd.nextDouble() * 0.06;
    values.add(base * climate * (1 + trend * i) * noise);
  }
  return Indicator(type: type, history: values, capacity: base * 1.3);
}

// =====================================================================
// Alertas preditivos
// =====================================================================

const kLimitations = [
  'Consumo, resíduos e chamados são dados simulados, calibrados pela população e pelo clima real. Não são medições oficiais.',
  'A projeção supõe que a tendência da última semana continua. Feriados, obras ou falhas na rede não são previstos.',
  'Quanto mais distante o dia, maior a incerteza.',
];

const _options = {
  IndicatorType.water: [
    'Campanha de uso consciente de água',
    'Vistoria de vazamentos na rede',
    'Rodízio de abastecimento',
  ],
  IndicatorType.energy: [
    'Pedir reforço de monitoramento à concessionária',
    'Reduzir consumo de prédios públicos no horário de pico',
    'Priorizar energia para unidades de saúde',
  ],
  IndicatorType.waste: [
    'Remanejar rotas de coleta',
    'Programar coleta extra nos pontos críticos',
  ],
  IndicatorType.services: [
    'Reforçar equipes de atendimento',
    'Triagem dos chamados por gravidade',
  ],
};

List<Alert> buildAlerts({
  required Region region,
  required List<Indicator> indicators,
  required List<DailyWeather> forecast,
  required DataSource source,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final day = dayKey(today);
  final offline = source != DataSource.live;
  final sourceNote = switch (source) {
    DataSource.cache => ['Sem internet: clima da última consulta salva.'],
    DataSource.simulated => [
        'Sem internet e sem dados salvos: o clima também foi simulado.'
      ],
    _ => <String>[],
  };
  final hotDays = forecast.where((d) => d.tMax >= 30).length;
  final rainyDays = forecast.where((d) => d.rain >= 20).length;
  final alerts = <Alert>[];

  // ---- Indicadores: projeção x capacidade ----
  for (final ind in indicators) {
    final p = ind.projectedUsage;
    final level = p >= 1
        ? Level.critical
        : p >= 0.9
            ? Level.warning
            : p >= 0.8
                ? Level.watch
                : null;
    if (level == null) continue;
    final t = ind.type;
    String v(double x) => '${fmtValue(t, x)} ${t.unit}';

    alerts.add(Alert(
      id: '${region.id}-${t.name}-$day',
      icon: t.icon,
      level: level,
      title: switch (level) {
        Level.critical => '${t.label}: pode passar da capacidade',
        Level.warning => '${t.label}: perto do limite',
        Level.watch => '${t.label}: uso em alta',
      },
      summary: 'Projeção de ${pct(p)} da capacidade na próxima semana.',
      justification: [
        'Média dos últimos 7 dias: ${v(ind.lastWeek)} (${pct(ind.usage)} da capacidade de ${v(ind.capacity)}).',
        'Variação em relação à semana anterior: ${signedPct(ind.weeklyChange)}.',
        'Se a tendência continuar, a média da próxima semana fica em ${v(ind.projection)}.',
        if ((t == IndicatorType.water || t == IndicatorType.energy) &&
            hotDays >= 2)
          'A previsão tem $hotDays dias com máxima de 30 °C ou mais, o que aumenta o consumo.',
        if (t == IndicatorType.services && rainyDays >= 1)
          'A previsão tem $rainyDays dia(s) com 20 mm de chuva ou mais, o que costuma aumentar os chamados.',
      ],
      confidence:
          (0.9 - ind.noise * 5 - (offline ? 0.15 : 0)).clamp(0.3, 0.9).toDouble(),
      confidenceNote: 'Calculada pela estabilidade dos dados dos últimos 14 dias'
          '${offline ? ', com desconto por falta de clima atualizado' : ''}.',
      limitations: [...kLimitations, ...sourceNote],
      options: _options[t]!,
      highImpact: level == Level.critical &&
          (t == IndicatorType.water || t == IndicatorType.energy),
    ));
  }

  // ---- Clima: só com previsão real (ao vivo ou salva) ----
  if (source != DataSource.simulated && forecast.isNotEmpty) {
    final weatherLimits = [
      'Previsão do Open-Meteo para o ponto central da região; a chuva pode variar muito entre bairros.',
      'A previsão perde precisão a cada dia de antecedência.',
      ...sourceNote,
    ];
    double conf(DateTime d) {
      final ahead = d.difference(today).inDays.clamp(0, 7);
      return (0.85 - 0.06 * ahead - (offline ? 0.15 : 0))
          .clamp(0.3, 0.9)
          .toDouble();
    }

    final wettest = forecast.reduce((a, b) => a.rain >= b.rain ? a : b);
    if (wettest.rain >= 30) {
      final critical = wettest.rain >= 50;
      alerts.add(Alert(
        id: '${region.id}-rain-$day',
        icon: Icons.thunderstorm_outlined,
        level: critical ? Level.critical : Level.warning,
        title: critical ? 'Chuva muito forte: risco de alagamento' : 'Chuva forte prevista',
        summary:
            '${fmtNum(wettest.rain, 1)} mm previstos para ${weekday(wettest.date)}, ${fmtDate(wettest.date)}.',
        justification: [
          'Previsão de ${fmtNum(wettest.rain, 1)} mm em um dia (atenção a partir de 30 mm; crítico a partir de 50 mm).',
          'Chuva intensa sobrecarrega bueiros e galerias e aumenta os chamados.',
        ],
        confidence: conf(wettest.date),
        confidenceNote: 'Cai conforme a antecedência da previsão.',
        limitations: weatherLimits,
        options: const [
          'Limpeza preventiva de bueiros e galerias',
          'Defesa Civil em prontidão',
          'Alerta à população das áreas de risco',
        ],
        highImpact: critical,
      ));
    }

    final hot = forecast.where((d) => d.tMax >= 32).toList();
    if (hot.length >= 3) {
      final peak = hot.map((d) => d.tMax).reduce(max);
      alerts.add(Alert(
        id: '${region.id}-heat-$day',
        icon: Icons.thermostat_outlined,
        level: peak >= 35 ? Level.critical : Level.warning,
        title: 'Calor intenso previsto',
        summary:
            '${hot.length} dias com máxima de 32 °C ou mais nos próximos 7 dias.',
        justification: [
          '${hot.length} dias com máxima de 32 °C ou mais; pico de ${fmtNum(peak, 1)} °C.',
          'Calor prolongado aumenta riscos à saúde de idosos e crianças e o consumo de água e energia.',
        ],
        confidence: conf(hot.first.date),
        confidenceNote: 'Cai conforme a antecedência da previsão.',
        limitations: weatherLimits,
        options: const [
          'Pontos de hidratação em locais públicos',
          'Avisar as unidades de saúde',
          'Alerta de saúde à população',
        ],
        highImpact: false,
      ));
    }
  }

  alerts.sort((a, b) => b.level.index.compareTo(a.level.index));
  return alerts;
}
