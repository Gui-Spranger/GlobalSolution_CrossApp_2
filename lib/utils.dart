import 'models.dart';

// ---------- Formatação (pt-BR) ----------

String fmtNum(double v, [int decimals = 0]) {
  final parts = v.toStringAsFixed(decimals).split('.');
  final intPart = parts[0]
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
}

String pct(double ratio) => '${(ratio * 100).round()}%';

String signedPct(double ratio) =>
    '${ratio >= 0 ? '+' : '−'}${fmtNum((ratio * 100).abs(), 1)}%';

String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} às ${two(d.hour)}:${two(d.minute)}';

String weekday(DateTime d) =>
    const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][d.weekday - 1];

String dayKey(DateTime d) => '${d.year}${two(d.month)}${two(d.day)}';

/// Contagens de pessoas abaixo de 5 viram "<5" (evita reidentificação).
String fmtValue(IndicatorType type, double v) {
  if (type == IndicatorType.services && v < 5) return '<5';
  return fmtNum(v, type.decimals);
}

String confidenceLabel(double c) =>
    c >= 0.7 ? 'Alta' : (c >= 0.5 ? 'Média' : 'Baixa');

// ---------- Validação de formulários ----------

class Validators {
  Validators._();

  static final _cpf = RegExp(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}');
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final _phone = RegExp(r'\(?\d{2}\)?\s?9?\d{4}-?\d{4}');

  /// Aceita "-23,55" ou "-23.55".
  static double? parseDecimal(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  static String? integer(String? value,
      {required String field, int min = 1, int max = 50000000}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field é obrigatório.';
    final n = int.tryParse(v);
    if (n == null) return 'Digite só números.';
    if (n < min || n > max) return '$field deve estar entre $min e $max.';
    return null;
  }

  static String? decimal(String? value,
      {required String field, required double min, required double max}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field é obrigatória.';
    final n = parseDecimal(v);
    if (n == null) return 'Número inválido. Exemplo: -23,55';
    if (n < min || n > max) return '$field deve estar entre $min e $max.';
    return null;
  }

  /// Campo de texto obrigatório, com tamanho mínimo e sem dados pessoais.
  static String? text(String? value, {required String field, int min = 1}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field é obrigatório.';
    if (v.length < min) return '$field precisa ter pelo menos $min caracteres.';
    if (_cpf.hasMatch(v) || _email.hasMatch(v) || _phone.hasMatch(v)) {
      return 'Não inclua dados pessoais (CPF, e-mail ou telefone).';
    }
    return null;
  }
}
