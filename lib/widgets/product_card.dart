import 'package:flutter/material.dart';
import '../models/produto.dart';

class ProductCard extends StatelessWidget {
  final Produto produto;
  final VoidCallback onTap;

  const ProductCard({required this.produto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory, size: 32, color: Colors.indigo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(produto.nome,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("Estoque: ${produto.estoque}",
                            style: TextStyle(color: Colors.grey.shade700)),
                        Text(
                          "Lucro por unidade: R\$ ${produto.lucroUnitario.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 13),
                        )
                      ]),
                ),
                Icon(Icons.chevron_right, size: 28, color: Colors.grey.shade600)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
