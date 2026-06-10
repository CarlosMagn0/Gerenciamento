import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/produto.dart';
import 'models/venda.dart';
import 'screens/home_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProdutoAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(VendaAdapter());
  }

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
      home: const LoginPage(),
    );
  }
}

