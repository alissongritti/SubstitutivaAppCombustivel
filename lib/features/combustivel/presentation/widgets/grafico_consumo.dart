import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/abastecimento.dart';

enum TipoGrafico { consumo, custo }

/// Componente visual reutilizável que renderiza gráficos de evolução usando fl_chart
class GraficoConsumo extends StatefulWidget {
  final List<Abastecimento> abastecimentos;

  const GraficoConsumo({
    super.key,
    required this.abastecimentos,
  });

  @override
  State<GraficoConsumo> createState() => _GraficoConsumoState();
}

class _GraficoConsumoState extends State<GraficoConsumo> {
  TipoGrafico _tipoSelecionado = TipoGrafico.consumo;

  @override
  Widget build(BuildContext context) {
    // Para calcular consumo e custo, precisamos de pelo menos 2 abastecimentos
    if (widget.abastecimentos.length < 2) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_graph_outlined,
                  size: 48, color: Colors.blueGrey.shade300),
              const SizedBox(height: 12),
              const Text(
                'Gráfico Indisponível',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                widget.abastecimentos.isEmpty
                    ? 'Nenhum abastecimento registrado até o momento.'
                    : 'O primeiro abastecimento é a referência inicial. Registre o 2º abastecimento para gerar os gráficos.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Calcula os pontos a partir do 2º abastecimento (índice 1 em diante)
    final pontosConsumo = <FlSpot>[];
    final pontosCusto = <FlSpot>[];

    double minVal = double.infinity;
    double maxVal = -double.infinity;

    for (int i = 1; i < widget.abastecimentos.length; i++) {
      final anterior = widget.abastecimentos[i - 1];
      final atual = widget.abastecimentos[i];

      final consumo = atual.calcularConsumoKmPorLitro(anterior) ?? 0.0;
      final custo = atual.calcularCustoPorKm(anterior) ?? 0.0;

      final x = i.toDouble();
      pontosConsumo.add(FlSpot(x, consumo));
      pontosCusto.add(FlSpot(x, custo));

      final valorAtivo = _tipoSelecionado == TipoGrafico.consumo ? consumo : custo;
      if (valorAtivo < minVal) minVal = valorAtivo;
      if (valorAtivo > maxVal) maxVal = valorAtivo;
    }

    if (minVal == double.infinity) minVal = 0;
    if (maxVal == -double.infinity) maxVal = 10;
    if (minVal == maxVal) {
      minVal = (minVal - 2).clamp(0, double.infinity);
      maxVal = maxVal + 2;
    }

    final isConsumo = _tipoSelecionado == TipoGrafico.consumo;
    final corLinha = isConsumo ? Colors.blue.shade600 : Colors.teal.shade600;
    final spots = isConsumo ? pontosConsumo : pontosCusto;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConsumo ? Icons.speed : Icons.monetization_on_outlined,
                      color: corLinha,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConsumo ? 'Consumo (km/L)' : 'Custo (R\$/km)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SegmentedButton<TipoGrafico>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: TipoGrafico.consumo,
                      label: Text('km/L'),
                    ),
                    ButtonSegment(
                      value: TipoGrafico.custo,
                      label: Text('R\$/km'),
                    ),
                  ],
                  selected: {_tipoSelecionado},
                  onSelectionChanged: (novaSelecao) {
                    setState(() {
                      _tipoSelecionado = novaSelecao.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: (minVal * 0.85).floorToDouble(),
                  maxY: (maxVal * 1.15).ceilToDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 1 && idx < widget.abastecimentos.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '#$idx',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            isConsumo
                                ? value.toStringAsFixed(1)
                                : 'R\$${value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: corLinha,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: corLinha,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: corLinha.withAlpha(40),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final valStr = isConsumo
                              ? '${spot.y.toStringAsFixed(2)} km/L'
                              : 'R\$ ${spot.y.toStringAsFixed(2)}/km';
                          return LineTooltipItem(
                            'Abastecimento #$idx\n$valStr',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
