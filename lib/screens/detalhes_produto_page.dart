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

      widget.atualizar(); // Atualiza lista principal

      if (widget.produto.estoque <= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠ Estoque de ${widget.produto.nome} está acabando!",
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
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
      appBar: AppBar(
        title: Text(
          p.nome,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // CARD DE INFORMAÇÕES DO PRODUTO
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Preço de compra:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("R\$ ${p.precoCompra.toStringAsFixed(2)}"),

                    SizedBox(height: 12),

                    Text("Preço de venda:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("R\$ ${p.precoVenda.toStringAsFixed(2)}"),

                    SizedBox(height: 12),

                    Text("Lucro por unidade:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("R\$ ${p.lucroUnitario.toStringAsFixed(2)}"),

                    SizedBox(height: 12),

                    Text("Estoque atual:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${p.estoque} unidades"),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // BOTÃO DE VENDA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vender,
                icon: Icon(Icons.shopping_cart_checkout_rounded),
                label: const Text("Registrar venda"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
