import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositorio.dart';
import '../../models/abastecimento.dart';
import '../../models/veiculo.dart';

/// Tela para inclusão de novos abastecimentos
class TelaAbastecimento extends StatefulWidget {
  const TelaAbastecimento({super.key});

  @override
  State<TelaAbastecimento> createState() => _TelaAbastecimentoState();
}

class _TelaAbastecimentoState extends State<TelaAbastecimento> {
  final _formKey = GlobalKey<FormState>();
  final _repositorio = Repositorio();
  final _moedaFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool _carregando = true;
  Veiculo? _veiculoAtual;
  Abastecimento? _ultimoAbastecimento;

  // Campos do formulário
  String _tipoCombustivel = 'Gasolina';
  final List<String> _opcoesCombustivel = ['Gasolina', 'Etanol', 'Diesel'];

  final TextEditingController _precoLitroController = TextEditingController();
  final TextEditingController _quilometragemController =
      TextEditingController();
  final TextEditingController _litrosController = TextEditingController();
  DateTime _dataHoraSelecionada = DateTime.now();

  double _valorTotalCalculado = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarVeiculoEUltimoAbastecimento();
  }

  @override
  void dispose() {
    _precoLitroController.dispose();
    _quilometragemController.dispose();
    _litrosController.dispose();
    super.dispose();
  }

  Future<void> _carregarVeiculoEUltimoAbastecimento() async {
    setState(() => _carregando = true);
    final veiculo = await _repositorio.obterVeiculoAtual();
    Abastecimento? ultimo;
    if (veiculo?.id != null) {
      ultimo = await _repositorio.obterUltimoAbastecimento(veiculo!.id!);
    }

    if (mounted) {
      setState(() {
        _veiculoAtual = veiculo;
        _ultimoAbastecimento = ultimo;
        _carregando = false;
      });
    }
  }

  void _atualizarValorTotal() {
    final preco =
        double.tryParse(_precoLitroController.text.replaceAll(',', '.')) ?? 0.0;
    final litros =
        double.tryParse(_litrosController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _valorTotalCalculado = preco * litros;
    });
  }

  Future<void> _selecionarDataHora() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataHoraSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dataEscolhida == null || !mounted) return;

    final horaEscolhida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHoraSelecionada),
    );
    if (horaEscolhida == null || !mounted) return;

    setState(() {
      _dataHoraSelecionada = DateTime(
        dataEscolhida.year,
        dataEscolhida.month,
        dataEscolhida.day,
        horaEscolhida.hour,
        horaEscolhida.minute,
      );
    });
  }

  Future<void> _salvarAbastecimento() async {
    if (_veiculoAtual == null || _veiculoAtual!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhum veículo cadastrado. Cadastre um veículo primeiro!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final preco = double.parse(_precoLitroController.text.replaceAll(',', '.'));
    final km = double.parse(_quilometragemController.text.replaceAll(',', '.'));
    final litros = double.parse(_litrosController.text.replaceAll(',', '.'));
    final total = preco * litros;

    if (_ultimoAbastecimento != null &&
        km <= _ultimoAbastecimento!.quilometragem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A quilometragem deve ser maior que a do último abastecimento (${_ultimoAbastecimento!.quilometragem.toStringAsFixed(0)} KM).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // Bloqueia a gravação para manter a consistência matemática
    }

    final novoAbastecimento = Abastecimento(
      veiculoId: _veiculoAtual!.id!,
      tipoCombustivel: _tipoCombustivel,
      precoLitro: preco,
      quilometragem: km,
      litros: litros,
      dataHora: _dataHoraSelecionada,
      valorTotal: total,
    );

    await _repositorio.inserirAbastecimento(novoAbastecimento);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abastecimento registrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Novo Abastecimento')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_veiculoAtual == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Novo Abastecimento')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.car_crash_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum veículo cadastrado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cadastre um veículo antes de registrar abastecimentos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Abastecimento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identificação do veículo
              Card(
                color: Theme.of(context).colorScheme.primaryContainer
                    .withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_veiculoAtual!.marca} ${_veiculoAtual!.modelo} (${_veiculoAtual!.ano})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de Combustível
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Combustível',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                initialValue: _tipoCombustivel,
                items: _opcoesCombustivel.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _tipoCombustivel = val);
                },
              ),
              const SizedBox(height: 16),

              // Preço por litro
              TextFormField(
                controller: _precoLitroController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço por Litro (R\$)',
                  hintText: 'Ex: 5.89',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (_) => _atualizarValorTotal(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o preço por litro';
                  }
                  final valor = double.tryParse(val.replaceAll(',', '.'));
                  if (valor == null || valor <= 0) {
                    return 'Informe um preço válido maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantidade de Litros
              TextFormField(
                controller: _litrosController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantidade de Litros',
                  hintText: 'Ex: 40.5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.opacity),
                ),
                onChanged: (_) => _atualizarValorTotal(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe a quantidade de litros';
                  }
                  final valor = double.tryParse(val.replaceAll(',', '.'));
                  if (valor == null || valor <= 0) {
                    return 'Informe uma quantidade válida maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quilometragem
              TextFormField(
                controller: _quilometragemController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quilometragem Atual (KM)',
                  hintText: _ultimoAbastecimento != null
                      ? 'Último: ${_ultimoAbastecimento!.quilometragem.toStringAsFixed(0)} km'
                      : 'Ex: 45200',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.speed),
                  helperText: _ultimoAbastecimento != null
                      ? 'Último abastecimento em: ${_ultimoAbastecimento!.quilometragem.toStringAsFixed(1)} km'
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe a quilometragem atual';
                  }
                  final valor = double.tryParse(val.replaceAll(',', '.'));
                  if (valor == null || valor < 0) {
                    return 'Informe uma quilometragem válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Seletor de Data e Horário
              InkWell(
                onTap: _selecionarDataHora,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data e Hora do Abastecimento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(_dateFormat.format(_dataHoraSelecionada)),
                ),
              ),
              const SizedBox(height: 20),

              // Card do Valor Total Calculado
              Card(
                elevation: 0,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Valor Total Calculado:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _moedaFormat.format(_valorTotalCalculado),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _salvarAbastecimento,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Salvar Abastecimento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
