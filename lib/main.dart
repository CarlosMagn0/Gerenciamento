import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/produto.dart';
import 'models/venda.dart';
import 'screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Hive no dispositivo
  await Hive.initFlutter();

  // Registra o Adapter do Produto
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProdutoAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(VendaAdapter());
  }

  // ABRE A BOX (SEM ISSO NADA É SALVO)
  await Hive.openBox<Produto>('produtosBox');
  await Hive.openBox<Venda>('vendasBox');

  runApp(const GerenciadorApp());
}

class GerenciadorApp extends StatelessWidget {
  const GerenciadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Loja',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}
