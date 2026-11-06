import 'package:sqflite/sqflite.dart';
import '../models/abastecimento.dart';
import '../models/veiculo.dart';
import 'banco_helper.dart';

/// Centraliza todas as operações de CRUD no banco de dados SQLite
class Repositorio {
  final BancoHelper _bancoHelper;

  Repositorio({BancoHelper? bancoHelper})
      : _bancoHelper = bancoHelper ?? BancoHelper.instance;

  // ----------------------------------------------------
  // Operações de Veículo (Apenas 1 veículo por vez)
  // ----------------------------------------------------

  /// Obtém o veículo cadastrado (retorna null se não houver)
  Future<Veiculo?> obterVeiculoAtual() async {
    final db = await _bancoHelper.database;
    final maps = await db.query(
      'veiculo',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Veiculo.fromMap(maps.first);
    }
    return null;
  }

  /// Verifica se já existe um veículo cadastrado
  Future<bool> temVeiculoCadastrado() async {
    final veiculo = await obterVeiculoAtual();
    return veiculo != null;
  }

  /// Insere um novo veículo
  Future<int> inserirVeiculo(Veiculo veiculo) async {
    final db = await _bancoHelper.database;
    return await db.insert(
      'veiculo',
      veiculo.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Exclui o veículo e remove em cascata todos os abastecimentos associados
  Future<void> excluirVeiculo(int id) async {
    final db = await _bancoHelper.database;
    await db.transaction((txn) async {
      // Exclui abastecimentos vinculados garantindo consistência
      await txn.delete(
        'abastecimento',
        where: 'veiculo_id = ?',
        whereArgs: [id],
      );

      // Exclui o veículo
      await txn.delete(
        'veiculo',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ----------------------------------------------------
  // Operações de Abastecimento
  // ----------------------------------------------------

  /// Insere um novo registro de abastecimento
  Future<int> inserirAbastecimento(Abastecimento abastecimento) async {
    final db = await _bancoHelper.database;
    return await db.insert(
      'abastecimento',
      abastecimento.toMap()..remove('id'),
    );
  }

  /// Lista abastecimentos ordenados por quilometragem (e data/hora) crescente
  /// Esta ordenação é fundamental para os cálculos dos indicadores entre abastecimentos
  Future<List<Abastecimento>> listarAbastecimentos({int? veiculoId}) async {
    final db = await _bancoHelper.database;
    final where = veiculoId != null ? 'veiculo_id = ?' : null;
    final whereArgs = veiculoId != null ? [veiculoId] : null;

    final maps = await db.query(
      'abastecimento',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'quilometragem ASC, data_hora ASC',
    );

    return maps.map((m) => Abastecimento.fromMap(m)).toList();
  }

  /// Obtém o último abastecimento registrado para validação de KM
  Future<Abastecimento?> obterUltimoAbastecimento(int veiculoId) async {
    final db = await _bancoHelper.database;
    final maps = await db.query(
      'abastecimento',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
      orderBy: 'quilometragem DESC, data_hora DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Abastecimento.fromMap(maps.first);
    }
    return null;
  }

  /// Exclui um abastecimento específico por id
  Future<int> excluirAbastecimento(int id) async {
    final db = await _bancoHelper.database;
    return await db.delete(
      'abastecimento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
