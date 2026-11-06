class Veiculo {
  final int? id;
  final String marca;
  final String modelo;
  final int ano;
  final String cilindrada;

  Veiculo({
    this.id,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.cilindrada,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marca': marca,
      'modelo': modelo,
      'ano': ano,
      'cilindrada': cilindrada,
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      id: map['id'] as int?,
      marca: map['marca'] as String,
      modelo: map['modelo'] as String,
      ano: map['ano'] as int,
      cilindrada: map['cilindrada']?.toString() ?? '',
    );
  }

  Veiculo copyWith({
    int? id,
    String? marca,
    String? modelo,
    int? ano,
    String? cilindrada,
  }) {
    return Veiculo(
      id: id ?? this.id,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      ano: ano ?? this.ano,
      cilindrada: cilindrada ?? this.cilindrada,
    );
  }
}
