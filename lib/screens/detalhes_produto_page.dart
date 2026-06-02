import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/produto.dart';
import 'novo_produto_page.dart';

class DetalhesProdutoPage extends StatefulWidget {
  final Produto produto;
  final VoidCallback atualizar;

  const DetalhesProdutoPage({
    super.key,
    required this.produto,
    required this.atualizar,
  });

  @override
  State<DetalhesProdutoPage> createState() => _DetalhesProdutoPageState();
}

class _DetalhesProdutoPageState extends State<DetalhesProdutoPage>
    with TickerProviderStateMixin {

  // ── Paleta ────────────────────────────────────────────────────────────────
  static const _purple      = Color(0xFF6A5AE0);
  static const _purpleMid   = Color(0xFF8B5CF6);
  static const _purpleLight = Color(0xFFEDE9FB);
  static const _purpleDark  = Color(0xFF3C3489);
  static const _greenMid    = Color(0xFF639922);
  static const _greenLight  = Color(0xFFEAF3DE);
  static const _green       = Color(0xFF3B6D11);
  static const _redMid      = Color(0xFFE24B4A);
  static const _redLight    = Color(0xFFFCEBEB);
  static const _red         = Color(0xFFA32D2D);
  static const _amber       = Color(0xFFBA7517);
  static const _amberLight  = Color(0xFFFAEEDA);
  static const _amberMid    = Color(0xFFEF9F27);
  static const _bg          = Color(0xFFF7F6FB);
  static const _grey        = Color(0xFF888780);
  static const _border      = Color(0xFFE4E2F5);

  late TabController _tabs;
  int _qtdVender = 1;
  bool _vendendo = false;

  Produto get p => widget.produto;

  // ── Derivados ─────────────────────────────────────────────────────────────
  double get _lucroUnit  => p.precoVenda - p.precoCompra;
  double get _margem     => p.precoVenda == 0 ? 0 : (_lucroUnit / p.precoVenda * 100);
  double get _lucroTotal => p.lucroTotal;
  double get _receitaTotal => p.precoVenda * p.vendidos;
  double get _custoTotal   => p.precoCompra * p.vendidos;
  double get _giroEstoque  => (p.vendidos + p.estoque) == 0
      ? 0
      : p.vendidos / (p.vendidos + p.estoque) * 100;

  int get _healthScore {
    int s = 0;
    if (_margem >= 50) s += 35;
    else if (_margem >= 30) s += 20;
    else s += 5;
    if (_lucroTotal > 0) s += 25;
    if (p.estoque > 5) s += 20;
    else if (p.estoque > 0) s += 10;
    if (_giroEstoque >= 60) s += 20;
    else if (_giroEstoque >= 30) s += 10;
    return s.clamp(0, 100);
  }

  Color get _healthColor {
    final s = _healthScore;
    if (s >= 70) return _greenMid;
    if (s >= 45) return _purple;
    if (s >= 25) return _amberMid;
    return _redMid;
  }

  String get _healthLabel {
    final s = _healthScore;
    if (s >= 70) return 'Excelente';
    if (s >= 45) return 'Bom';
    if (s >= 25) return 'Regular';
    return 'Atenção';
  }

  // ── Simulação de histórico de vendas (7 dias) ─────────────────────────────
  List<double> get _historicoVendas {
    if (p.vendidos == 0) return List.filled(7, 0);
    final base = p.vendidos / 7;
    final seed = p.nome.codeUnits.fold(0, (a, b) => a + b);
    return List.generate(7, (i) {
      final fator = 0.4 + ((seed * (i + 3)) % 120) / 100;
      return (base * fator).clamp(0, p.vendidos.toDouble());
    });
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Vender ────────────────────────────────────────────────────────────────
  void _vender() async {
    if (p.estoque <= 0) {
      _snack('Sem estoque disponível', erro: true);
      return;
    }
    if (_qtdVender > p.estoque) {
      _snack('Quantidade maior que o estoque disponível', erro: true);
      return;
    }

    setState(() => _vendendo = true);
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      p.estoque -= _qtdVender;
      p.vendidos += _qtdVender;
      _vendendo = false;
      _qtdVender = 1;
    });
    widget.atualizar();

    if (p.estoque == 0) {
      _snack('⚠️ Estoque zerado! Reponha o produto.', erro: true);
    } else if (p.estoque <= 3) {
      _snack('⚠️ Estoque baixo: apenas ${p.estoque} unidade(s)', erro: false, cor: _amberMid);
    } else {
      _snack('✅ ${_qtdVender} venda(s) registrada(s) com sucesso!');
    }
  }

  void _snack(String msg, {bool erro = false, Color? cor}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: cor ?? (erro ? _redMid : _purple),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(),
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverToBoxAdapter(child: _buildTabBar()),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _tabVisaoGeral(),
            _tabVender(),
            _tabAnalise(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SLIVER HEADER
  // ═══════════════════════════════════════════════════════════════════════
  SliverAppBar _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _purple,
      foregroundColor: Colors.white,
      surfaceTintColor: _purple,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NovoProdutoPage(produto: p)),
              );
              widget.atualizar();
              setState(() {});
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4C3BBF), Color(0xFF6A5AE0), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -30, right: -30,
                child: Container(width: 140, height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05)))),
              Positioned(bottom: -10, left: -10,
                child: Container(width: 90, height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05)))),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + nome
                      Row(children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(
                              p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nome,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(p.categoria,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.white70)),
                                ),
                                const SizedBox(width: 8),
                                _estoqueBadgeHeader(),
                              ]),
                            ],
                          ),
                        ),
                        // Health score mini
                        Column(
                          children: [
                            SizedBox(
                              width: 44, height: 44,
                              child: CustomPaint(
                                painter: _ScoreRingPainter(
                                  value: _healthScore / 100,
                                  color: Colors.white,
                                  bgColor: Colors.white.withOpacity(0.2),
                                  strokeWidth: 4,
                                ),
                                child: Center(
                                  child: Text('$_healthScore',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_healthLabel,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white60)),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // Stat pills rápidas
                      Row(children: [
                        _headerPill('Lucro/un.',
                            'R\$ ${_lucroUnit.toStringAsFixed(2)}'),
                        const SizedBox(width: 8),
                        _headerPill('Margem',
                            '${_margem.toStringAsFixed(0)}%'),
                        const SizedBox(width: 8),
                        _headerPill('Vendidos', '${p.vendidos}'),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _estoqueBadgeHeader() {
    final est = p.estoque;
    Color bg, fg;
    String label;
    if (est == 0) { bg = _redLight; fg = _red; label = 'Sem estoque'; }
    else if (est <= 3) { bg = _amberLight; fg = _amber; label = '$est un.'; }
    else { bg = _greenLight; fg = _green; label = '$est un.'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        isScrollable: false,
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _purple, width: 2.5),
          ),
        ),
        labelColor: _purple,
        unselectedLabelColor: _grey,
        dividerColor: _border,
        tabs: const [
          Tab(text: 'Visão Geral'),
          Tab(text: 'Vender'),
          Tab(text: 'Análise'),
        ],
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ABA 1 – VISÃO GERAL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _tabVisaoGeral() {
    return Builder(builder: (context) {
      return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card principal lucro total
          _gradientCard(),
          const SizedBox(height: 16),
          // Grid 2x2
          _secaoLabel('Indicadores'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _infoCard('Preço de venda',
                  'R\$ ${p.precoVenda.toStringAsFixed(2)}',
                  Icons.arrow_upward_rounded, _greenMid, _greenLight),
              _infoCard('Custo de compra',
                  'R\$ ${p.precoCompra.toStringAsFixed(2)}',
                  Icons.arrow_downward_rounded, _redMid, _redLight),
              _infoCard('Em estoque', '${p.estoque} un.',
                  Icons.inventory_2_outlined,
                  p.estoque == 0 ? _redMid : p.estoque <= 3 ? _amberMid : _purple,
                  p.estoque == 0 ? _redLight : p.estoque <= 3 ? _amberLight : _purpleLight),
              _infoCard('Total vendido', '${p.vendidos} un.',
                  Icons.shopping_cart_checkout_rounded, _purple, _purpleLight),
            ],
          ),
          const SizedBox(height: 16),
          _secaoLabel('Giro de estoque'),
          const SizedBox(height: 10),
          _giroCard(),
          const SizedBox(height: 16),
          _secaoLabel('Score do produto'),
          const SizedBox(height: 10),
          _scoreCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
    });
  }

  Widget _gradientCard() {
    final isLucro = _lucroTotal >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLucro
              ? [const Color(0xFF4C3BBF), _purple, _purpleMid]
              : [_redMid, const Color(0xFFC93A39)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (isLucro ? _purple : _redMid).withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Resultado financeiro',
                  style: TextStyle(fontSize: 11, color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            Icon(isLucro ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: Colors.white70, size: 20),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _gradientStat('Lucro total',
                'R\$ ${_lucroTotal.toStringAsFixed(2)}'),
            _gradientDivider(),
            _gradientStat('Receita total',
                'R\$ ${_receitaTotal.toStringAsFixed(2)}'),
            _gradientDivider(),
            _gradientStat('Custo total',
                'R\$ ${_custoTotal.toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_margem.clamp(0, 100)) / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _margem >= 50 ? '🏆 Margem excelente!'
            : _margem >= 30 ? '✅ Margem saudável'
            : _lucroTotal > 0 ? '⚠️ Margem baixa'
            : '❌ Produto no prejuízo',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _gradientStat(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _gradientDivider() => Container(
      width: 1, height: 30, color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _infoCard(String label, String value, IconData icon,
      Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: bg,
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: fg, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 10, color: _grey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: fg)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _giroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Taxa de giro',
                      style: TextStyle(fontSize: 12, color: _grey)),
                  const SizedBox(height: 4),
                  Text('${_giroEstoque.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _giroEstoque >= 60 ? _greenMid
                              : _giroEstoque >= 30 ? _amberMid : _redMid)),
                  Text(
                    _giroEstoque >= 60 ? 'Alto giro — produto popular'
                    : _giroEstoque >= 30 ? 'Giro médio'
                    : 'Baixo giro — revise estratégia',
                    style: const TextStyle(fontSize: 11, color: _grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _giroStat('Vendidos', '${p.vendidos}'),
                const SizedBox(height: 6),
                _giroStat('Estoque', '${p.estoque}'),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: _giroEstoque / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                _giroEstoque >= 60 ? _greenMid
                : _giroEstoque >= 30 ? _amberMid : _redMid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _giroStat(String label, String val) => Row(
    children: [
      Text('$label: ', style: const TextStyle(fontSize: 11, color: _grey)),
      Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
          color: _purpleDark)),
    ],
  );

  Widget _scoreCard() {
    final indicadores = [
      _ScoreItem('Margem (${_margem.toStringAsFixed(0)}%)',
          _margem >= 50 ? 'Excelente' : _margem >= 30 ? 'Boa' : 'Fraca',
          _margem >= 50 ? _greenMid : _margem >= 30 ? _amberMid : _redMid),
      _ScoreItem('Resultado financeiro',
          _lucroTotal >= 0 ? 'Positivo' : 'Negativo',
          _lucroTotal >= 0 ? _greenMid : _redMid),
      _ScoreItem('Nível de estoque (${p.estoque})',
          p.estoque > 5 ? 'Adequado' : p.estoque > 0 ? 'Baixo' : 'Zerado',
          p.estoque > 5 ? _greenMid : p.estoque > 0 ? _amberMid : _redMid),
      _ScoreItem('Giro (${_giroEstoque.toStringAsFixed(0)}%)',
          _giroEstoque >= 60 ? 'Alto' : _giroEstoque >= 30 ? 'Médio' : 'Baixo',
          _giroEstoque >= 60 ? _greenMid : _giroEstoque >= 30 ? _amberMid : _redMid),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(children: [
            SizedBox(
              width: 72, height: 72,
              child: CustomPaint(
                painter: _ScoreRingPainter(
                  value: _healthScore / 100,
                  color: _healthColor,
                  bgColor: Colors.grey.withOpacity(0.1),
                  strokeWidth: 8,
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$_healthScore',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold, color: _healthColor)),
                    const Text('score',
                        style: TextStyle(fontSize: 9, color: _grey)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_healthLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _healthScore >= 70
                        ? 'Produto com ótima performance!'
                        : _healthScore >= 45
                            ? 'Performance boa, há espaço para melhorar.'
                            : 'Produto precisa de atenção.',
                    style: const TextStyle(fontSize: 12, color: _grey, height: 1.4),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ...indicadores.map((ind) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: ind.color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(ind.label,
                      style: const TextStyle(fontSize: 12, color: _grey))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ind.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(ind.grade,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ind.color)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ABA 2 – VENDER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _tabVender() {
    final lucroVenda = _lucroUnit * _qtdVender;
    final receitaVenda = p.precoVenda * _qtdVender;

    return Builder(builder: (context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alerta estoque
          if (p.estoque == 0) _alertaBanner(
            '❌ Sem estoque disponível',
            'Não é possível registrar vendas. Atualize o estoque do produto.',
            _redLight, _red,
          ) else if (p.estoque <= 3) _alertaBanner(
            '⚠️ Estoque crítico: ${p.estoque} unidade(s)',
            'Considere repor o estoque em breve.',
            _amberLight, _amber,
          ),

          const SizedBox(height: 16),
          _secaoLabel('Quantidade a vender'),
          const SizedBox(height: 10),

          // Stepper de quantidade
          _card(Column(
            children: [
              Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: _purple, size: 19),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantidade',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Unidades para registrar',
                          style: TextStyle(fontSize: 11, color: _grey)),
                    ]),
                ),
              ]),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _stepBtn(Icons.remove_rounded, () {
                  if (_qtdVender > 1) setState(() => _qtdVender--);
                }),
                const SizedBox(width: 20),
                Container(
                  width: 90, height: 56,
                  decoration: BoxDecoration(
                    color: _purpleLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Center(
                    child: Text('$_qtdVender',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _purpleDark)),
                  ),
                ),
                const SizedBox(width: 20),
                _stepBtn(Icons.add_rounded, () {
                  if (_qtdVender < p.estoque) {
                    setState(() => _qtdVender++);
                  }
                }, primary: true),
              ]),
              const SizedBox(height: 12),
              Text(
                p.estoque == 0
                    ? 'Sem estoque disponível'
                    : 'Disponível: ${p.estoque} unidade(s)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: p.estoque == 0 ? _red : _purple),
              ),
            ],
          )),

          const SizedBox(height: 16),
          _secaoLabel('Resumo da venda'),
          const SizedBox(height: 10),

          // Preview da venda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C3BBF), _purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: _purple.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              Row(children: [
                _vendaStat('Receita', 'R\$ ${receitaVenda.toStringAsFixed(2)}'),
                _vendaDivider(),
                _vendaStat('Lucro', '+ R\$ ${lucroVenda.toStringAsFixed(2)}'),
                _vendaDivider(),
                _vendaStat('Margem', '${_margem.toStringAsFixed(0)}%'),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Estoque após venda: ',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text('${(p.estoque - _qtdVender).clamp(0, 999)} un.',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Botão registrar
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: p.estoque > 0 && !_vendendo ? _vender : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _purple.withOpacity(0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _vendendo
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        p.estoque == 0
                            ? 'Sem estoque'
                            : 'Registrar $_qtdVender venda(s)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
            ),
          ),

          const SizedBox(height: 16),

          // Histórico rápido
          _secaoLabel('Histórico de performance'),
          const SizedBox(height: 10),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vendas recentes (estimativa)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Baseado no volume total de ${p.vendidos} vendas',
                  style: const TextStyle(fontSize: 11, color: _grey)),
              const SizedBox(height: 16),
              SizedBox(height: 120, child: _miniBarChart()),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom']
                    .map((d) => Text(d,
                        style: const TextStyle(fontSize: 9, color: _grey)))
                    .toList()),
            ],
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
    });
  }

  Widget _miniBarChart() {
    final hist = _historicoVendas;
    final maxY = hist.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) {
      return const Center(child: Text('Sem vendas registradas',
          style: TextStyle(color: _grey, fontSize: 12)));
    }
    return BarChart(BarChartData(
      maxY: maxY * 1.3,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: List.generate(hist.length, (i) => BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(
          toY: hist[i],
          width: 22,
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            colors: [_purple.withOpacity(0.7), _purpleMid],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        )],
      )),
    ));
  }

  Widget _vendaStat(String label, String value) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis),
    ]),
  );

  Widget _vendaDivider() => Container(width: 1, height: 30,
      color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8));

  // ═══════════════════════════════════════════════════════════════════════
  // ABA 3 – ANÁLISE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _tabAnalise() {
    final alertas = <_AlertaItem>[];
    final positivos = <_AlertaItem>[];

    // Gerar alertas dinâmicos
    if (p.estoque == 0) {
      alertas.add(_AlertaItem(Icons.warning_rounded,
          'Estoque zerado',
          'Produto sem estoque. Reponha imediatamente para não perder vendas.',
          _redLight, _red));
    } else if (p.estoque <= 3) {
      alertas.add(_AlertaItem(Icons.inventory_2_outlined,
          'Estoque crítico (${p.estoque} un.)',
          'Nível de estoque muito baixo. Considere repor em breve.',
          _amberLight, _amber));
    }

    if (_margem < 20) {
      alertas.add(_AlertaItem(Icons.trending_down_rounded,
          'Margem muito baixa (${_margem.toStringAsFixed(0)}%)',
          'Margem abaixo de 20%. Reavalie o preço de venda ou negocie o custo.',
          _redLight, _red));
    }

    if (_giroEstoque < 30 && p.estoque > 0) {
      alertas.add(_AlertaItem(Icons.loop_rounded,
          'Baixo giro de estoque',
          'Menos de 30% do estoque foi vendido. Considere promoções.',
          _amberLight, _amber));
    }

    if (_margem >= 50) {
      positivos.add(_AlertaItem(Icons.star_rounded,
          'Margem excelente (${_margem.toStringAsFixed(0)}%)',
          'Acima de 50% de margem! Continue priorizando este produto.',
          _greenLight, _green));
    } else if (_margem >= 30) {
      positivos.add(_AlertaItem(Icons.check_circle_outline_rounded,
          'Margem saudável (${_margem.toStringAsFixed(0)}%)',
          'Margem dentro do esperado para o varejo.',
          _greenLight, _green));
    }

    if (p.vendidos > 10) {
      positivos.add(_AlertaItem(Icons.trending_up_rounded,
          'Bom volume de vendas (${p.vendidos} un.)',
          'Produto com boa tração de mercado.',
          _greenLight, _green));
    }

    if (p.estoque > 10) {
      positivos.add(_AlertaItem(Icons.inventory_2_outlined,
          'Estoque confortável',
          'Estoque adequado para sustentar demanda.',
          _purpleLight, _purple));
    }

    // Simulação de precificação
    final precoSugerido25 = p.precoCompra * 1.25;
    final precoSugerido50 = p.precoCompra * 1.50;
    final precoSugerido100 = p.precoCompra * 2.00;

    return Builder(builder: (context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulador de preço
          _secaoLabel('Simulador de precificação'),
          const SizedBox(height: 10),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sugestões de preço',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Com base no custo de R\$ ${p.precoCompra.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: _grey)),
              const SizedBox(height: 14),
              _precoSugestao('Margem 25%', precoSugerido25, 25, _amberMid, _amberLight),
              const SizedBox(height: 8),
              _precoSugestao('Margem 50%', precoSugerido50, 33, _purple, _purpleLight),
              const SizedBox(height: 8),
              _precoSugestao('Margem 100%', precoSugerido100, 50, _greenMid, _greenLight,
                  destaque: true),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: _grey),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  'Preço atual: R\$ ${p.precoVenda.toStringAsFixed(2)} (${_margem.toStringAsFixed(0)}% de margem)',
                  style: const TextStyle(fontSize: 11, color: _grey),
                )),
              ]),
            ],
          )),

          const SizedBox(height: 16),

          if (alertas.isNotEmpty) ...[
            _secaoLabel('Pontos de atenção'),
            const SizedBox(height: 10),
            ...alertas.map(_alertaCard),
            const SizedBox(height: 8),
          ],

          if (positivos.isNotEmpty) ...[
            _secaoLabel('Destaques positivos'),
            const SizedBox(height: 10),
            ...positivos.map(_alertaCard),
          ],

          if (alertas.isEmpty && positivos.isEmpty)
            _alertaBanner(
              '💡 Sem dados suficientes para análise',
              'Registre vendas para obter insights detalhados.',
              _purpleLight, _purple,
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
    });
  }

  Widget _precoSugestao(String label, double preco, double margemReal,
      Color cor, Color bg, {bool destaque = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: destaque ? cor.withOpacity(0.08) : bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: destaque ? cor.withOpacity(0.4) : cor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 12, color: cor,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal))),
        Text('R\$ ${preco.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cor)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6)),
          child: Text('${margemReal.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.bold, color: cor)),
        ),
      ]),
    );
  }

  Widget _alertaCard(_AlertaItem a) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: a.bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: a.cor.withOpacity(0.3)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
            color: a.cor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(a.icon, size: 17, color: a.cor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.titulo,
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.bold, color: a.cor)),
          const SizedBox(height: 3),
          Text(a.desc,
              style: TextStyle(fontSize: 12,
                  color: a.cor.withOpacity(0.8), height: 1.4)),
        ]),
      ),
    ]),
  );

  Widget _alertaBanner(String titulo, String desc, Color bg, Color cor) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, color: cor, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.bold, color: cor)),
            Text(desc, style: TextStyle(fontSize: 12,
                color: cor.withOpacity(0.8), height: 1.4)),
          ],
        )),
      ]),
    );

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _secaoLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: _grey, letterSpacing: 0.6),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _stepBtn(IconData icon, VoidCallback onTap,
      {bool primary = false}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: primary ? _purple : _purpleLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: primary ? [BoxShadow(
              color: _purple.withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Icon(icon,
            color: primary ? Colors.white : _purple, size: 22),
      ),
    );
}

// ── Data classes ──────────────────────────────────────────────────────────────
class _ScoreItem {
  final String label, grade;
  final Color color;
  _ScoreItem(this.label, this.grade, this.color);
}

class _AlertaItem {
  final IconData icon;
  final String titulo, desc;
  final Color bg, cor;
  _AlertaItem(this.icon, this.titulo, this.desc, this.bg, this.cor);
}

// ── CustomPainter para o anel de score (texto fica sempre visível no centro) ──
class _ScoreRingPainter extends CustomPainter {
  final double value;      // 0.0 – 1.0
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _ScoreRingPainter({
    required this.value,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Trilha de fundo
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Arco de progresso
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -1.5708, // -π/2 (topo)
      6.2832 * value, // 2π * value
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.value != value || old.color != color;
}