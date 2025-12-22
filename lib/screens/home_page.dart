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
  final List<Produto> produtos = [];

  String _search = '';
  String _sort = 'Mais vendidos';
  String? _filterCategoria;

  // ================== DADOS ==================
  double get receitaTotal =>
      produtos.fold(0, (s, p) => s + p.precoVenda * p.vendidos);

  double get lucroTotal =>
      produtos.fold(0, (s, p) => s + p.lucroTotal);

  int get totalEstoque =>
      produtos.fold(0, (s, p) => s + p.estoque);

  List<String> get categorias {
    final set = <String>{};
    for (var p in produtos) {
      set.add(p.categoria);
    }
    return ['Todas', ...set];
  }

  List<Produto> get produtosFiltrados {
    var list = [...produtos];

    if (_search.isNotEmpty) {
      list = list.where((p) =>
          p.nome.toLowerCase().contains(_search.toLowerCase()) ||
          p.categoria.toLowerCase().contains(_search.toLowerCase())).toList();
    }

    if (_filterCategoria != null && _filterCategoria != 'Todas') {
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

  // ================== AÇÕES ==================
  void adicionarProduto(Produto p) => setState(() => produtos.add(p));
  void removerProduto(Produto p) => setState(() => produtos.remove(p));

  void venderProduto(Produto p) {
    if (p.estoque > 0) {
      setState(() {
        p.estoque--;
        p.vendidos++;
      });
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NovoProdutoPage()),
          );
          if (res is Produto) adicionarProduto(res);
        },
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildKpis()),
          SliverToBoxAdapter(child: _buildFilters()),
          produtosFiltrados.isEmpty
              ? SliverFillRemaining(child: _emptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = produtosFiltrados[i];
                        return ProductCard(
                          produto: p,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalhesProdutoPage(
                                  produto: p,
                                  atualizar: () => setState(() {}),
                                ),
                              ),
                            );
                          },
                          onSell: () => venderProduto(p),
                          onDelete: () => removerProduto(p),
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NovoProdutoPage(),
                              ),
                            );
                            setState(() {});
                          },
                        );
                      },
                      childCount: produtosFiltrados.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ================== HEADER ==================
  SliverAppBar _buildHeader() {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A5AE0), Color(0xFF8F7CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gerenciador de Loja",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              const Text(
                "Visão geral",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _searchField(),
              const Spacer(),
              _headerTotals(),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.white),
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

  Widget _searchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar produto ou categoria',
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          if (_search.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _search = ''),
              child: const Icon(Icons.close, size: 18),
            )
        ],
      ),
    );
  }

  Widget _headerTotals() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _headerValue("Receita", receitaTotal),
          _headerValue("Lucro", lucroTotal),
        ],
      ),
    );
  }

  Widget _headerValue(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          "R\$ ${value.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  // ================== KPIs ==================
  Widget _buildKpis() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _kpiCard("Produtos", produtos.length.toString(), Icons.shopping_bag),
          const SizedBox(width: 12),
          _kpiCard("Estoque", totalEstoque.toString(), Icons.inventory),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6A5AE0),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================== FILTROS ==================
  Widget _buildFilters() {
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
          DropdownButton<String>(
            value: _sort,
            underline: const SizedBox(),
            items: ['Mais vendidos', 'Maior lucro', 'A - Z']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _sort = v!),
          ),
        ],
      ),
    );
  }

  // ================== EMPTY ==================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inbox, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "Nenhum produto encontrado",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
