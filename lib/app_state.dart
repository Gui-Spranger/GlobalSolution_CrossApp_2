import 'package:flutter/foundation.dart';

import 'models.dart';
import 'services.dart';

/// Estado global do app (Provider + ChangeNotifier).
class AppState extends ChangeNotifier {
  AppState(this._storage, this._api);

  final Storage _storage;
  final WeatherApi _api;

  Region region = kRegions.first;
  List<Region> customRegions = [];
  double textScale = 1.0;
  List<DailyWeather> forecast = [];
  List<Indicator> indicators = [];
  List<Alert> alerts = [];
  List<Decision> decisions = []; // mais recente primeiro
  DataSource source = DataSource.loading;
  DateTime? updatedAt;
  bool loading = false;

  /// Regiões de exemplo + regiões cadastradas pelo gestor.
  List<Region> get regions => [...kRegions, ...customRegions];

  Future<void> init() async {
    customRegions = _storage.loadCustomRegions();
    textScale = _storage.textScale;
    final savedId = _storage.regionId;
    region = regions.firstWhere((r) => r.id == savedId,
        orElse: () => kRegions.first);
    decisions = _storage.loadDecisions();
    notifyListeners();
    await load();
  }

  /// Clima: API → cache → simulado. Depois gera indicadores e alertas.
  Future<void> load() async {
    final r = region;
    loading = true;
    notifyListeners();

    List<DailyWeather> days;
    DataSource src;
    DateTime? when;
    try {
      days = await _api.fetch(r);
      src = DataSource.live;
      when = DateTime.now();
      await _storage.saveWeather(r.id, days);
    } catch (_) {
      final cached = _storage.loadWeather(r.id);
      if (cached != null) {
        days = cached.days;
        when = cached.savedAt;
        src = DataSource.cache;
      } else {
        days = simulatedWeather(r);
        src = DataSource.simulated;
      }
    }
    if (r.id != region.id) return; // a região mudou durante a busca

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var past = days.where((d) => d.date.isBefore(today)).toList();
    if (past.length < 8) {
      days = simulatedWeather(r);
      src = DataSource.simulated;
      past = days.where((d) => d.date.isBefore(today)).toList();
    }
    if (past.length > 14) past = past.sublist(past.length - 14);

    forecast = days.where((d) => !d.date.isBefore(today)).take(7).toList();
    indicators = buildIndicators(r, past);
    alerts = buildAlerts(
      region: r,
      indicators: indicators,
      forecast: forecast,
      source: src,
    );
    source = src;
    updatedAt = when;
    loading = false;
    notifyListeners();
  }

  Future<void> selectRegion(Region r) async {
    if (r.id == region.id) return;
    region = r;
    indicators = [];
    alerts = [];
    forecast = [];
    source = DataSource.loading;
    await _storage.saveRegionId(r.id);
    await load();
  }

  Future<void> addRegion(Region r) async {
    customRegions = [...customRegions, r];
    await _storage.saveCustomRegions(customRegions);
    await selectRegion(r);
  }

  Future<void> setTextScale(double value) async {
    textScale = value;
    notifyListeners();
    await _storage.saveTextScale(value);
  }

  Alert? alertById(String id) {
    for (final a in alerts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Decision? decisionFor(String alertId) {
    for (final d in decisions) {
      if (d.alertId == alertId) return d;
    }
    return null;
  }

  /// Alertas de atenção ou críticos ainda sem decisão.
  int get pendingCount => alerts
      .where((a) => a.level != Level.watch && decisionFor(a.id) == null)
      .length;

  Future<void> addDecision(Decision d) async {
    decisions = [d, ...decisions];
    await _storage.saveDecisions(decisions);
    notifyListeners();
  }

  Future<void> removeDecision(String id) async {
    decisions = decisions.where((d) => d.id != id).toList();
    await _storage.saveDecisions(decisions);
    notifyListeners();
  }

  /// Apaga tudo o que o app guardou no aparelho.
  Future<void> clearData() async {
    await _storage.clear();
    decisions = [];
    customRegions = [];
    textScale = 1.0;
    region = kRegions.first;
    await load();
  }
}
