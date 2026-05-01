import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, double> _resumoFinanceiro = {
    'saldo_atual': 0.0,
    'saldo_projetado': 0.0,
    'total_receitas_mes': 0.0,
    'total_despesas_mes': 0.0,
  };
  List<Map<String, dynamic>> _transacoes = [];

  @override
  void initState() {
    super.initState();
    _atualizarDados();
  }

  // Busca o resumo e a lista ao mesmo tempo
  Future<void> _atualizarDados() async {
    setState(() => _isLoading = true);

    final resumo = await DatabaseHelper().getResumoFinanceiro();
    final transacoes = await DatabaseHelper().listarTransacoes();

    setState(() {
      _resumoFinanceiro = resumo;
      _transacoes = transacoes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Meu Bolso Offline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: 'Novo Lançamento',
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );

              if (resultado == true) {
                _atualizarDados();
              }
            },
          ),
          const SizedBox(
            width: 8,
          ), // Um pequeno espaço para não ficar colado na borda
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Principal - Saldo Atual
                  _buildCard(
                    titulo: 'Saldo Atual',
                    valor: _resumoFinanceiro['saldo_atual']!,
                    corTexto: _resumoFinanceiro['saldo_atual']! >= 0
                        ? Colors.green
                        : Colors.red,
                    tamanhoFonte: 32,
                  ),
                  const SizedBox(height: 16),

                  // Cards de Receitas e Despesas lado a lado
                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          titulo: 'Receitas (Mês)',
                          valor: _resumoFinanceiro['total_receitas_mes']!,
                          corTexto: Colors.green,
                          tamanhoFonte: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCard(
                          titulo: 'Despesas (Mês)',
                          valor: _resumoFinanceiro['total_despesas_mes']!,
                          corTexto: Colors.red,
                          tamanhoFonte: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card - Projeção do Mês
                  _buildCard(
                    titulo: 'Projeção Fim do Mês',
                    valor: _resumoFinanceiro['saldo_projetado']!,
                    corTexto: _resumoFinanceiro['saldo_projetado']! >= 0
                        ? Colors.blue
                        : Colors.orange,
                    tamanhoFonte: 24,
                  ),

                  const SizedBox(height: 24),

                  // Título da Seção da Lista
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'Lançamentos Recentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // A Lista de Transações
                  Expanded(
                    child: _transacoes.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum lançamento ainda.\nClique no + para começar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _transacoes.length,
                            itemBuilder: (context, index) {
                              final item = _transacoes[index];
                              final bool isReceita = item['tipo'] == 'receita';

                              String valorFormatado = item['valor']
                                  .toStringAsFixed(2)
                                  .replaceAll('.', ',');

                              // O Dismissible permite arrastar o item para os lados
                              return Dismissible(
                                // O Flutter precisa de uma chave única (o ID do banco) para saber quem deletar
                                key: Key(item['id'].toString()),
                                direction: DismissDirection
                                    .endToStart, // Arrasta da direita para a esquerda
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  // 1. Apaga do banco de dados
                                  await DatabaseHelper().excluirTransacao(
                                    item['id'],
                                  );

                                  // 2. Recarrega os saldos e a lista automaticamente
                                  _atualizarDados();

                                  // 3. Mostra um aviso rápido na tela
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${item['titulo']} excluído!',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                // O Card original continua igual, agora apenas "dentro" do Dismissible
                                child: Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isReceita
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      child: Icon(
                                        isReceita
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: isReceita
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      item['titulo'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item['frequencia'] == 'fixa' ? 'Fixa' : 'Esporádica'} • ${item['data_vencimento'].toString().substring(0, 10)}',
                                    ),
                                    trailing: Text(
                                      'R\$ $valorFormatado',
                                      style: TextStyle(
                                        color: isReceita
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required double valor,
    required Color corTexto,
    required double tamanhoFonte,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: tamanhoFonte,
                fontWeight: FontWeight.bold,
                color: corTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
