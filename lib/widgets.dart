import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'utils.dart';

/// Cartão base do app.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? AppColors.border,
              width: borderColor == null ? 1 : 2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Título de seção (marcado como cabeçalho para leitores de tela).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
          ),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Etiqueta colorida com ícone (o texto garante que a cor não é a única pista).
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(140)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

/// Lista com marcadores dentro de uma caixa (justificativa, limitações…).
class BulletBox extends StatelessWidget {
  const BulletBox({
    super.key,
    required this.items,
    this.color = AppColors.primary,
  });

  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Icon(Icons.circle, size: 7, color: color),
                    ),
                  ),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 14.5, height: 1.35)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class EmptyMessage extends StatelessWidget {
  const EmptyMessage({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(icon, size: 48, color: AppColors.muted),
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 15)),
      ]),
    );
  }
}

/// Barra de confiança + rótulo em texto.
class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value >= 0.7
        ? AppColors.green
        : value >= 0.5
            ? AppColors.amber
            : AppColors.red;
    final label = 'Confiança ${confidenceLabel(value)} (${pct(value)})';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.border,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}

/// Cartão de indicador do painel.
class IndicatorTile extends StatelessWidget {
  const IndicatorTile({
    super.key,
    required this.indicator,
    this.selected = false,
    this.onTap,
  });

  final Indicator indicator;
  final bool selected;
  final VoidCallback? onTap;

  static Color colorFor(double usage) => usage >= 1
      ? AppColors.red
      : usage >= 0.9
          ? AppColors.amber
          : usage >= 0.8
              ? AppColors.blue
              : AppColors.green;

  @override
  Widget build(BuildContext context) {
    final t = indicator.type;
    final value = fmtValue(t, indicator.lastWeek);
    final color = colorFor(indicator.usage);
    return Semantics(
      button: true,
      selected: selected,
      label: '${t.label}: média de $value ${t.unit}, ${pct(indicator.usage)} da capacidade, '
          '${signedPct(indicator.weeklyChange)} na semana. Toque para ver o gráfico.',
      excludeSemantics: true,
      child: Panel(
        onTap: onTap,
        borderColor: selected ? AppColors.primary : null,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(t.icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text(t.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.text)),
            ]),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
            Text(t.unit,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: min(1.0, indicator.usage),
                minHeight: 6,
                color: color,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${pct(indicator.usage)} da capacidade\n${signedPct(indicator.weeklyChange)} na semana',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras: 14 dias de histórico + 7 projetados + linha de capacidade.
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.indicator, this.height = 150});

  final Indicator indicator;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = indicator.type;
    final past = indicator.history;
    final next = indicator.projectedDays;
    final all = [...past, ...next];
    final top = [...all, indicator.capacity].reduce(max) * 1.1;

    final summary =
        'Gráfico de ${t.label}. Últimos ${past.length} dias com média recente de ${fmtValue(t, indicator.lastWeek)} ${t.unit}. '
        'Projeção chega a ${fmtValue(t, next.last)} ${t.unit} em 7 dias. '
        'Capacidade: ${fmtValue(t, indicator.capacity)} ${t.unit}.';

    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: Column(children: [
        SizedBox(
          height: height,
          child: LayoutBuilder(builder: (context, c) {
            final capY = indicator.capacity / top * c.maxHeight;
            return Stack(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < all.length; i++)
                    Expanded(
                      child: Container(
                        height: all[i] / top * c.maxHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: i < past.length
                              ? AppColors.primary
                              : AppColors.amber,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: capY,
                child: Container(height: 2, color: AppColors.red),
              ),
            ]);
          }),
        ),
        const SizedBox(height: 6),
        const Row(children: [
          Text('há 14 dias', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          Spacer(),
          Text('hoje', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          Spacer(),
          Text('+7 dias', style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
        const SizedBox(height: 10),
        const Wrap(spacing: 14, runSpacing: 6, children: [
          _Legend(AppColors.primary, 'Histórico'),
          _Legend(AppColors.amber, 'Projeção'),
          _Legend(AppColors.red, 'Capacidade'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 14, height: 10, color: color),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text)),
    ]);
  }
}

/// Resumo de alerta em lista.
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, this.decision, this.onTap});

  final Alert alert;
  final Decision? decision;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alerta ${alert.level.label}: ${alert.title}. ${alert.summary} '
          'Confiança ${confidenceLabel(alert.confidence)}. '
          '${decision == null ? 'Sem decisão registrada.' : 'Decisão: ${decision!.choice.label}.'}',
      excludeSemantics: true,
      child: Panel(
        onTap: onTap,
        borderColor: alert.level.color.withAlpha(160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              Tag(alert.level.label,
                  color: alert.level.color, icon: alert.level.icon),
              if (alert.highImpact)
                const Tag('Alto impacto',
                    color: AppColors.red, icon: Icons.gavel_outlined),
              if (decision != null)
                Tag(decision!.choice.label,
                    color: decision!.choice.color, icon: Icons.check),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(alert.icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(alert.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(alert.summary, style: const TextStyle(color: AppColors.text)),
            const SizedBox(height: 10),
            ConfidenceBar(value: alert.confidence),
          ],
        ),
      ),
    );
  }
}

/// Cartão de decisão registrada.
class DecisionCard extends StatelessWidget {
  const DecisionCard({super.key, required this.decision, this.onDelete});

  final Decision decision;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final d = decision;
    return Panel(
      borderColor: d.choice.color.withAlpha(160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Tag(d.choice.label, color: d.choice.color, icon: Icons.check),
            const Spacer(),
            if (onDelete != null)
              IconButton(
                tooltip: 'Excluir registro',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.muted),
              ),
          ]),
          const SizedBox(height: 8),
          Text(d.alertTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.text)),
          Text(d.regionName,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          if (d.option != null) ...[
            const SizedBox(height: 8),
            Text('Ação: ${d.option}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.text)),
          ],
          const SizedBox(height: 6),
          Text(d.justification, style: const TextStyle(color: AppColors.text)),
          const SizedBox(height: 8),
          Text(
            '${d.sector} · ${fmtDateTime(d.createdAt)}'
            '${d.deadlineDays == null ? '' : ' · prazo: ${d.deadlineDays} dia(s)'}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Caixa de seleção obrigatória com validação de formulário.
class CheckboxField extends FormField<bool> {
  CheckboxField({
    super.key,
    required String label,
    required String errorMessage,
    Color color = AppColors.primary,
  }) : super(
          initialValue: false,
          validator: (v) => v == true ? null : errorMessage,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: field.value ?? false,
                onChanged: field.didChange,
                activeColor: color,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(label,
                    style: const TextStyle(color: AppColors.text, fontSize: 14.5)),
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 6),
                  child: Text(field.errorText!,
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 12.5)),
                ),
            ],
          ),
        );
}
