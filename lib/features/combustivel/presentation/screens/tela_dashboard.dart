import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositorio.dart';
import '../../models/abastecimento.dart';
import '../../models/veiculo.dart';
import '../widgets/grafico_consumo.dart';
import 'tela_abastecimento.dart';
import 'tela_veiculo.dart';

/// Tela principal com indicadores, resumos, gráfico e histórico de abastecimentos
class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  final _repositorio = Repositorio();
  final _moedaFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool _carregando = true;
  Veiculo? _veiculoAtual;
  List<Abastecimento> _abastecimentos = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    final veiculo = await _repositorio.obterVeiculoAtual();
    List<Abastecimento> abastecimentos = [];
    if (veiculo?.id != null) {
      abastecimentos = await _repositorio.listarAbastecimentos(veiculoId: veiculo!.id);
    }

    if (mounted) {
      setState(() {
        _veiculoAtual = veiculo;
        _abastecimentos = abastecimentos;
        _carregando = false;
      });
    }
  }

  Future<void> _abrirTelaVeiculo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaVeiculo()),
    );
    _carregarDados();
  }

  Future<void> _abrirNovoAbastecimento() async {
    if (_veiculoAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um veículo antes de registrar abastecimentos.'),
          backgroundColor: Colors.orange,
        ),
      );
      _abrirTelaVeiculo();
      return;
    }

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaAbastecimento()),
    );
    if (resultado == true) {
      _carregarDados();
    }
  }

  Future<void> _excluirAbastecimento(Abastecimento abastecimento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Abastecimento'),
        content: Text(
          'Deseja realmente remover o abastecimento de ${abastecimento.quilometragem} km?',
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
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && abastecimento.id != null) {
      await _repositorio.excluirAbastecimento(abastecimento.id!);
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Combustível'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car),
            tooltip: 'Gerenciar Veículo',
            onPressed: _abrirTelaVeiculo,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildHeaderVeiculo(),
                  const SizedBox(height: 16),
                  if (_veiculoAtual != null) ...[
                    _buildCardsResumo(),
                    const SizedBox(height: 16),
                    GraficoConsumo(abastecimentos: _abastecimentos),
                    const SizedBox(height: 20),
                    _buildHistoricoAbastecimentos(),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoAbastecimento,
        icon: const Icon(Icons.local_gas_station),
        label: const Text('Novo Abastecimento'),
      ),
    );
  }

  Widget _buildHeaderVeiculo() {
    if (_veiculoAtual == null) {
      return Card(
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.directions_car_filled_outlined,
                  size: 48, color: Colors.blue.shade700),
              const SizedBox(height: 12),
              const Text(
                'Nenhum Veículo Cadastrado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cadastre o veículo para começar a controlar seus gastos e consumo de combustível.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _abrirTelaVeiculo,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Veículo'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.directions_car,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_veiculoAtual!.marca} ${_veiculoAtual!.modelo}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Ano: ${_veiculoAtual!.ano} • Motor: ${_veiculoAtual!.cilindrada}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _abrirTelaVeiculo,
              child: const Text('Detalhes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsResumo() {
    if (_abastecimentos.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_abastecimentos.length == 1) {
      return Card(
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(14.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '1º abastecimento cadastrado como referência inicial. O consumo e o custo por km serão calculados a partir do próximo abastecimento.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calcula médias globais a partir do 2º abastecimento
    double totalKm = _abastecimentos.last.quilometragem - _abastecimentos.first.quilometragem;
    double totalLitrosAposPrimeiro = 0.0;
    double totalValorAposPrimeiro = 0.0;

    for (int i = 1; i < _abastecimentos.length; i++) {
      totalLitrosAposPrimeiro += _abastecimentos[i].litros;
      totalValorAposPrimeiro += _abastecimentos[i].valorTotal;
    }

    final consumoMedio = totalLitrosAposPrimeiro > 0 ? totalKm / totalLitrosAposPrimeiro : 0.0;
    final custoMedioKm = totalKm > 0 ? totalValorAposPrimeiro / totalKm : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildCardIndicador(
            titulo: 'Consumo Médio',
            valor: '${consumoMedio.toStringAsFixed(2)} km/L',
            icone: Icons.speed,
            cor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardIndicador(
            titulo: 'Custo Médio',
            valor: 'R\$ ${custoMedioKm.toStringAsFixed(2)}/km',
            icone: Icons.monetization_on_outlined,
            cor: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildCardIndicador({
    required String titulo,
    required String valor,
    required IconData icone,
    required MaterialColor cor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 20, color: cor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoAbastecimentos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Histórico de Abastecimentos (${_abastecimentos.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_abastecimentos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Nenhum abastecimento registrado ainda.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          // Exibe do mais recente para o mais antigo, mantendo a referência calculada
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _abastecimentos.length,
            itemBuilder: (context, visualIndex) {
              // Índice real no array ordenado de forma crescente (0 = mais antigo)
              final index = _abastecimentos.length - 1 - visualIndex;
              final atual = _abastecimentos[index];
              final anterior = index > 0 ? _abastecimentos[index - 1] : null;

              return _buildItemAbastecimento(atual, anterior, index);
            },
          ),
      ],
    );
  }

  Widget _buildItemAbastecimento(
    Abastecimento atual,
    Abastecimento? anterior,
    int index,
  ) {
    final ehPrimeiro = anterior == null;
    final distancia = !ehPrimeiro ? atual.calcularDistancia(anterior) : null;
    final consumo = !ehPrimeiro ? atual.calcularConsumoKmPorLitro(anterior) : null;
    final custoKm = !ehPrimeiro ? atual.calcularCustoPorKm(anterior) : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        atual.tipoCombustivel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dateFormat.format(atual.dataHora),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'Excluir',
                  onPressed: () => _excluirAbastecimento(atual),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${atual.quilometragem.toStringAsFixed(0)} KM',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${atual.litros.toStringAsFixed(2)} L • R\$ ${atual.precoLitro.toStringAsFixed(2)}/L',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  _moedaFormat.format(atual.valorTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            if (ehPrimeiro)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'Abastecimento inicial (ponto de referência)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSubIndicador(
                    rotulo: 'Distância',
                    valor: '${distancia?.toStringAsFixed(0) ?? '0'} km',
                    icone: Icons.navigation_outlined,
                  ),
                  _buildSubIndicador(
                    rotulo: 'Consumo',
                    valor: '${consumo?.toStringAsFixed(2) ?? '0.00'} km/L',
                    icone: Icons.speed,
                    destaque: true,
                  ),
                  _buildSubIndicador(
                    rotulo: 'Custo/KM',
                    valor: 'R\$ ${custoKm?.toStringAsFixed(2) ?? '0.00'}',
                    icone: Icons.monetization_on_outlined,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubIndicador({
    required String rotulo,
    required String valor,
    required IconData icone,
    bool destaque = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              rotulo,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: destaque ? Colors.blue.shade800 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
