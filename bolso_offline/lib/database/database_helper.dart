import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bolso_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL, -- 'receita' ou 'despesa'
        frequencia TEXT NOT NULL, -- 'fixa' ou 'esporadica'
        data_vencimento TEXT NOT NULL,
        status INTEGER DEFAULT 0, -- 0: Pendente, 1: Pago/Recebido
        id_origem INTEGER, -- Para rastrear duplicatas de contas fixas
        mes_referencia INTEGER -- Mês de competência (1-12)
      )
    ''');
  }

  // --- Operações de Saldo ---

  Future<Map<String, double>> getResumoFinanceiro() async {
    final db = await database;

    // Saldo Atual: Apenas o que já foi efetivado (status = 1)
    final List<Map<String, dynamic>> atual = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END) as receitas,
        SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END) as despesas
      FROM transacoes WHERE status = 1
    ''');

    // Projeção: Tudo o que está lançado no mês corrente
    final int mesAtual = DateTime.now().month;
    final List<Map<String, dynamic>> projecao = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END) as receitas,
        SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END) as despesas
      FROM transacoes WHERE mes_referencia = ?
    ''', [mesAtual]);

    double saldoAtual = (atual[0]['receitas'] ?? 0.0) - (atual[0]['despesas'] ?? 0.0);
    double saldoProjetado = (projecao[0]['receitas'] ?? 0.0) - (projecao[0]['despesas'] ?? 0.0);

    return {
      'saldo_atual': saldoAtual,
      'saldo_projetado': saldoProjetado,
      'total_receitas_mes': projecao[0]['receitas'] ?? 0.0,
      'total_despesas_mes': projecao[0]['despesas'] ?? 0.0,
    };
  }

  // --- Lógica de Duplicação de Contas Fixas ---

  Future<void> gerarCicloMensal() async {
    final db = await database;
    final int proximoMes = DateTime.now().month; // Simplificação para o mês atual/próximo
    
    // Busca contas fixas que ainda não foram replicadas para este mês
    final List<Map<String, dynamic>> fixas = await db.rawQuery('''
      SELECT * FROM transacoes 
      WHERE frequencia = 'fixa' 
      AND id NOT IN (SELECT id_origem FROM transacoes WHERE mes_referencia = ? AND id_origem IS NOT NULL)
      AND mes_referencia != ?
    ''', [proximoMes, proximoMes]);

    for (var conta in fixas) {
      DateTime dataOrigem = DateTime.parse(conta['data_vencimento']);
      DateTime novaData = DateTime(DateTime.now().year, proximoMes, dataOrigem.day);

      await db.insert('transacoes', {
        'titulo': conta['titulo'],
        'valor': conta['valor'],
        'tipo': conta['tipo'],
        'frequencia': 'fixa',
        'data_vencimento': novaData.toIso8601String(),
        'status': 0,
        'id_origem': conta['id'],
        'mes_referencia': proximoMes,
      });
    }
  }

  // --- CRUD Básico ---

  Future<int> inserirTransacao(Map<String, dynamic> row) async {
    final db = await database;
    // Garante que o mês de referência seja extraído da data de vencimento
    DateTime data = DateTime.parse(row['data_vencimento']);
    row['mes_referencia'] = data.month;
    return await db.insert('transacoes', row);
  }

  Future<List<Map<String, dynamic>>> listarTransacoes() async {
    final db = await database;
    return await db.query('transacoes', orderBy: 'data_vencimento ASC');
  }

  Future<int> atualizarStatus(int id, int novoStatus) async {
    final db = await database;
    return await db.update(
      'transacoes',
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> excluirTransacao(int id) async {
    final db = await database;
    return await db.delete('transacoes', where: 'id = ?', whereArgs: [id]);
  }
}