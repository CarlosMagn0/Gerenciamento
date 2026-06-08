import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/produto.dart';
import '../produto_repository.dart';
import '../venda_repository.dart';
import 'novo_produto_page.dart';
import 'estatisticas_page.dart';
import 'detalhes_produto_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ProdutoRepository repo = ProdutoRepository();
  final VendaRepository vendaRepo = VendaRepository();

  String _search = '';
  String _sort = 'Mais vendidos';
  String? _filterCategoria;
  bool _searchFocused = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  // ── Paleta ────────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF6A5AE0);
  static const _purpleMid = Color(0xFF8B5CF6);
  static const _purpleLight = Color(0xFFEDE9FB);
  static const _blueDark = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF7F6FB);
  static const _white = Colors.white;
  static const _grey = Color(0xFF888780);
  static const _greyLight = Color(0xFFE8E6F5);
  static const _green = Color(0xFF3B6D11);
  static const _greenLight = Color(0xFFEAF3DE);
  static const _greenMid = Color(0xFF639922);
  static const _red = Color(0xFFA32D2D);
  static const _redLight = Color(0xFFFCEBEB);
  static const _redMid = Color(0xFFE24B4A);
  static const _amber = Color(0xFFBA7517);
  static const _amberLight = Color(0xFFFAEEDA);

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
    _searchFocus.addListener(
        () => setState(() => _searchFocused = _searchFocus.hasFocus));
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Filtros ───────────────────────────────────────────────────────────────
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
    switch (_sort) {
      case 'Mais vendidos':
        list.sort((a, b) => b.vendidos.compareTo(a.vendidos));
        break;
      case 'Maior lucro':
        list.sort((a, b) => b.lucroTotal.compareTo(a.lucroTotal));
        break;
      case 'Maior margem':
        list.sort((a, b) {
          final mA = a.precoVenda == 0
              ? 0.0
              : (a.precoVenda - a.precoCompra) / a.precoVenda;
          final mB = b.precoVenda == 0
              ? 0.0
              : (b.precoVenda - b.precoCompra) / b.precoVenda;
          return mB.compareTo(mA);
        });
        break;
      default:
        list.sort((a, b) => a.nome.compareTo(b.nome));
    }
    return list;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        floatingActionButton: _fab(),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<Produto>('produtosBox').listenable(),
          builder: (context, Box<Produto> box, _) {
            final produtos = box.values.toList();
            final filtrados = _filtrar(produtos);

            final receitaTotal =
                produtos.fold(0.0, (s, p) => s + p.precoVenda * p.vendidos);
            final lucroTotal = produtos.fold(0.0, (s, p) => s + p.lucroTotal);
            final despesaTotal =
                produtos.fold(0.0, (s, p) => s + p.precoCompra * p.vendidos);
            final estoqueTotal = produtos.fold(0, (s, p) => s + p.estoque);
            final margem =
                receitaTotal == 0 ? 0.0 : (lucroTotal / receitaTotal * 100);

            final categorias =
                <String>{'Todas', ...produtos.map((p) => p.categoria)}.toList();

            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(produtos, receitaTotal, lucroTotal, margem),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(
                    child: _buildKpiRow(produtos.length, estoqueTotal, margem)),
                SliverToBoxAdapter(
                    child: _buildExecutivePanel(produtos, receitaTotal,
                        lucroTotal, despesaTotal, estoqueTotal, margem)),
                SliverToBoxAdapter(child: _buildFilterRow(categorias)),
                filtrados.isEmpty
                    ? SliverFillRemaining(child: _emptyState(produtos.isEmpty))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final p = filtrados[i];
                              final idx = produtos.indexOf(p);
                              return _produtoCard(p, idx);
                            },
                            childCount: filtrados.length,
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SLIVER APP BAR — SEM título nem actions duplicados
  // ═══════════════════════════════════════════════════════════════════════
  SliverAppBar _buildSliverAppBar(
      List<Produto> produtos, double receita, double lucro, double margem) {
    final hora = DateTime.now().hour;
    final saudacao = hora < 12
        ? 'Bom dia'
        : hora < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      // ── Sem title / actions aqui: evita duplicação ──────────────────
      automaticallyImplyLeading: false,
      backgroundColor: _purple,
      surfaceTintColor: _purple,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      // Barra colapsada: só fundo colorido + botão stats alinhado
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: const SizedBox.shrink(),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Quanto o header está expandido (0 = colapsado, 1 = expandido)
          final minH = kToolbarHeight + MediaQuery.of(context).padding.top;
          final maxH = 220.0 + MediaQuery.of(context).padding.top;
          final expandRatio =
              ((constraints.maxHeight - minH) / (maxH - minH)).clamp(0.0, 1.0);
          final collapsed = expandRatio < 0.15;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4C3BBF),
                  Color(0xFF6A5AE0),
                  Color(0xFF8B5CF6)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // ── Círculos decorativos ─────────────────────────────
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 50,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: -20,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF38BDF8).withOpacity(0.07),
                    ),
                  ),
                ),

                // ── Conteúdo principal ──────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Linha topo: saudação/título + botão stats
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: collapsed
                                  // ── Colapsado: título simples ───
                                  ? Text(
                                      'Meus Produtos',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600),
                                    )
                                  // ── Expandido: saudação + contagem
                                  : FadeTransition(
                                      opacity: _headerFade,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(saudacao,
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(
                                            produtos.isEmpty
                                                ? 'Nenhum produto'
                                                : '${produtos.length} produto${produtos.length > 1 ? 's' : ''} ativo${produtos.length > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.3),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            // ── Único botão de stats ─────────────
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EstatisticasPage(produtos: produtos),
                                ),
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1),
                                ),
                                child: const Icon(Icons.bar_chart_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),

                        // Cards de receita/lucro (somem ao colapsar)
                        if (!collapsed) ...[
                          const Spacer(),
                          FadeTransition(
                            opacity: _headerFade,
                            child: Row(children: [
                              _headerStatCard(
                                label: 'Receita total',
                                value: 'R\$ ${receita.toStringAsFixed(2)}',
                                icon: Icons.arrow_upward_rounded,
                                iconColor: const Color(0xFF86EFAC),
                              ),
                              const SizedBox(width: 10),
                              _headerStatCard(
                                label: 'Lucro líquido',
                                value: 'R\$ ${lucro.toStringAsFixed(2)}',
                                icon: Icons.trending_up_rounded,
                                iconColor: const Color(0xFF7DD3FC),
                                sub: '${margem.toStringAsFixed(0)}% margem',
                              ),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? sub,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                if (sub != null)
                  Text(sub,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55), fontSize: 10)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUSCA
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _searchFocused
                    ? _purple.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _searchFocused ? 12 : 6,
                offset: const Offset(0, 3)),
          ],
          border: Border.all(
              color: _searchFocused
                  ? _purple.withOpacity(0.4)
                  : Colors.transparent,
              width: 1.5),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar produto ou categoria...',
            hintStyle: const TextStyle(color: _grey, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(11),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.search_rounded, color: _purple, size: 16),
              ),
            ),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.close_rounded, color: _grey, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // KPI ROW
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildKpiRow(int totalProd, int estoqueTotal, double margem) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        _kpiCard(
          icon: Icons.shopping_bag_outlined,
          iconColor: _purple,
          iconBg: _purpleLight,
          label: 'Produtos',
          value: '$totalProd',
        ),
        const SizedBox(width: 10),
        _kpiCard(
          icon: Icons.inventory_2_outlined,
          iconColor: _blueDark,
          iconBg: const Color(0xFFE0F2FE),
          label: 'Em estoque',
          value: '$estoqueTotal',
        ),
        const SizedBox(width: 10),
        _kpiCard(
          icon: Icons.percent_rounded,
          iconColor: margem >= 30 ? _greenMid : _amber,
          iconBg: margem >= 30 ? _greenLight : _amberLight,
          label: 'Margem',
          value: '${margem.toStringAsFixed(0)}%',
        ),
      ]),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B))),
            Text(label, style: const TextStyle(fontSize: 10, color: _grey)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTROS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildExecutivePanel(
    List<Produto> produtos,
    double receita,
    double lucro,
    double despesa,
    int estoqueTotal,
    double margem,
  ) {
    if (produtos.isEmpty) return const SizedBox.shrink();

    final vendidosTotal = produtos.fold(0, (s, p) => s + p.vendidos);
    final ticketMedio = vendidosTotal == 0 ? 0.0 : receita / vendidosTotal;
    final metaReceita = (despesa * 1.35).clamp(500.0, double.infinity);
    final progressoMeta =
        metaReceita == 0 ? 0.0 : (receita / metaReceita).clamp(0.0, 1.0);
    final lucroProjetado = lucro * 1.18;
    final produtosCriticos =
        produtos.where((p) => p.estoque <= 3 || p.lucroUnitario <= 0).toList();
    final produtoCampeao = [...produtos]
      ..sort((a, b) => b.lucroTotal.compareTo(a.lucroTotal));
    final score = _scoreOperacional(produtos, margem, lucro, estoqueTotal);
    final scoreColor = score >= 80
        ? _greenMid
        : score >= 55
            ? _purple
            : score >= 35
                ? _amber
                : _redMid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: scoreColor, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Central financeira',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B))),
                    Text(_diagnosticoExecutivo(score, produtosCriticos.length),
                        style: const TextStyle(fontSize: 11, color: _grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$score',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: scoreColor)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _executiveMetric(
                'Ticket médio',
                'R\$ ${ticketMedio.toStringAsFixed(2)}',
                Icons.receipt_long_rounded,
                _purple,
                _purpleLight,
              ),
              const SizedBox(width: 8),
              _executiveMetric(
                'Lucro previsto',
                'R\$ ${lucroProjetado.toStringAsFixed(2)}',
                Icons.query_stats_rounded,
                lucroProjetado >= 0 ? _greenMid : _redMid,
                lucroProjetado >= 0 ? _greenLight : _redLight,
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _greyLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Meta de receita',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1B4B))),
                      Text(
                          'R\$ ${receita.toStringAsFixed(0)} / R\$ ${metaReceita.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _purple)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressoMeta,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation(
                          progressoMeta >= 0.85 ? _greenMid : _purple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _nextAction(
              produtosCriticos,
              produtoCampeao.isEmpty ? null : produtoCampeao.first,
            ),
          ],
        ),
      ),
    );
  }

  Widget _executiveMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: color.withOpacity(0.75),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _nextAction(List<Produto> criticos, Produto? campeao) {
    final temCritico = criticos.isNotEmpty;
    final titulo = temCritico
        ? '${criticos.length} produto${criticos.length > 1 ? 's' : ''} pedem atenção'
        : campeao == null
            ? 'Pronto para vender'
            : 'Aposte em ${campeao.nome}';
    final desc = temCritico
        ? 'Revise estoque baixo, margem negativa ou produtos parados antes de crescer.'
        : campeao == null
            ? 'Cadastre produtos e registre vendas para receber recomendações.'
            : 'É o item que mais contribui para o lucro. Use estoque e preço a favor dele.';
    final color = temCritico ? _amber : _greenMid;
    final bg = temCritico ? _amberLight : _greenLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
              temCritico
                  ? Icons.priority_high_rounded
                  : Icons.trending_up_rounded,
              color: color,
              size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(desc,
                  style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.82),
                      height: 1.35)),
            ],
          ),
        ),
      ]),
    );
  }

  int _scoreOperacional(
      List<Produto> produtos, double margem, double lucro, int estoqueTotal) {
    var score = 0;
    if (lucro > 0) score += 25;
    if (margem >= 50) {
      score += 25;
    } else if (margem >= 30) {
      score += 18;
    } else if (margem >= 15) {
      score += 10;
    }
    if (estoqueTotal > 0) score += 18;
    if (produtos.length >= 5) {
      score += 17;
    } else if (produtos.length >= 3) {
      score += 12;
    } else {
      score += 6;
    }
    final criticos =
        produtos.where((p) => p.estoque <= 3 || p.lucroUnitario <= 0).length;
    score -= criticos * 6;
    return score.clamp(0, 100);
  }

  String _diagnosticoExecutivo(int score, int criticos) {
    if (criticos > 0) return 'Resolva riscos operacionais antes de acelerar.';
    if (score >= 80) return 'Operação saudável e pronta para escalar.';
    if (score >= 55) return 'Boa base, com espaço para margem e giro.';
    return 'Foque em margem, estoque e mix de produtos.';
  }

  Widget _buildFilterRow(List<String> categorias) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categorias[i];
                final sel = (_filterCategoria ?? 'Todas') == c;
                return GestureDetector(
                  onTap: () => setState(
                      () => _filterCategoria = c == 'Todas' ? null : c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? _purple : _white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _purple : _greyLight, width: 1.2),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: _purple.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ]
                          : null,
                    ),
                    child: Text(c,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: sel ? _white : _grey)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          offset: const Offset(0, 40),
          onSelected: (v) => setState(() => _sort = v),
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: _sort != 'Mais vendidos' ? _purple : _white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _sort != 'Mais vendidos' ? _purple : _greyLight,
                  width: 1.2),
            ),
            child: Icon(Icons.tune_rounded,
                size: 16, color: _sort != 'Mais vendidos' ? _white : _grey),
          ),
          itemBuilder: (_) => [
            _sortItem('Mais vendidos', Icons.trending_up_rounded),
            _sortItem('Maior lucro', Icons.attach_money_rounded),
            _sortItem('Maior margem', Icons.percent_rounded),
            _sortItem('A - Z', Icons.sort_by_alpha_rounded),
          ],
        ),
      ]),
    );
  }

  PopupMenuItem<String> _sortItem(String value, IconData icon) {
    final sel = _sort == value;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: sel ? _purpleLight : _bg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: sel ? _purple : _grey),
        ),
        const SizedBox(width: 10),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: sel ? _purple : Colors.black87)),
        if (sel) ...[
          const Spacer(),
          const Icon(Icons.check_rounded, size: 15, color: _purple),
        ]
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRODUTO CARD
  // ═══════════════════════════════════════════════════════════════════════
  Widget _produtoCard(Produto p, int idx) {
    final lucroUnit = p.precoVenda - p.precoCompra;
    final margem = p.precoVenda == 0 ? 0.0 : (lucroUnit / p.precoVenda * 100);
    final Color margemColor = margem >= 50
        ? _greenMid
        : margem >= 30
            ? _amber
            : _redMid;
    final Color margemBg = margem >= 50
        ? _greenLight
        : margem >= 30
            ? _amberLight
            : _redLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalhesProdutoPage(
                produto: p,
                atualizar: () => repo.atualizar(idx, p),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Topo: avatar + nome + badge estoque ──────────
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_purple, _purpleMid],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                          p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: _white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nome,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1B4B))),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _purpleLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p.categoria,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _purple,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  _estoqueBadge(p.estoque),
                ]),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF0EEF8)),
                const SizedBox(height: 12),

                // ── Métricas ──────────────────────────────────────
                Row(children: [
                  _metrica('Preço', 'R\$ ${p.precoVenda.toStringAsFixed(2)}',
                      const Color(0xFF1E1B4B)),
                  _metricaDivider(),
                  _metrica('Custo', 'R\$ ${p.precoCompra.toStringAsFixed(2)}',
                      _grey),
                  _metricaDivider(),
                  _metrica(
                      'Lucro total',
                      'R\$ ${p.lucroTotal.toStringAsFixed(2)}',
                      lucroUnit >= 0 ? _greenMid : _redMid),
                  _metricaDivider(),
                  _metrica('Vendidos', '${p.vendidos}', _purple),
                ]),

                const SizedBox(height: 12),

                // ── Barra de margem ───────────────────────────────
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (margem.clamp(0, 100)) / 100,
                        minHeight: 5,
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(margemColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: margemBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${margem.toStringAsFixed(0)}% margem',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: margemColor),
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Botões ────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: p.estoque > 0
                          ? () async {
                              p.estoque--;
                              p.vendidos++;
                              await vendaRepo.registrar(
                                  produto: p, quantidade: 1);
                              await repo.atualizar(idx, p);
                            }
                          : null,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: p.estoque > 0
                              ? const LinearGradient(
                                  colors: [_purple, _purpleMid],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color:
                              p.estoque == 0 ? const Color(0xFFF1EEF8) : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: p.estoque > 0
                              ? [
                                  BoxShadow(
                                      color: _purple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_checkout_rounded,
                                size: 15,
                                color: p.estoque > 0 ? _white : _grey),
                            const SizedBox(width: 6),
                            Text(
                                p.estoque > 0
                                    ? 'Registrar venda'
                                    : 'Sem estoque',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: p.estoque > 0 ? _white : _grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NovoProdutoPage(produto: p),
                        ),
                      );
                      await repo.atualizar(idx, p);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _purpleLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: _purple, size: 17),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _estoqueBadge(int estoque) {
    Color bg, fg;
    IconData ico;
    String label;
    if (estoque == 0) {
      bg = _redLight;
      fg = _red;
      ico = Icons.warning_amber_rounded;
      label = 'Sem estoque';
    } else if (estoque <= 3) {
      bg = _amberLight;
      fg = _amber;
      ico = Icons.inventory_2_outlined;
      label = '$estoque un.';
    } else {
      bg = _greenLight;
      fg = _green;
      ico = Icons.inventory_2_outlined;
      label = '$estoque un.';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ico, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }

  Widget _metrica(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: _grey)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _metricaDivider() => Container(
      width: 1,
      height: 24,
      color: const Color(0xFFF0EEF8),
      margin: const EdgeInsets.symmetric(horizontal: 6));

  // ═══════════════════════════════════════════════════════════════════════
  // FAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _fab() {
    return FloatingActionButton.extended(
      backgroundColor: _purple,
      foregroundColor: _white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(Icons.add_rounded, size: 16),
      ),
      label: const Text('Novo produto',
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.2)),
      onPressed: () async {
        final res = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NovoProdutoPage()),
        );
        if (res is Produto) {
          await repo.adicionar(res);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _emptyState(bool semProdutos) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: _purpleLight, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.inbox_rounded, size: 40, color: _purple),
            ),
            const SizedBox(height: 16),
            Text(
              semProdutos
                  ? 'Nenhum produto cadastrado'
                  : 'Nenhum resultado encontrado',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 8),
            Text(
              semProdutos
                  ? 'Toque em "Novo produto" para começar'
                  : 'Tente buscar com outros termos',
              style: const TextStyle(fontSize: 13, color: _grey),
              textAlign: TextAlign.center,
            ),
            if (semProdutos) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NovoProdutoPage()),
                  );
                  if (res is Produto) {
                    await repo.adicionar(res);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: _white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Cadastrar produto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
