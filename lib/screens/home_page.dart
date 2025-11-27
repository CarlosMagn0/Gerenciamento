import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../widgets/product_card.dart';
import 'novo_produto_page.dart';
import 'estatisticas_page.dart';
import 'detalhes_produto_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Produto> produtos = [];

  // UI state
  String _search = '';
  String _sort = 'Mais vendidos';
  String? _filterCategoria;

  // Exemplo: adicionar / atualizar / remover
  void adicionarProduto(Produto p) {
    setState(() => produtos.add(p));
  }

  void atualizar() => setState(() {});

  void removerProduto(Produto p) {
    setState(() => produtos.remove(p));
  }

  void venderProduto(Produto p) {
    setState(() {
      if (p.estoque > 0) {
        p.estoque = p.estoque - 1;
        p.vendidos = p.vendidos + 1;
      }
    });
  }

  List<String> getCategorias() {
    final set = <String>{};
    for (var p in produtos) {
      set.add(p.categoria);
    }
    return ['Todas', ...set];
  }

  double get receitaTotal =>
      produtos.fold(0.0, (s, p) => s + p.precoVenda * p.vendidos);
  double get lucroTotal =>
      produtos.fold(0.0, (s, p) => s + p.lucroTotal);
  int get totalProdutos =>
      produtos.fold(0, (s, p) => s + p.estoque);

  List<Produto> applyFilters() {
    var list = produtos.toList();

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) {
        final nome = p.nome.toLowerCase();
        final cat = p.categoria.toLowerCase();
        return nome.contains(q) || cat.contains(q);
      }).toList();
    }

    if (_filterCategoria != null && _filterCategoria != 'Todas') {
      list = list.where((p) => p.categoria == _filterCategoria).toList();
    }

    if (_sort == 'Mais vendidos') {
      list.sort((a, b) => b.vendidos.compareTo(a.vendidos));
    } else if (_sort == 'Maior lucro') {
      list.sort((a, b) => (b.lucroTotal).compareTo(a.lucroTotal));
    } else if (_sort == 'A - Z') {
      list.sort((a, b) => a.nome.compareTo(b.nome));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final categorias = getCategorias();
    final filtered = applyFilters();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciador de Loja"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EstatisticasPage(produtos: produtos)),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NovoProdutoPage()),
          );
          if (result != null && result is Produto) adicionarProduto(result);
        },
        child: const Icon(Icons.add, size: 30),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              // Search & quick actions row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                  hintText: 'Procurar produto ou categoria',
                                  border: InputBorder.none,
                              ),
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                          if (_search.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _search = ''),
                              child: const Icon(Icons.close, size: 18, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // small filter icon (could open advanced filters)
                  InkWell(
                    onTap: () {
                      // exemplo: abrir modal de filtros (pode ser implementado)
                      showModalBottomSheet(context: context, builder: (_) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: categorias.map((c) {
                                  final selected = c == (_filterCategoria ?? 'Todas');
                                  return ChoiceChip(
                                    label: Text(c),
                                    selected: selected,
                                    onSelected: (_) => setState(() {
                                      _filterCategoria = c == 'Todas' ? null : c;
                                      Navigator.pop(context);
                                    }),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.filter_list, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // KPIs row
              Row(
                children: [
                  _kpiCard('Receita', 'R\$ ${receitaTotal.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                  const SizedBox(width: 8),
                  _kpiCard('Lucro', 'R\$ ${lucroTotal.toStringAsFixed(2)}', Icons.trending_up, Colors.deepPurpleAccent),
                  const SizedBox(width: 8),
                  _kpiCard('Estoque', '$totalProdutos', Icons.inventory_2, Colors.orange),
                ],
              ),

              const SizedBox(height: 12),

              // Filters: categoria chips + sort dropdown
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: categorias.map((c) {
                          final selected = (_filterCategoria ?? 'Todas') == c;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: selected,
                              onSelected: (_) => setState(() {
                                _filterCategoria = c == 'Todas' ? null : c;
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sort,
                      items: ['Mais vendidos', 'Maior lucro', 'A - Z'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (v) => setState(() => _sort = v ?? 'Mais vendidos'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Grid of product cards or empty state
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Nenhum produto encontrado', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return ProductCard(
                            produto: p,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalhesProdutoPage(produto: p, atualizar: atualizar),
                                ),
                              );
                            },
                            onDelete: () => removerProduto(p),
                            onSell: () => venderProduto(p),
                            onEdit: () async {
                              // abrir e editar (reaproveitar NovoProdutoPage para edição se quiser)
                              final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => NovoProdutoPage()));
                              if (res != null) atualizar();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
