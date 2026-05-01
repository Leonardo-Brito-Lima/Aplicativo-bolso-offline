import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _valorController = TextEditingController();

  String _tipoTransacao = 'despesa'; // Padrão começa como despesa

  void _salvarTransacao() async {
    // 1. Verifica se os campos estão preenchidos corretamente
    if (_formKey.currentState!.validate()) {
      try {
        // 2. Limpeza avançada: remove pontos de milhar e troca vírgula por ponto
        String valorLimpo = _valorController.text
            .replaceAll('.', '')
            .replaceAll(',', '.');
        double valor = double.parse(valorLimpo);

        Map<String, dynamic> novaTransacao = {
          'titulo': _tituloController.text,
          'valor': valor,
          'tipo': _tipoTransacao,
          // Adicionamos os campos exatos que o banco exige:
          'frequencia': 'esporadica',
          'data_vencimento': DateTime.now().toIso8601String(),
          'status': 1,
        };
        // 3. Tenta salvar no banco de dados
        await DatabaseHelper().inserirTransacao(novaTransacao);

        // 4. Deu tudo certo? Mostra mensagem verde e fecha a tela!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lançamento salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (erro) {
        // CAPTURA DE ERRO: Se o banco de dados falhar, a tela vai ficar vermelha e te avisar!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $erro'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        print("====== ERRO GRAVE NO BANCO ======\n$erro");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Lançamento'),
        backgroundColor: _tipoTransacao == 'receita'
            ? Colors.green
            : Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botões para escolher Receita ou Despesa
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'receita',
                    label: Text('Receita'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: 'despesa',
                    label: Text('Despesa'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_tipoTransacao},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _tipoTransacao = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return _tipoTransacao == 'receita'
                          ? Colors.green.shade100
                          : Colors.red.shade100;
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Campo de Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título (ex: Salário, Mercado)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de Valor
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Insira um valor numérico válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botão de Salvar
              ElevatedButton(
                onPressed: _salvarTransacao,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _tipoTransacao == 'receita'
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salvar', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
