import 'package:flutter/material.dart';

import '../../data/repositorio.dart';
import '../../models/veiculo.dart';
import '../../services/brasil_api_service.dart';

/// Tela para visualização, cadastro e exclusão do veículo único
class TelaVeiculo extends StatefulWidget {
  const TelaVeiculo({super.key});

  @override
  State<TelaVeiculo> createState() => _TelaVeiculoState();
}

class _TelaVeiculoState extends State<TelaVeiculo> {
  final _repositorio = Repositorio();
  final _brasilApiService = BrasilApiService();
  final _formKey = GlobalKey<FormState>();

  bool _carregando = true;
  Veiculo? _veiculoAtual;

  // Estados do formulário (usando as classes do brasil_api_service.dart)
  List<MarcaFipe> _marcas = [];
  List<ModeloFipe> _modelos = [];
  MarcaFipe? _marcaSelecionada;
  ModeloFipe? _modeloSelecionado;
  bool _carregandoMarcas = false;
  bool _carregandoModelos = false;

  final TextEditingController _anoController = TextEditingController();
  final TextEditingController _cilindradaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _anoController.dispose();
    _cilindradaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _carregando = true);
    final veiculo = await _repositorio.obterVeiculoAtual();

    if (veiculo == null) {
      await _carregarMarcas();
    }

    if (mounted) {
      setState(() {
        _veiculoAtual = veiculo;
        _carregando = false;
      });
    }
  }

  Future<void> _carregarMarcas() async {
    setState(() => _carregandoMarcas = true);
    try {
      final marcas = await _brasilApiService.buscarMarcas();
      if (mounted) {
        setState(() {
          _marcas = marcas;
          _carregandoMarcas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoMarcas = false);
      }
    }
  }

  Future<void> _aoMudarMarca(MarcaFipe? novaMarca) async {
    if (novaMarca == null) return;
    setState(() {
      _marcaSelecionada = novaMarca;
      _modeloSelecionado = null;
      _modelos = [];
      _carregandoModelos = true;
    });

    try {
      final modelos = await _brasilApiService.buscarModelos(novaMarca.codigo);
      if (mounted) {
        setState(() {
          _modelos = modelos;
          _carregandoModelos = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoModelos = false);
      }
    }
  }

  Future<void> _salvarVeiculo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_marcaSelecionada == null || _modeloSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione a Marca e o Modelo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final novoVeiculo = Veiculo(
      marca: _marcaSelecionada!.nome,
      modelo: _modeloSelecionado!.nome,
      ano: int.parse(_anoController.text.trim()),
      cilindrada: _cilindradaController.text.trim(),
    );

    await _repositorio.inserirVeiculo(novoVeiculo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veículo cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _carregarDadosIniciais();
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: const Text(
          'A exclusão do veículo removerá permanentemente o veículo atual e TODOS os abastecimentos associados a ele.\n\nDeseja realmente continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir Tudo'),
          ),
        ],
      ),
    );

    if (confirmar == true && _veiculoAtual?.id != null) {
      await _repositorio.excluirVeiculo(_veiculoAtual!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veículo e abastecimentos excluídos com sucesso.'),
          ),
        );
        _carregarDadosIniciais();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Veículo')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _veiculoAtual != null
          ? _buildVisualizacaoVeiculo(_veiculoAtual!)
          : _buildFormularioCadastro(),
    );
  }

  Widget _buildVisualizacaoVeiculo(Veiculo veiculo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Icon(
                          Icons.directions_car,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              veiculo.marca,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                            Text(
                              veiculo.modelo,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        'Ano',
                        veiculo.ano.toString(),
                        Icons.calendar_today,
                      ),
                      _buildInfoItem(
                        'Cilindrada',
                        veiculo.cilindrada.isNotEmpty
                            ? veiculo.cilindrada
                            : 'N/A',
                        Icons.speed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.amber.shade300),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'O aplicativo permite apenas 1 veículo por vez. Para cadastrar um novo veículo, é necessário excluir o atual.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _confirmarExclusao,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text(
              'Excluir Veículo Atual',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, size: 22, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFormularioCadastro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cadastrar Veículo',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'As opções de marca e modelo são carregadas em tempo real da BrasilAPI.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Dropdown de Marcas
            _carregandoMarcas
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<MarcaFipe>(
                    decoration: const InputDecoration(
                      labelText: 'Marca do Veículo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    initialValue: _marcaSelecionada,
                    isExpanded: true,
                    hint: const Text('Selecione a Marca'),
                    items: _marcas.map((m) {
                      return DropdownMenuItem<MarcaFipe>(
                        value: m,
                        child: Text(m.nome),
                      );
                    }).toList(),
                    onChanged: _aoMudarMarca,
                    validator: (val) =>
                        val == null ? 'Campo obrigatório' : null,
                  ),
            const SizedBox(height: 16),

            // Dropdown de Modelos
            _carregandoModelos
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Buscando modelos na BrasilAPI...'),
                        ],
                      ),
                    ),
                  )
                : DropdownButtonFormField<ModeloFipe>(
                    decoration: const InputDecoration(
                      labelText: 'Modelo do Veículo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car_filled),
                    ),
                    initialValue: _modeloSelecionado,
                    isExpanded: true,
                    hint: Text(
                      _marcaSelecionada == null
                          ? 'Selecione a marca primeiro'
                          : (_modelos.isEmpty
                                ? 'Nenhum modelo encontrado'
                                : 'Selecione o Modelo'),
                    ),
                    items: _modelos.map((mod) {
                      return DropdownMenuItem<ModeloFipe>(
                        value: mod,
                        child: Text(mod.nome, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (_marcaSelecionada == null || _modelos.isEmpty)
                        ? null
                        : (val) => setState(() => _modeloSelecionado = val),
                    validator: (val) =>
                        val == null ? 'Campo obrigatório' : null,
                  ),
            const SizedBox(height: 16),

            // Campo Ano
            TextFormField(
              controller: _anoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ano de Fabricação / Modelo',
                hintText: 'Ex: 2022',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe o ano do veículo';
                }
                final ano = int.tryParse(val.trim());
                if (ano == null || ano < 1900 || ano > 2100) {
                  return 'Informe um ano válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo Cilindrada
            TextFormField(
              controller: _cilindradaController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Cilindrada do Motor',
                hintText: 'Ex: 1.0, 1.6 Turbo, 2.0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe a cilindrada do motor';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _salvarVeiculo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.save),
              label: const Text(
                'Cadastrar Veículo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
