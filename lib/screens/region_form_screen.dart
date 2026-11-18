import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets.dart';

/// Formulário de cadastro de uma nova região monitorada.
class RegionFormScreen extends StatefulWidget {
  const RegionFormScreen({super.key});

  @override
  State<RegionFormScreen> createState() => _RegionFormScreenState();
}

class _RegionFormScreenState extends State<RegionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _population = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _population.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final error = Validators.text(v, field: 'O nome', min: 3);
    if (error != null) return error;
    final name = v!.trim().toLowerCase();
    final exists = context
        .read<AppState>()
        .regions
        .any((r) => r.name.toLowerCase() == name);
    return exists ? 'Já existe uma região com esse nome.' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Corrija os campos destacados para salvar.')));
      return;
    }
    final region = Region(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      population: int.parse(_population.text.trim()),
      lat: Validators.parseDecimal(_lat.text)!,
      lon: Validators.parseDecimal(_lon.text)!,
    );
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
        SnackBar(content: Text('Região "${region.name}" cadastrada.')));
    await state.addRegion(region);
  }

  @override
  Widget build(BuildContext context) {
    final coordinateInput = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\-]')),
    ];
    const coordinateKeyboard =
        TextInputType.numberWithOptions(signed: true, decimal: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova região')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const SectionTitle('Identificação'),
            TextFormField(
              controller: _name,
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da região',
                hintText: 'Ex.: Vila Nova — Campinas/SP',
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _population,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'População (habitantes)',
                helperText: 'Total da região. Fonte sugerida: IBGE.',
              ),
              validator: (v) => Validators.integer(v, field: 'A população'),
            ),
            const SectionTitle('Localização do centro da região',
                subtitle:
                    'Usada só para buscar o clima. É enviada arredondada (~1 km).'),
            TextFormField(
              controller: _lat,
              keyboardType: coordinateKeyboard,
              inputFormatters: coordinateInput,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'Ex.: -22,90',
                helperText: 'Entre -90 e 90',
              ),
              validator: (v) =>
                  Validators.decimal(v, field: 'A latitude', min: -90, max: 90),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lon,
              keyboardType: coordinateKeyboard,
              inputFormatters: coordinateInput,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'Ex.: -47,06',
                helperText: 'Entre -180 e 180',
              ),
              validator: (v) => Validators.decimal(v,
                  field: 'A longitude', min: -180, max: 180),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Cadastrar região'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
