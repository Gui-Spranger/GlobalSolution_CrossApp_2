import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

/// Formulário em que o gestor registra a SUA decisão sobre um alerta.
class DecisionFormScreen extends StatefulWidget {
  const DecisionFormScreen({super.key, required this.alert});

  final Alert alert;

  @override
  State<DecisionFormScreen> createState() => _DecisionFormScreenState();
}

class _DecisionFormScreenState extends State<DecisionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sector = TextEditingController();
  final _reason = TextEditingController();
  Choice _choice = Choice.adopt;
  String? _option;
  int? _deadline;

  @override
  void dispose() {
    _sector.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Corrija os campos destacados para salvar.')));
      return;
    }
    final s = context.read<AppState>();
    final a = widget.alert;
    await s.addDecision(Decision(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      alertId: a.id,
      alertTitle: a.title,
      regionName: s.region.name,
      choice: _choice,
      option: _choice == Choice.adopt ? _option : null,
      sector: _sector.text.trim(),
      justification: _reason.text.trim(),
      deadlineDays: _choice == Choice.dismiss ? null : _deadline,
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Decisão registrada.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final highImpact = a.highImpact && _choice == Choice.adopt;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar decisão')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Panel(
              borderColor: a.level.color.withAlpha(160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tag(a.level.label, color: a.level.color, icon: a.level.icon),
                  const SizedBox(height: 8),
                  Text(a.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 8),
                  ConfidenceBar(value: a.confidence),
                ],
              ),
            ),

            const SectionTitle('1. Decisão'),
            SegmentedButton<Choice>(
              showSelectedIcon: false,
              segments: [
                for (final c in Choice.values)
                  ButtonSegment(value: c, label: Text(c.label)),
              ],
              selected: {_choice},
              onSelectionChanged: (v) => setState(() => _choice = v.first),
            ),

            if (_choice == Choice.adopt) ...[
              const SectionTitle('2. Ação escolhida'),
              DropdownButtonFormField<String>(
                value: _option,
                isExpanded: true,
                dropdownColor: AppColors.surfaceHigh,
                decoration: const InputDecoration(labelText: 'Ação'),
                items: [
                  for (final o in a.options)
                    DropdownMenuItem(
                        value: o,
                        child: Text(o, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _option = v),
                validator: (v) => v == null ? 'Escolha uma ação.' : null,
              ),
            ],

            const SectionTitle('Justificativa e responsável'),
            TextFormField(
              controller: _reason,
              minLines: 3,
              maxLines: 5,
              maxLength: 400,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Justificativa',
                helperText: 'Mínimo de 20 caracteres, sem dados pessoais.',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  Validators.text(v, field: 'A justificativa', min: 20),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sector,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cargo ou setor responsável',
                hintText: 'Ex.: Secretaria de Obras',
                helperText: 'Não use nomes de pessoas.',
              ),
              validator: (v) =>
                  Validators.text(v, field: 'O setor responsável', min: 3),
            ),
            if (_choice != Choice.dismiss) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _deadline,
                dropdownColor: AppColors.surfaceHigh,
                decoration: InputDecoration(
                  labelText: _choice == Choice.adopt
                      ? 'Prazo para executar'
                      : 'Reavaliar em',
                ),
                items: [
                  for (final d in const [1, 3, 7, 15, 30])
                    DropdownMenuItem(
                        value: d, child: Text(d == 1 ? '1 dia' : '$d dias')),
                ],
                onChanged: (v) => setState(() => _deadline = v),
                validator: (v) => v == null ? 'Escolha um prazo.' : null,
              ),
            ],

            const SectionTitle('Confirmação'),
            CheckboxField(
              label:
                  'Li a justificativa, a confiança e as limitações deste alerta.',
              errorMessage: 'Confirme que leu as limitações.',
            ),
            if (highImpact)
              CheckboxField(
                key: const ValueKey('high-impact'),
                color: AppColors.red,
                label:
                    'Sei que esta é uma decisão de alto impacto e que sua execução depende da validação da instância competente.',
                errorMessage: 'Confirmação obrigatória para alto impacto.',
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar decisão'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
