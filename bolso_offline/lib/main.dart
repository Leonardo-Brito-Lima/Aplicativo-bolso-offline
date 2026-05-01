import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'screens/dashboard_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  await DatabaseHelper().database;


  await DatabaseHelper().gerarCicloMensal();


  runApp(const BolsoOfflineApp());
}

class BolsoOfflineApp extends StatelessWidget {
  const BolsoOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolso Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// --- Tela Inicial Temporária ---
// Vamos criar a estrutura visual real no próximo passo,
// por enquanto esta tela serve apenas para confirmar que tudo rodou sem erros.
