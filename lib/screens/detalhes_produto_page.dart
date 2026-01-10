import 'package:flutter/material.dart';
import '../models/produto.dart';

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

class _DetalhesProdutoPageState extends State<DetalhesProdutoPage> {
  void vender() {
    if (widget.produto.estoque > 0) {
      setState(() {
        widget.produto.estoque--;
        widget.produto.vendidos++;
      });

      widget.atualizar();

      if (widget.produto.estoque <= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠ Estoque de ${widget.produto.nome} está acabando!",
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "❌ Não há estoque para vender!",
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text(
          p.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // BOTÃO FIXO EMBAIXO (CTA)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: vender,
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: const Text("Registrar venda"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// CARD PRINCIPAL — LUCRO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A5AE0), Color(0xFF8F7CFF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lucro por unidade",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "R\$ ${p.lucroUnitario.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// GRID DE INFORMAÇÕES
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              children: [

                _InfoCard(
                  title: "Compra",
                  value: "R\$ ${p.precoCompra.toStringAsFixed(2)}",
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.orange,
                ),

                _InfoCard(
                  title: "Venda",
                  value: "R\$ ${p.precoVenda.toStringAsFixed(2)}",
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.green,
                ),

                _InfoCard(
                  title: "Estoque",
                  value: "${p.estoque}",
                  icon: Icons.inventory_2_rounded,
                  color: p.estoque <= 2 ? Colors.red : Colors.blue,
                ),

                _InfoCard(
                  title: "Vendidos",
                  value: "${p.vendidos}",
                  icon: Icons.trending_up_rounded,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
