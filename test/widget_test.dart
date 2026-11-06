import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/combustivel/models/abastecimento.dart';
import 'package:flutter_application_1/features/combustivel/models/veiculo.dart';

void main() {
  group('Testes de Veiculo', () {
    test('Serialização toMap e fromMap', () {
      final veiculo = Veiculo(
        id: 1,
        marca: 'Chevrolet',
        modelo: 'Onix 1.0',
        ano: 2022,
        cilindrada: '1.0',
      );

      final map = veiculo.toMap();
      expect(map['marca'], 'Chevrolet');
      expect(map['modelo'], 'Onix 1.0');
      expect(map['ano'], 2022);
      expect(map['cilindrada'], '1.0');

      final deserializado = Veiculo.fromMap(map);
      expect(deserializado.id, 1);
      expect(deserializado.marca, 'Chevrolet');
      expect(deserializado.modelo, 'Onix 1.0');
      expect(deserializado.ano, 2022);
      expect(deserializado.cilindrada, '1.0');
    });
  });

  group('Testes de Abastecimento e Regras de Negócio', () {
    test('Cálculo de valor total automático', () {
      final abastecimento = Abastecimento(
        id: 1,
        veiculoId: 1,
        tipoCombustivel: 'Gasolina',
        precoLitro: 5.50,
        quilometragem: 10000,
        litros: 40,
        dataHora: DateTime.now(),
      );

      expect(abastecimento.valorTotal, 220.0);
    });

    test('Cálculo de indicadores entre abastecimentos conforme a especificação', () {
      // 1º abastecimento: 10.000 km, 45 L, R$ 5,00/L -> R$ 225,00
      final abast1 = Abastecimento(
        id: 1,
        veiculoId: 1,
        tipoCombustivel: 'Gasolina',
        precoLitro: 5.00,
        quilometragem: 10000,
        litros: 45,
        dataHora: DateTime(2026, 11, 1),
      );

      // 2º abastecimento: 10.450 km, 40 L, R$ 5,50/L -> R$ 220,00
      final abast2 = Abastecimento(
        id: 2,
        veiculoId: 1,
        tipoCombustivel: 'Gasolina',
        precoLitro: 5.50,
        quilometragem: 10450,
        litros: 40,
        dataHora: DateTime(2026, 11, 5),
      );

      // Distância = KM atual (10450) - KM anterior (10000) = 450 km
      final distancia = abast2.calcularDistancia(abast1);
      expect(distancia, 450.0);

      // Consumo = Distância (450) / Litros atuais (40) = 11.25 km/L
      final consumo = abast2.calcularConsumoKmPorLitro(abast1);
      expect(consumo, 11.25);

      // Custo = Valor Total atual (220.00) / Distância (450) = ~0.4888 R$/km
      final custoKm = abast2.calcularCustoPorKm(abast1);
      expect(custoKm, closeTo(0.488, 0.001));
    });
  });
}
