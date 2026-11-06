import 'package:flutter/material.dart';
import 'features/combustivel/presentation/screens/tela_dashboard.dart';

/// Configuração principal da aplicação com MaterialApp e Material 3
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Combustível',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const TelaDashboard(),
    );
  }
}
