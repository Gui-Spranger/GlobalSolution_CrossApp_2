import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorial/models.dart';
import 'package:radar_territorial/services.dart';
import 'package:radar_territorial/utils.dart';

void main() {
  final region = kRegions.first;
  final today = DateTime(2026, 11, 16);

  Indicator water(double start, double dailyGrowth) {
    final cap = region.population * IndicatorType.water.perCapita * 1.3;
    return Indicator(
      type: IndicatorType.water,
      capacity: cap,
      history: [for (var i = 0; i < 14; i++) cap * start * (1 + dailyGrowth * i)],
    );
  }

  List<DailyWeather> forecast({double rain = 0, double tMax = 26}) => [
        for (var i = 0; i < 7; i++)
          DailyWeather(
              date: today.add(Duration(days: i)),
              tMax: tMax,
              rain: i == 2 ? rain : 0),
      ];

  test('projeção segue a tendência da última semana', () {
    final ind = water(0.5, 0.01);
    expect(ind.weeklyChange, greaterThan(0));
    expect(ind.projection, greaterThan(ind.lastWeek));
    expect(ind.projectedDays, hasLength(7));
  });

  test('uso projetado acima da capacidade gera alerta crítico completo', () {
    final alerts = buildAlerts(
      region: region,
      indicators: [water(0.8, 0.015)],
      forecast: forecast(),
      source: DataSource.live,
      now: today,
    );
    final a = alerts.single;
    expect(a.level, Level.critical);
    expect(a.highImpact, isTrue);
    expect(a.justification, isNotEmpty);
    expect(a.limitations, isNotEmpty);
    expect(a.confidence, inInclusiveRange(0.3, 0.9));
  });

  test('uso baixo não gera alerta', () {
    final alerts = buildAlerts(
      region: region,
      indicators: [water(0.4, 0)],
      forecast: forecast(),
      source: DataSource.live,
      now: today,
    );
    expect(alerts, isEmpty);
  });

  test('chuva forte e calor geram alertas; clima simulado não', () {
    final real = buildAlerts(
        region: region,
        indicators: const [],
        forecast: forecast(rain: 60, tMax: 36),
        source: DataSource.live,
        now: today);
    expect(real, hasLength(2));
    final fake = buildAlerts(
        region: region,
        indicators: const [],
        forecast: forecast(rain: 60, tMax: 36),
        source: DataSource.simulated,
        now: today);
    expect(fake, isEmpty);
  });

  test('validação recusa texto curto e dados pessoais', () {
    expect(Validators.text('', field: 'X'), isNotNull);
    expect(Validators.text('curto', field: 'X', min: 20), isNotNull);
    expect(Validators.text('CPF 123.456.789-09 do morador', field: 'X'), isNotNull);
    expect(Validators.text('contato@prefeitura.gov.br', field: 'X'), isNotNull);
    expect(Validators.text('Secretaria de Obras', field: 'X', min: 3), isNull);
  });

  test('validação do cadastro de região', () {
    expect(Validators.integer('3200', field: 'X'), isNull);
    expect(Validators.integer('0', field: 'X'), isNotNull);
    expect(Validators.integer('', field: 'X'), isNotNull);
    expect(Validators.decimal('-23,55', field: 'X', min: -90, max: 90), isNull);
    expect(Validators.decimal('95', field: 'X', min: -90, max: 90), isNotNull);
    expect(Validators.decimal('abc', field: 'X', min: -90, max: 90), isNotNull);
    expect(Validators.parseDecimal('-46,63'), closeTo(-46.63, 1e-9));
  });

  test('região é salva e lida em JSON', () {
    final copy = Region.fromJson(region.toJson());
    expect(copy.id, region.id);
    expect(copy.population, region.population);
    expect(copy.lat, region.lat);
  });

  test('formatação pt-BR e supressão de pequenas contagens', () {
    expect(fmtNum(1234567), '1.234.567');
    expect(fmtNum(12.5, 1), '12,5');
    expect(fmtValue(IndicatorType.services, 3), '<5');
  });
}
