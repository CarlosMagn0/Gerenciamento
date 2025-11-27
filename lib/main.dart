import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(GerenciadorApp());
}

class GerenciadorApp extends StatelessWidget {
  const GerenciadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Loja',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
