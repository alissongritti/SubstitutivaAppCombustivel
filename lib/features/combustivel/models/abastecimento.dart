class Abastecimento {
  final int? id;
  final int veiculoId;
  final String tipoCombustivel;
  final double precoLitro;
  final double quilometragem;
  final double litros;
  final DateTime dataHora;
  final double valorTotal;

  Abastecimento({
    this.id,
    required this.veiculoId,
    required this.tipoCombustivel,
    required this.precoLitro,
    required this.quilometragem,
    required this.litros,
    required this.dataHora,
    double? valorTotal,
  }) : valorTotal = valorTotal ?? (precoLitro * litros);

  /// Distância percorrida em relação ao abastecimento anterior
  /// Distância = KM atual - KM anterior
  double calcularDistancia(Abastecimento anterior) {
    return quilometragem - anterior.quilometragem;
  }

  /// Consumo em km/L entre abastecimentos
  /// Consumo (km/L) = Distância / Litros atuais
  double? calcularConsumoKmPorLitro(Abastecimento anterior) {
    if (litros <= 0) return null;
    final distancia = calcularDistancia(anterior);
    if (distancia <= 0) return 0.0;
    return distancia / litros;
  }

  /// Custo por quilômetro percorrido
  /// Custo (R$/km) = Valor Total atual / Distância
  double? calcularCustoPorKm(Abastecimento anterior) {
    final distancia = calcularDistancia(anterior);
    if (distancia <= 0) return null;
    return valorTotal / distancia;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'veiculo_id': veiculoId,
      'tipo_combustivel': tipoCombustivel,
      'preco_litro': precoLitro,
      'quilometragem': quilometragem,
      'litros': litros,
      'data_hora': dataHora.toIso8601String(),
      'valor_total': valorTotal,
    };
  }

  factory Abastecimento.fromMap(Map<String, dynamic> map) {
    final precoLitro = (map['preco_litro'] as num).toDouble();
    final litros = (map['litros'] as num).toDouble();
    final valorTotalDb = map['valor_total'] != null
        ? (map['valor_total'] as num).toDouble()
        : (precoLitro * litros);

    return Abastecimento(
      id: map['id'] as int?,
      veiculoId: map['veiculo_id'] as int,
      tipoCombustivel: map['tipo_combustivel'] as String,
      precoLitro: precoLitro,
      quilometragem: (map['quilometragem'] as num).toDouble(),
      litros: litros,
      dataHora: DateTime.parse(map['data_hora'] as String),
      valorTotal: valorTotalDb,
    );
  }

  Abastecimento copyWith({
    int? id,
    int? veiculoId,
    String? tipoCombustivel,
    double? precoLitro,
    double? quilometragem,
    double? litros,
    DateTime? dataHora,
    double? valorTotal,
  }) {
    return Abastecimento(
      id: id ?? this.id,
      veiculoId: veiculoId ?? this.veiculoId,
      tipoCombustivel: tipoCombustivel ?? this.tipoCombustivel,
      precoLitro: precoLitro ?? this.precoLitro,
      quilometragem: quilometragem ?? this.quilometragem,
      litros: litros ?? this.litros,
      dataHora: dataHora ?? this.dataHora,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }
}
