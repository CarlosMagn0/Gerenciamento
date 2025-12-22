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

  final chartColors = [
    Colors.deepPurpleAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.teal,
    Colors.redAccent,
    Colors.indigo,
  ];

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

    // ================= KPIs =================
    final receitaTotal =
        produtos.fold<double>(0, (s, p) => s + p.precoVenda * p.vendidos);

    final despesaTotal =
        produtos.fold<double>(0, (s, p) => s + p.precoCompra * p.vendidos);

    final lucroTotal =
        produtos.fold<double>(0, (s, p) => s + p.lucroTotal);

    // ================= AGRUPAMENTOS =================
    final Map<String, double> despesasPorCategoria = {};
    final Map<String, double> receitasPorProduto = {};
    final Map<String, int> produtosVendidos = {};

    for (var p in produtos) {
      despesasPorCategoria[p.categoria] =
          (despesasPorCategoria[p.categoria] ?? 0) +
              (p.precoCompra * p.vendidos);

      receitasPorProduto[p.nome] =
          (receitasPorProduto[p.nome] ?? 0) +
              (p.precoVenda * p.vendidos);

      produtosVendidos[p.nome] =
          (produtosVendidos[p.nome] ?? 0) + p.vendidos;
    }

    final totalCategorias =
        despesasPorCategoria.values.fold(0.0, (a, b) => a + b);

    // ================= DESPESAS POR CONTA =================
    final despesasPorConta = {
      'Fornecedores': despesaTotal * 0.6,
      'Impostos': despesaTotal * 0.25,
      'Outros': despesaTotal * 0.15,
    };

    // ================= COMPONENTES =================
    Widget kpiCard(String title, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    Widget donutChart(Map<String, double> data, double centerValue) {
      if (data.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                centerSpaceRadius: 50,
                sectionsSpace: 4,
                sections: data.entries.map((e) {
                  final idx = data.keys.toList().indexOf(e.key);
                  return PieChartSectionData(
                    value: e.value,
                    color: chartColors[idx % chartColors.length],
                    radius: 60,
                    title: '',
                  );
                }).toList(),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(color: Colors.grey)),
                Text('R\$ ${centerValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
          ],
        ),
      );
    }

    Widget legendList(Map<String, double> data, double total) {
      return Column(
        children: data.entries.map((e) {
          final idx = data.keys.toList().indexOf(e.key);
          final percent = total == 0 ? 0 : (e.value / total) * 100;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: chartColors[idx % chartColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.key,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('R\$ ${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    Text('${percent.toStringAsFixed(1)}%',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                )
              ],
            ),
          );
        }).toList(),
      );
    }

Widget barChartProdutos() {
  final list = produtosVendidos.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top = list.take(5).toList();
  if (top.isEmpty) return const SizedBox.shrink();

  final maxValue =
      top.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

  return LayoutBuilder(
    builder: (context, constraints) {
      final barWidth =
          (constraints.maxWidth / (top.length * 2)).clamp(14.0, 28.0);

      return SizedBox(
        height: 260,
        child: BarChart(
          BarChartData(
            maxY: maxValue + (maxValue * 0.2),
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              horizontalInterval: maxValue / 4,
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxValue / 4,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= top.length) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: barWidth * 1.6,
                        child: Text(
                          top[index].key,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(top.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: top[index].value.toDouble(),
                    width: barWidth,
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.deepPurpleAccent,
                        Colors.purple,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    },
  );
}

    Widget listaProdutos() {
      final list = produtosVendidos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final nome = list[i].key;
          final vendidos = list[i].value;
          final p = produtos.firstWhere((e) => e.nome == nome);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Text(nome[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text('Vendidos: $vendidos',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('R\$ ${(p.precoVenda * vendidos).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    Text('Lucro R\$ ${p.lucroTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurpleAccent)),
                  ],
                )
              ],
            ),
          );
        },
      );
    }

    // ================= UI =================
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Tabs
    Material(
  color: Colors.white,
  elevation: 2,
  borderRadius: BorderRadius.circular(30),
  child: TabBar(
    controller: _tabs,
    isScrollable: true,

    // ❌ NÃO usar indicatorPadding
    indicator: BoxDecoration(
      color: Colors.deepPurpleAccent,
      borderRadius: BorderRadius.circular(30),
    ),

    labelColor: Colors.white,
    unselectedLabelColor: Colors.black54,

    tabs: const [
      Tab(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Text(
            'Desp. Categoria',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      Tab(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Text(
            'Desp. Conta',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      Tab(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Text(
            'Receitas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      Tab(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Text(
            'Produtos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 12),

            // KPIs
            Row(
              children: [
                kpiCard('Receita',
                    'R\$ ${receitaTotal.toStringAsFixed(2)}',
                    Icons.attach_money, Colors.green),
                const SizedBox(width: 8),
                kpiCard('Despesas',
                    'R\$ ${despesaTotal.toStringAsFixed(2)}',
                    Icons.money_off, Colors.redAccent),
                const SizedBox(width: 8),
                kpiCard('Lucro',
                    'R\$ ${lucroTotal.toStringAsFixed(2)}',
                    Icons.trending_up, Colors.deepPurpleAccent),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      Column(
                        children: [
                          donutChart(
                              despesasPorCategoria, despesaTotal),
                          Expanded(
                            child: SingleChildScrollView(
                              child: legendList(
                                  despesasPorCategoria, totalCategorias),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          donutChart(despesasPorConta, despesaTotal),
                          Expanded(
                            child: SingleChildScrollView(
                              child: legendList(
                                  despesasPorConta, despesaTotal),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          donutChart(receitasPorProduto, receitaTotal),
                          Expanded(
                            child: SingleChildScrollView(
                              child: legendList(
                                  receitasPorProduto, receitaTotal),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          barChartProdutos(),
                          const SizedBox(height: 12),
                          Expanded(child: listaProdutos()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
