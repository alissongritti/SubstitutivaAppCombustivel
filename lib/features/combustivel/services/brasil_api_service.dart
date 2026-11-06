import 'dart:convert';
import 'package:http/http.dart' as http;

class MarcaFipe {
  final String nome;
  final String codigo;

  const MarcaFipe({required this.nome, required this.codigo});

  factory MarcaFipe.fromJson(Map<String, dynamic> json) {
    return MarcaFipe(
      nome: (json['nome'] ?? json['name'] ?? '').toString(),
      codigo: (json['valor'] ?? json['codigo'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarcaFipe &&
          runtimeType == other.runtimeType &&
          codigo == other.codigo;

  @override
  int get hashCode => codigo.hashCode;
}

class ModeloFipe {
  final String nome;
  final String codigo;

  const ModeloFipe({required this.nome, required this.codigo});

  factory ModeloFipe.fromJson(Map<String, dynamic> json) {
    // Na BrasilAPI o campo vem como 'modelo', enquanto no Parallelum vem como 'nome'
    final nomeExtraido =
        (json['modelo'] ?? json['nome'] ?? json['name'] ?? '').toString();
    final codigoExtraido =
        (json['valor'] ?? json['codigo'] ?? '').toString();

    return ModeloFipe(
      nome: nomeExtraido,
      codigo: codigoExtraido,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModeloFipe &&
          runtimeType == other.runtimeType &&
          codigo == other.codigo;

  @override
  int get hashCode => codigo.hashCode;
}

/// Serviço de consumo HTTP para a BrasilAPI (Tabela FIPE)
class BrasilApiService {
  static const String brasilApiBaseUrl = 'https://brasilapi.com.br/api/fipe';
  static const String fallbackFipeBaseUrl = 'https://parallelum.com.br/fipe/api/v1';

  final http.Client _client;

  BrasilApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca a lista de marcas de carros
  Future<List<MarcaFipe>> buscarMarcas() async {
    // 1. Tentar BrasilAPI
    try {
      final response = await _client
          .get(Uri.parse('$brasilApiBaseUrl/marcas/v1/carros'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final marcas = data
            .map((item) => MarcaFipe.fromJson(item))
            .where((m) => m.nome.isNotEmpty)
            .toList();
        marcas.sort((a, b) => a.nome.compareTo(b.nome));
        if (marcas.isNotEmpty) return marcas;
      }
    } catch (_) {
      // Falha de rede ou timeout na BrasilAPI, tenta o fallback
    }

    // 2. Fallback Parallelum Fipe
    try {
      final response = await _client
          .get(Uri.parse('$fallbackFipeBaseUrl/carros/marcas'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final marcas = data
            .map((item) => MarcaFipe.fromJson(item))
            .where((m) => m.nome.isNotEmpty)
            .toList();
        marcas.sort((a, b) => a.nome.compareTo(b.nome));
        if (marcas.isNotEmpty) return marcas;
      }
    } catch (_) {
      // Ignora erro e recorre aos dados locais
    }

    // 3. Fallback de contingência offline com marcas mais comuns
    return _marcasLocaisPadrao;
  }

  /// Busca dinamicamente os modelos de carros filtrados pelo código da marca
  Future<List<ModeloFipe>> buscarModelos(String codigoMarca) async {
    // 1. Tentar BrasilAPI
    try {
      final response = await _client
          .get(Uri.parse('$brasilApiBaseUrl/veiculos/v1/carros/$codigoMarca'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final modelos = data
            .map((item) => ModeloFipe.fromJson(item))
            .where((m) => m.nome.isNotEmpty)
            .toList();

        if (modelos.isNotEmpty) {
          final mapaUnicos = <String, ModeloFipe>{};
          for (final m in modelos) {
            mapaUnicos.putIfAbsent(m.nome, () => m);
          }
          final lista = mapaUnicos.values.toList();
          lista.sort((a, b) => a.nome.compareTo(b.nome));
          return lista;
        }
      }
    } catch (_) {
      // Falha na rota BrasilAPI, tenta fallback
    }

    // 2. Fallback Parallelum Fipe
    try {
      final response = await _client
          .get(Uri.parse('$fallbackFipeBaseUrl/carros/marcas/$codigoMarca/modelos'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('modelos')) {
          final List<dynamic> listaModelos = data['modelos'];
          final modelos = listaModelos
              .map((item) => ModeloFipe.fromJson(item))
              .where((m) => m.nome.isNotEmpty)
              .toList();

          if (modelos.isNotEmpty) {
            final mapaUnicos = <String, ModeloFipe>{};
            for (final m in modelos) {
              mapaUnicos.putIfAbsent(m.nome, () => m);
            }
            final lista = mapaUnicos.values.toList();
            lista.sort((a, b) => a.nome.compareTo(b.nome));
            return lista;
          }
        }
      }
    } catch (_) {
      // Ignora
    }

    // 3. Fallback offline por código da marca para garantir navegação fluida
    return _obterModelosLocaisPadrao(codigoMarca);
  }

  List<ModeloFipe> _obterModelosLocaisPadrao(String codigoMarca) {
    final modelos = _modelosPadraoPorMarca[codigoMarca] ?? [];
    return modelos
        .map((nome) => ModeloFipe(nome: nome, codigo: nome.hashCode.toString()))
        .toList();
  }

  static const List<MarcaFipe> _marcasLocaisPadrao = [
    MarcaFipe(nome: 'Chevrolet', codigo: '23'),
    MarcaFipe(nome: 'Fiat', codigo: '21'),
    MarcaFipe(nome: 'Ford', codigo: '22'),
    MarcaFipe(nome: 'Honda', codigo: '25'),
    MarcaFipe(nome: 'Hyundai', codigo: '26'),
    MarcaFipe(nome: 'Renault', codigo: '44'),
    MarcaFipe(nome: 'Toyota', codigo: '56'),
    MarcaFipe(nome: 'Volkswagen', codigo: '59'),
  ];

  static const Map<String, List<String>> _modelosPadraoPorMarca = {
    '23': [ // Chevrolet
      'Onix 1.0',
      'Onix Plus 1.0 Turbo',
      'Prisma 1.4',
      'Celta 1.0',
      'Tracker 1.0 Turbo',
      'S10 2.8 Diesel',
      'Spin 1.8',
      'Cruze 1.4 Turbo',
    ],
    '21': [ // Fiat
      'Argo 1.0',
      'Cronos 1.3',
      'Mobi 1.0',
      'Palio 1.0 / 1.4',
      'Strada 1.3 Freedom / Volcano',
      'Toro 1.3 Turbo / 2.0 Diesel',
      'Uno 1.0 Mille / Attractive',
      'Pulse 1.0 Turbo',
    ],
    '22': [ // Ford
      'Ka 1.0 / 1.5',
      'Ka Sedan 1.5',
      'EcoSport 1.5 / 2.0',
      'Fiesta 1.0 / 1.6',
      'Ranger 2.2 / 3.2 Diesel',
      'Focus 1.6 / 2.0',
    ],
    '25': [ // Honda
      'Civic 1.5 Turbo / 2.0',
      'City 1.5',
      'Fit 1.5',
      'HR-V 1.5 Turbo / 1.8',
      'WR-V 1.5',
      'CR-V 1.5 Turbo',
    ],
    '26': [ // Hyundai
      'HB20 1.0 / 1.0 Turbo',
      'HB20S 1.0 / 1.6',
      'Creta 1.0 Turbo / 2.0',
      'Tucson 1.6 Turbo / 2.0',
      'i30 1.8 / 2.0',
    ],
    '44': [ // Renault
      'Kwid 1.0',
      'Sandero 1.0 / 1.6',
      'Logan 1.0 / 1.6',
      'Duster 1.3 Turbo / 1.6',
      'Captur 1.3 Turbo',
      'Oroch 1.3 Turbo / 1.6',
    ],
    '56': [ // Toyota
      'Corolla 1.8 Híbrido / 2.0',
      'Corolla Cross 2.0 / Híbrido',
      'Yaris Hatch / Sedan 1.5',
      'Etios 1.3 / 1.5',
      'Hilux 2.8 Diesel',
      'SW4 2.8 Diesel',
    ],
    '59': [ // Volkswagen
      'Gol 1.0 / 1.6',
      'Polo 1.0 / 1.0 TSI',
      'Virtus 1.0 TSI',
      'T-Cross 1.0 TSI / 1.4 TSI',
      'Nivus 1.0 TSI',
      'Saveiro 1.6',
      'Voyage 1.0 / 1.6',
      'Fox 1.6',
    ],
  };
}
