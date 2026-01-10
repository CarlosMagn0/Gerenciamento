import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/produto.dart';
import '../produto_repository.dart';
import '../widgets/product_list_card.dart';
import 'novo_produto_page.dart';
import 'estatisticas_page.dart';
import 'detalhes_produto_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProdutoRepository repo = ProdutoRepository();

  String _search = '';
  String _sort = 'Mais vendidos';
  String? _filterCategoria;

  // ================== HELPERS ==================
  List<Produto> _filtrar(List<Produto> produtos) {
    var list = [...produtos];

    if (_search.isNotEmpty) {
      list = list
          .where((p) =>
              p.nome.toLowerCase().contains(_search.toLowerCase()) ||
              p.categoria.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    if (_filterCategoria != null) {
      list = list.where((p) => p.categoria == _filterCategoria).toList();
    }

    if (_sort == 'Mais vendidos') {
      list.sort((a, b) => b.vendidos.compareTo(a.vendidos));
    } else if (_sort == 'Maior lucro') {
      list.sort((a, b) => b.lucroTotal.compareTo(a.lucroTotal));
    } else {
      list.sort((a, b) => a.nome.compareTo(b.nome));
    }

    return list;
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6A5AE0),
        icon: const Icon(Icons.add),
        label: const Text("Novo"),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovoProdutoPage()),
          );
          if (res is Produto) {
            await repo.adicionar(res);
          }
        },
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Produto>('produtosBox').listenable(),
        builder: (context, Box<Produto> box, _) {
          final produtos = box.values.toList();
          final filtrados = _filtrar(produtos);

          final receitaTotal =
              produtos.fold(0.0, (s, p) => s + p.precoVenda * p.vendidos);
          final lucroTotal = produtos.fold(0.0, (s, p) => s + p.lucroTotal);
          final estoqueTotal = produtos.fold(0, (s, p) => s + p.estoque);

          final categorias = {'Todas', ...produtos.map((p) => p.categoria)}
              .toList();

          return CustomScrollView(
            slivers: [
              _buildHeader(receitaTotal, lucroTotal, produtos),
              SliverToBoxAdapter(child: _buildSearch()),
              SliverToBoxAdapter(child: _buildKpis(produtos.length, estoqueTotal)),
              SliverToBoxAdapter(child: _buildFilters(categorias)),
              filtrados.isEmpty
                  ? SliverFillRemaining(child: _emptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final p = filtrados[i];
                          final index = produtos.indexOf(p);

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: ProductListCard(
                              produto: p,
                              onSell: () async {
                                if (p.estoque > 0) {
                                  p.estoque--;
                                  p.vendidos++;
                                  await repo.atualizar(index, p);
                                }
                              },
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NovoProdutoPage(produto: p),
                                  ),
                                );
                                await repo.atualizar(index, p);
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalhesProdutoPage(
                                      produto: p,
                                      atualizar: () =>
                                          repo.atualizar(index, p),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: filtrados.length,
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  // ================== HEADER ==================
  SliverAppBar _buildHeader(
      double receita, double lucro, List<Produto> produtos) {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A5AE0), Color(0xFF8F7CFF)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Visão geral",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text("Produtos: ${produtos.length}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerValue("Receita", receita),
                  _headerValue("Lucro", lucro),
                ],
              )
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EstatisticasPage(produtos: produtos),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _headerValue(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          "R\$ ${value.toStringAsFixed(2)}",
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ],
    );
  }

  // ================== SEARCH ==================
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: "Buscar produto ou categoria...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ================== KPIs ==================
  Widget _buildKpis(int total, int estoque) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _kpi("Produtos", total.toString(), Icons.shopping_bag),
          const SizedBox(width: 12),
          _kpi("Estoque", estoque.toString(), Icons.inventory_2),
        ],
      ),
    );
  }

  Widget _kpi(String t, String v, IconData i) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6A5AE0),
              child: Icon(i, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: const TextStyle(color: Colors.grey)),
                Text(v,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ================== FILTROS ==================
  Widget _buildFilters(List<String> categorias) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categorias.map((c) {
                  final selected = (_filterCategoria ?? 'Todas') == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _filterCategoria = c == 'Todas' ? null : c),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            icon: const Icon(Icons.tune),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Mais vendidos', child: Text('Mais vendidos')),
              PopupMenuItem(value: 'Maior lucro', child: Text('Maior lucro')),
              PopupMenuItem(value: 'A - Z', child: Text('A - Z')),
            ],
          )
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Text("Nenhum produto cadastrado",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
