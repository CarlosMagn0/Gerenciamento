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
  String periodo = 'Janeiro';

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

  @override
  Widget build(BuildContext context) {
    final produtos = widget.produtos;

    // Calculate metrics using existing Produto fields: nome, categoria, precoCompra, precoVenda, vendidos, lucroTotal
    final lucroTotal = produtos.fold<double>(0.0, (s, p) => s + p.lucroTotal);
    final receitaTotal = produtos.fold<double>(0.0, (s, p) => s + p.precoVenda * p.vendidos);
    final despesaTotal = produtos.fold<double>(0.0, (s, p) => s + p.precoCompra * p.vendidos);

    final Map<String, double> categorias = {};
    final Map<String, int> produtosVendidos = {};
    for (var p in produtos) {
      final cat = p.categoria;
      categorias[cat] = (categorias[cat] ?? 0) + p.lucroTotal;
      produtosVendidos[p.nome] = (produtosVendidos[p.nome] ?? 0) + p.vendidos;
    }

    final totalCategorias = categorias.values.fold<double>(0.0, (a, b) => a + b);

    final chartColors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.teal,
      Colors.redAccent,
      Colors.indigo,
    ];

    // top balloon-style tabs
    Widget buildTopTabs() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicator: BoxDecoration(
            color: Colors.deepPurpleAccent,
            borderRadius: BorderRadius.circular(24),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: 'Despesas por categoria'),
            Tab(text: 'Despesas por conta'),
            Tab(text: 'Receitas'),
            Tab(text: 'Produtos'),
          ],
        ),
      );
    }

    // KPI cards
    Widget buildKpiCard(String title, String value, IconData icon,
        {Color? color}) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color ?? Colors.deepPurpleAccent,
                    child: Icon(icon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // product bar chart
    Widget buildProductBarChart() {
      final topProducts = produtos
          .where((p) => p.vendidos > 0)
              .toList()
                ..sort((a, b) => b.vendidos.compareTo(a.vendidos));

      final display = topProducts.take(6).toList();
      return SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, getTitlesWidget: (i, meta) {
                  final idx = i.toInt();
                  if (idx < 0 || idx >= display.length) return const SizedBox.shrink();
                  final name = display[idx].nome;
                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(name, style: TextStyle(fontSize: 10)));
                }),
              ),
            ),
            barGroups: display.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(toY: p.vendidos.toDouble(), width: 18, borderRadius: BorderRadius.circular(6)),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    // donut chart for categories
    Widget buildDonutChart() {
      if (categorias.isEmpty) return const SizedBox.shrink();
      final sections = categorias.entries.map((e) {
        final idx = categorias.keys.toList().indexOf(e.key);
        final color = chartColors[idx % chartColors.length];
        return PieChartSectionData(
          value: e.value,
          color: color,
          title: '',
          radius: 60,
        );
      }).toList();

      return SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 4,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total', style: TextStyle(color: Colors.grey[600])),
                Text('R\$ ${lucroTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      );
    }

    // list with legend
    Widget buildCategoryList() {
      return Column(
        children: categorias.entries.map((e) {
          final idx = categorias.keys.toList().indexOf(e.key);
          final color = chartColors[idx % chartColors.length];
          final percent = totalCategorias == 0 ? 0.0 : (e.value / totalCategorias) * 100;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,3))]),
            child: Row(
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Text(e.key, style: TextStyle(fontWeight: FontWeight.bold))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('R\$ ${e.value.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    Text('${percent.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                )
              ],
            ),
          );
        }).toList(),
      );
    }

    // products tab content
    Widget productsTab() {
      final topSold = produtosVendidos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            buildProductBarChart(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: topSold.length,
                itemBuilder: (context, idx) {
                  final entry = topSold[idx];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${idx + 1}')),
                    title: Text(entry.key),
                    subtitle: Text('Vendidos: ${entry.value}'),
                    trailing: Icon(Icons.chevron_right),
                  );
                },
              ),
            )
          ],
        ),
      );
    }

    // despesas por categoria tab
    Widget despesasCategoriaTab() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            buildDonutChart(),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: buildCategoryList())),
          ],
        ),
      );
    }

    // Placeholder tabs (Despesas por conta, Receitas)
    Widget placeholderTab(String title) {
      return Center(child: Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // top balloon tabs
              Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: buildTopTabs()),
                      const SizedBox(width: 8),
                      // month selector as small pill
                      GestureDetector(
                        onTap: () {
                          // quick demo: cycle months (no blocking async)
                          setState(() {
                            periodo = periodo == 'Janeiro' ? 'Fevereiro' : periodo == 'Fevereiro' ? 'Março' : 'Janeiro';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(periodo, style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // KPI row
              Row(
                children: [
                  buildKpiCard('Receita', 'R\$ ${receitaTotal.toStringAsFixed(2)}', Icons.attach_money, color: Colors.green),
                  buildKpiCard('Despesas', 'R\$ ${despesaTotal.toStringAsFixed(2)}', Icons.money_off, color: Colors.redAccent),
                  buildKpiCard('Lucro', 'R\$ ${lucroTotal.toStringAsFixed(2)}', Icons.trending_up, color: Colors.deepPurpleAccent),
                ],
              ),

              const SizedBox(height: 12),

              // tab views
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        despesasCategoriaTab(),
                        placeholderTab('Despesas por conta - ainda não implementado'),
                        placeholderTab('Receitas - resumo e tendências'),
                        productsTab(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
