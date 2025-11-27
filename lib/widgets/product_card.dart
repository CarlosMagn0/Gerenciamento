import 'package:flutter/material.dart';
import '../models/produto.dart';

class ProductCard extends StatelessWidget {
  final Produto produto;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSell;
  final VoidCallback? onEdit;

  const ProductCard({
    super.key,
    required this.produto,
    this.onTap,
    this.onDelete,
    this.onSell,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final nome = produto.nome;
    final categoria = produto.categoria;
    final quantidade = produto.estoque;
    final preco = produto.precoVenda * produto.vendidos;
    final lucro = produto.lucroTotal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header: avatar + category + menu
            Row(
              children: [
                _avatar(nome),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(categoria, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // price & quantity row
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('R\$ ${preco.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Lucro R\$ ${lucro.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Column(
                  children: [
                    Text('Qtd', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: quantidade > 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$quantidade', style: TextStyle(fontWeight: FontWeight.bold, color: quantidade > 0 ? Colors.green : Colors.red)),
                    ),
                  ],
                )
              ],
            ),

            const Spacer(),

            // actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSell,
                    icon: const Icon(Icons.remove_shopping_cart),
                    label: const Text('Vender'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final initials = name.trim().isEmpty
        ? 'S'
        : name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final color = _colorFromString(name);
    return CircleAvatar(
      backgroundColor: color,
      child: Text(initials, style: const TextStyle(color: Colors.white)),
    );
  }

  Color _colorFromString(String s) {
    final hash = s.codeUnits.fold(0, (a, b) => a + b);
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.red];
    return colors[hash % colors.length];
  }
}
