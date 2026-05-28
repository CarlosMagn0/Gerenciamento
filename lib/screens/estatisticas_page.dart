import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/produto.dart';

class EstatisticasPage extends StatefulWidget {
  final List<Produto> produtos;

  const EstatisticasPage({super.key, required this.produtos});

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ─── Paleta ───────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF534AB7);
  static const _purpleLight = Color(0xFFEDE9FB);
  static const _green = Color(0xFF3B6D11);
  static const _greenLight = Color(0xFFEAF3DE);
  static const _greenMid = Color(0xFF639922);
  static const _red = Color(0xFFA32D2D);
  static const _redLight = Color(0xFFFCEBEB);
  static const _redMid = Color(0xFFE24B4A);
  static const _amber = Color(0xFFBA7517);
  static const _amberLight = Color(0xFFFAEEDA);
  static const _amberMid = Color(0xFFEF9F27);
  static const _bg = Color(0xFFF7F6FB);
  static const _grey = Color(0xFF888780);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── Cálculos ─────────────────────────────────────────────────────────────
  double get receitaTotal =>
      widget.produtos.fold(0, (s, p) => s + p.precoVenda * p.vendidos);

  double get despesaTotal =>
      widget.produtos.fold(0, (s, p) => s + p.precoCompra * p.vendidos);

  double get lucroTotal =>
      widget.produtos.fold(0, (s, p) => s + p.lucroTotal);

  double get margemPct =>
      receitaTotal == 0 ? 0 : (lucroTotal / receitaTotal) * 100;

  Map<String, double> get despesasPorCategoria {
    final m = <String, double>{};
    for (var p in widget.produtos) {
      m[p.categoria] = (m[p.categoria] ?? 0) + p.precoCompra * p.vendidos;
    }
    return m;
  }

  Map<String, double> get receitasPorProduto {
    final m = <String, double>{};
    for (var p in widget.produtos) {
      m[p.nome] = (m[p.nome] ?? 0) + p.precoVenda * p.vendidos;
    }
    return m;
  }

  Map<String, int> get produtosVendidos {
    final m = <String, int>{};
    for (var p in widget.produtos) {
      m[p.nome] = (m[p.nome] ?? 0) + p.vendidos;
    }
    return m;
  }

  Map<String, double> get despesasPorConta => {
        'Fornecedores': despesaTotal * 0.6,
        'Impostos': despesaTotal * 0.25,
        'Outros': despesaTotal * 0.15,
      };

  /// Score de saúde 0–100 baseado em 4 indicadores
  int get healthScore {
    int score = 0;
    // Margem: excelente ≥50%, boa ≥30%, fraca <30%
    if (margemPct >= 50) score += 35;
    else if (margemPct >= 30) score += 20;
    else score += 5;
    // Lucro positivo
    if (lucroTotal > 0) score += 25;
    // Diversificação: ≥3 produtos = ótimo, 2 = médio, 1 = fraco
    final np = widget.produtos.length;
    if (np >= 3) score += 25;
    else if (np == 2) score += 15;
    else score += 5;
    // Carga tributária (impostos / despesa): <20% ok, <30% médio, ≥30% ruim
    final cargaTrib = despesaTotal == 0 ? 0 : (despesaTotal * 0.25) / despesaTotal;
    if (cargaTrib < 0.20) score += 15;
    else if (cargaTrib < 0.30) score += 8;
    else score += 2;
    return score.clamp(0, 100);
  }

  String get healthLabel {
    final s = healthScore;
    if (s >= 80) return 'Excelente';
    if (s >= 60) return 'Bom desempenho';
    if (s >= 40) return 'Regular';
    return 'Atenção necessária';
  }

  Color get healthColor {
    final s = healthScore;
    if (s >= 80) return _greenMid;
    if (s >= 60) return _purple;
    if (s >= 40) return _amberMid;
    return _redMid;
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          _buildKpiStrip(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _tabVisaoGeral(),
                _tabProdutos(),
                _tabAlertas(),
                _tabSaude(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Financeiro',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _purpleLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Maio 2025',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _purple)),
        ),
      ],
    );
  }

  // ─── TabBar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Visão Geral',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Produtos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Alertas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Saúde',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Strip (fixo em todas as abas) ───────────────────────────────────
  Widget _buildKpiStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          _kpiMini('Receita', 'R\$ ${receitaTotal.toStringAsFixed(2)}',
              Icons.arrow_upward_rounded, _greenLight, _green),
          const SizedBox(width: 8),
          _kpiMini('Despesas', 'R\$ ${despesaTotal.toStringAsFixed(2)}',
              Icons.arrow_downward_rounded, _redLight, _red),
          const SizedBox(width: 8),
          _kpiMiniHighlight('Lucro', 'R\$ ${lucroTotal.toStringAsFixed(2)}',
              '${margemPct.toStringAsFixed(0)}% margem'),
        ],
      ),
    );
  }

  Widget _kpiMini(
      String label, String value, IconData icon, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: fg.withOpacity(0.8))),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _kpiMiniHighlight(String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_purple, Color(0xFF7F77DD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.trending_up_rounded, size: 14, color: Colors.white70),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: Colors.white70)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(sub,
                style: const TextStyle(fontSize: 9, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 1 – VISÃO GERAL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabVisaoGeral() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Composição do resultado'),
          _card(_waterfallChart()),
          const SizedBox(height: 14),
          _sectionLabel('Margem por categoria'),
          _card(_margemBars()),
          const SizedBox(height: 14),
          _sectionLabel('Despesas por tipo'),
          _card(_donutDespesas()),
        ],
      ),
    );
  }

  // Waterfall chart
  Widget _waterfallChart() {
    final bars = [
      _WFBar('Receita', receitaTotal, _greenMid),
      _WFBar('Despesas', despesaTotal, _redMid),
      _WFBar('Lucro', lucroTotal, _purple),
    ];
    final maxY = receitaTotal * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cascata financeira',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Receita → Despesas → Lucro',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, m) => Text(
                      'R\$${v.toInt()}',
                      style: const TextStyle(fontSize: 9, color: _grey),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= bars.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(bars[i].label,
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(bars.length, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: bars[i].value,
                    width: 36,
                    color: bars[i].color,
                    borderRadius: BorderRadius.circular(8),
                    rodStackItems: [],
                  ),
                ]);
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend([
          _LegendItem('Receita', _greenMid),
          _LegendItem('Despesas', _redMid),
          _LegendItem('Lucro', _purple),
        ]),
      ],
    );
  }

  // Barras de margem por categoria
  Widget _margemBars() {
    final cats = despesasPorCategoria.entries.toList();
    if (cats.isEmpty) {
      return const Text('Sem dados', style: TextStyle(color: _grey));
    }
    final colors = [_purple, _greenMid, _amberMid, _redMid];
    return Column(
      children: List.generate(cats.length, (i) {
        final name = cats[i].key;
        final despesa = cats[i].value;
        final receita = receitasPorProduto.entries
            .where((_) => true)
            .fold(0.0, (s, e) => s + e.value);
        final margem = receita == 0
            ? 0.0
            : ((receita - despesa) / receita * 100).clamp(0, 100);
        final color = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('${margem.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: margem / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Donut despesas
  Widget _donutDespesas() {
    final data = despesasPorConta;
    final colors = [_purple, _greenMid, _amberMid];
    final keys = data.keys.toList();
    final vals = data.values.toList();
    final total = vals.fold(0.0, (a, b) => a + b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                centerSpaceRadius: 36,
                sectionsSpace: 3,
                sections: List.generate(keys.length, (i) {
                  return PieChartSectionData(
                    value: vals[i],
                    color: colors[i % colors.length],
                    radius: 44,
                    title: '',
                  );
                }),
              )),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total',
                      style: TextStyle(fontSize: 9, color: _grey)),
                  Text('R\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _purple)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: List.generate(keys.length, (i) {
              final pct = total == 0 ? 0 : (vals[i] / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(keys[i],
                            style: const TextStyle(fontSize: 12))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('R\$ ${vals[i].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _red)),
                        Text('${pct.toStringAsFixed(1)}%',
                            style:
                                const TextStyle(fontSize: 10, color: _grey)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 2 – PRODUTOS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabProdutos() {
    final sorted = produtosVendidos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Receita vs Custo por produto'),
          _card(_receitaVsCustoChart()),
          const SizedBox(height: 14),
          _sectionLabel('Ranking de produtos'),
          ...sorted.map((entry) => _produtoRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _receitaVsCustoChart() {
    final nomes = receitasPorProduto.keys.toList();
    if (nomes.isEmpty) return const Text('Sem dados');

    final maxY = nomes
            .map((n) {
              final receita = receitasPorProduto[n] ?? 0;
              return receita * 1.2;
            })
            .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Receita · Custo · Lucro',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Comparativo por produto',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= nomes.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(nomes[i],
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, m) => Text(
                      'R\$${v.toInt()}',
                      style: const TextStyle(fontSize: 9, color: _grey),
                    ),
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(nomes.length, (i) {
                final nome = nomes[i];
                final p = widget.produtos.firstWhere((e) => e.nome == nome,
                    orElse: () => widget.produtos.first);
                final receita = receitasPorProduto[nome] ?? 0;
                final custo = p.precoCompra * p.vendidos;
                final lucro = p.lucroTotal;
                return BarChartGroupData(
                  x: i,
                  groupVertically: false,
                  barRods: [
                    BarChartRodData(
                        toY: receita,
                        color: _purple,
                        width: 14,
                        borderRadius: BorderRadius.circular(5)),
                    BarChartRodData(
                        toY: custo,
                        color: _redMid,
                        width: 14,
                        borderRadius: BorderRadius.circular(5)),
                    BarChartRodData(
                        toY: lucro,
                        color: _greenMid,
                        width: 14,
                        borderRadius: BorderRadius.circular(5)),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend([
          _LegendItem('Receita', _purple),
          _LegendItem('Custo', _redMid),
          _LegendItem('Lucro', _greenMid),
        ]),
      ],
    );
  }

  Widget _produtoRow(String nome, int vendidos) {
    final p = widget.produtos.firstWhere((e) => e.nome == nome,
        orElse: () => widget.produtos.first);
    final receita = p.precoVenda * vendidos;
    final lucro = p.lucroTotal;
    final margem = receita == 0 ? 0.0 : (lucro / receita * 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _purpleLight,
                child: Text(nome[0].toUpperCase(),
                    style: const TextStyle(
                        color: _purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('$vendidos vendido(s)',
                        style: const TextStyle(fontSize: 11, color: _grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('R\$ ${receita.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _green,
                          fontSize: 14)),
                  Text('Lucro R\$ ${lucro.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 11, color: _purple)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de margem inline
          Row(
            children: [
              const Text('Margem:',
                  style: TextStyle(fontSize: 11, color: _grey)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (margem / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(
                        margem >= 50 ? _greenMid : margem >= 30 ? _amberMid : _redMid),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${margem.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: margem >= 50
                          ? _green
                          : margem >= 30
                              ? _amber
                              : _red)),
            ],
          ),
          const SizedBox(height: 10),
          // Mini tabela
          _miniTabela([
            ['Preço venda', 'R\$ ${p.precoVenda.toStringAsFixed(2)}'],
            ['Custo compra', 'R\$ ${p.precoCompra.toStringAsFixed(2)}'],
            ['Margem bruta', 'R\$ ${lucro.toStringAsFixed(2)}'],
          ]),
        ],
      ),
    );
  }

  Widget _miniTabela(List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r[0],
                    style: const TextStyle(fontSize: 11, color: _grey)),
                Text(r[1],
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 3 – ALERTAS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabAlertas() {
    // Gera alertas dinamicamente
    final alertas = <_Alerta>[];
    final positivos = <_Alerta>[];

    // Concentração
    if (widget.produtos.length == 1) {
      alertas.add(_Alerta(
        Icons.warning_amber_rounded,
        'Baixa diversificação',
        '100% da receita concentrada em 1 produto. Risco alto caso haja problemas de estoque ou demanda.',
        _amberLight,
        const Color(0xFFFAC775),
        const Color(0xFF633806),
      ));
    }

    // Impostos
    final impostos = despesaTotal * 0.25;
    if (impostos > 0) {
      alertas.add(_Alerta(
        Icons.account_balance_wallet_outlined,
        'Impostos: ${(impostos / despesaTotal * 100).toStringAsFixed(0)}% das despesas',
        'R\$ ${impostos.toStringAsFixed(2)} em impostos neste período. Avalie enquadramento tributário para otimizar.',
        _amberLight,
        const Color(0xFFFAC775),
        const Color(0xFF633806),
      ));
    }

    // Margem baixa
    if (margemPct < 20) {
      alertas.add(_Alerta(
        Icons.trending_down_rounded,
        'Margem abaixo do ideal',
        'Margem de ${margemPct.toStringAsFixed(0)}% está abaixo da média do varejo (30–40%). Reavalie precificação.',
        _redLight,
        const Color(0xFFF7C1C1),
        const Color(0xFF791F1F),
      ));
    }

    // Margem excelente
    if (margemPct >= 50) {
      positivos.add(_Alerta(
        Icons.trending_up_rounded,
        'Margem excelente (${margemPct.toStringAsFixed(0)}%)',
        'Margem acima de 50% está excelente frente à média do varejo (30–40%). Continue priorizando produtos de alta margem.',
        _greenLight,
        const Color(0xFFC0DD97),
        const Color(0xFF27500A),
      ));
    } else if (margemPct >= 30) {
      positivos.add(_Alerta(
        Icons.trending_up_rounded,
        'Boa margem (${margemPct.toStringAsFixed(0)}%)',
        'Margem saudável, acima da média de mercado.',
        _greenLight,
        const Color(0xFFC0DD97),
        const Color(0xFF27500A),
      ));
    }

    // Lucro positivo
    if (lucroTotal > 0) {
      positivos.add(_Alerta(
        Icons.check_circle_outline_rounded,
        'Negócio lucrativo',
        'R\$ ${lucroTotal.toStringAsFixed(2)} de lucro líquido neste período. Negócio com resultado positivo.',
        _greenLight,
        const Color(0xFFC0DD97),
        const Color(0xFF27500A),
      ));
    }

    // Oportunidade
    if (lucroTotal > 0 && widget.produtos.length < 3) {
      positivos.add(_Alerta(
        Icons.lightbulb_outline_rounded,
        'Oportunidade de crescimento',
        'Com margens saudáveis, reinvestir parte do lucro em novos produtos pode acelerar o crescimento.',
        _purpleLight,
        const Color(0xFFCECBF6),
        const Color(0xFF3C3489),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo
          Row(
            children: [
              _kpiMini('Alertas', '${alertas.length}',
                  Icons.warning_amber_rounded, _amberLight, _amber),
              const SizedBox(width: 8),
              _kpiMini('Positivos', '${positivos.length}',
                  Icons.check_rounded, _greenLight, _green),
            ],
          ),
          const SizedBox(height: 16),
          if (alertas.isNotEmpty) ...[
            _sectionLabel('Pontos de atenção'),
            ...alertas.map(_alertaCard),
            const SizedBox(height: 8),
          ],
          if (positivos.isNotEmpty) ...[
            _sectionLabel('Destaques positivos'),
            ...positivos.map(_alertaCard),
          ],
        ],
      ),
    );
  }

  Widget _alertaCard(_Alerta a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: a.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: a.borderColor, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: a.borderColor,
                borderRadius: BorderRadius.circular(9)),
            child: Icon(a.icon, size: 18, color: a.textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: a.textColor)),
                const SizedBox(height: 4),
                Text(a.desc,
                    style:
                        TextStyle(fontSize: 12, color: a.textColor.withOpacity(0.8), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 4 – SAÚDE FINANCEIRA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabSaude() {
    final score = healthScore;
    final color = healthColor;
    final label = healthLabel;

    final indicadores = [
      _Indicador(
        'Margem bruta (${margemPct.toStringAsFixed(0)}%)',
        margemPct >= 50
            ? 'Excelente'
            : margemPct >= 30
                ? 'Boa'
                : 'Fraca',
        margemPct >= 50
            ? _greenMid
            : margemPct >= 30
                ? _amberMid
                : _redMid,
      ),
      _Indicador(
        'Resultado (${lucroTotal >= 0 ? "lucrativo" : "prejuízo"})',
        lucroTotal >= 0 ? 'Ótimo' : 'Atenção',
        lucroTotal >= 0 ? _greenMid : _redMid,
      ),
      _Indicador(
        'Diversificação (${widget.produtos.length} produto(s))',
        widget.produtos.length >= 3
            ? 'Ótimo'
            : widget.produtos.length == 2
                ? 'Regular'
                : 'Fraco',
        widget.produtos.length >= 3
            ? _greenMid
            : widget.produtos.length == 2
                ? _amberMid
                : _redMid,
      ),
      _Indicador(
        'Carga tributária (25% das despesas)',
        despesaTotal * 0.25 / (despesaTotal == 0 ? 1 : despesaTotal) < 0.20
            ? 'Ok'
            : 'Moderado',
        _amberMid,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          _card(Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                          strokeCap: StrokeCap.round,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$score',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: color)),
                            const Text('score',
                                style: TextStyle(
                                    fontSize: 10, color: _grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          lucroTotal > 0
                              ? 'Negócio com fundamentos sólidos. ${margemPct >= 50 ? "Margem excelente." : "Foco em expandir margem."}'
                              : 'Resultado negativo. Reavalie custos e precificação.',
                          style: const TextStyle(
                              fontSize: 12, color: _grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...indicadores.map((ind) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: ind.color,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(ind.label,
                                style: const TextStyle(
                                    fontSize: 12, color: _grey))),
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
                      ],
                    ),
                  )),
            ],
          )),

          const SizedBox(height: 14),
          _sectionLabel('Evolução (simulação)'),
          _card(_trendChart()),
        ],
      ),
    );
  }

  Widget _trendChart() {
    final base = lucroTotal;
    final List<FlSpot> receitas = List.generate(6, (i) {
      return FlSpot(i.toDouble(), receitaTotal * (0.72 + i * 0.056));
    });
    final List<FlSpot> lucros = List.generate(6, (i) {
      return FlSpot(i.toDouble(), base * (0.63 + i * 0.074));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Projeção 6 meses',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Com base na tendência atual',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
                      final i = v.toInt();
                      if (i < 0 || i >= months.length) return const SizedBox();
                      return Text(months[i],
                          style: const TextStyle(fontSize: 10, color: _grey));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, m) => Text(
                      'R\$${v.toInt()}',
                      style: const TextStyle(fontSize: 9, color: _grey),
                    ),
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: receitas,
                  isCurved: true,
                  color: _purple,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: _purple.withOpacity(0.07)),
                ),
                LineChartBarData(
                  spots: lucros,
                  isCurved: true,
                  color: _greenMid,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: _greenMid.withOpacity(0.07)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend([
          _LegendItem('Receita', _purple),
          _LegendItem('Lucro', _greenMid),
        ]),
      ],
    );
  }

  // ─── Helpers UI ───────────────────────────────────────────────────────────
  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _grey,
            letterSpacing: 0.6),
      ),
    );
  }

  Widget _legend(List<_LegendItem> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 5),
                  Text(item.label,
                      style:
                          const TextStyle(fontSize: 11, color: _grey)),
                ],
              ))
          .toList(),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────
class _WFBar {
  final String label;
  final double value;
  final Color color;
  _WFBar(this.label, this.value, this.color);
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem(this.label, this.color);
}

class _Alerta {
  final IconData icon;
  final String title;
  final String desc;
  final Color bg;
  final Color borderColor;
  final Color textColor;
  _Alerta(this.icon, this.title, this.desc, this.bg, this.borderColor,
      this.textColor);
}

class _Indicador {
  final String label;
  final String grade;
  final Color color;
  _Indicador(this.label, this.grade, this.color);
}