import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/produto.dart';

class EstatisticasPage extends StatelessWidget {
  final List<Produto> produtos;

  const EstatisticasPage({Key? key, required this.produtos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lucroTotal =
        produtos.fold(0.0, (sum, p) => sum + p.lucroTotal);

    return Scaffold(
      appBar: AppBar(title: const Text("Estatísticas")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("Lucro total",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(
                      "R\$ ${lucroTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      barGroups: produtos.asMap().entries.map((e) {
                        final i = e.key;
                        final p = e.value;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: p.lucroTotal,
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.indigo,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
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
