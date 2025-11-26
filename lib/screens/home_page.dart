import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../widgets/product_card.dart';
import 'novo_produto_page.dart';
import 'estatisticas_page.dart';
import 'detalhes_produto_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Produto> produtos = [];

  void adicionarProduto(Produto p) {
    setState(() => produtos.add(p));
  }

  void atualizar() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciador de Loja"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 28),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => EstatisticasPage(produtos: produtos)));
            },
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context, MaterialPageRoute(builder: (_) => NovoProdutoPage()));
          if (result != null) adicionarProduto(result);
        },
        child: const Icon(Icons.add, size: 30),
      ),

      body: produtos.isEmpty
          ? const Center(
              child: Text(
                "Nenhum produto cadastrado",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: produtos.length,
              itemBuilder: (_, i) {
                final p = produtos[i];
                return ProductCard(
                  produto: p,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalhesProdutoPage(
                          produto: p,
                          atualizar: atualizar,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
