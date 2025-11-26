import 'package:flutter/material.dart';
import '../models/produto.dart';

class NovoProdutoPage extends StatefulWidget {
  const NovoProdutoPage({Key? key}) : super(key: key);

  @override
  State<NovoProdutoPage> createState() => _NovoProdutoPageState();
}

class _NovoProdutoPageState extends State<NovoProdutoPage> {
  final form = GlobalKey<FormState>();

  String nome = "";
  double compra = 0;
  double venda = 0;
  int estoque = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Produto")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: form,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(label: Text("Nome do produto")),
                validator: (v) => v!.isEmpty ? "Insira um nome" : null,
                onSaved: (v) => nome = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(label: Text("Preço de compra")),
                keyboardType: TextInputType.number,
                onSaved: (v) => compra = double.parse(v!),
              ),
              TextFormField(
                decoration: const InputDecoration(label: Text("Preço de venda")),
                keyboardType: TextInputType.number,
                onSaved: (v) => venda = double.parse(v!),
              ),
              TextFormField(
                decoration: const InputDecoration(label: Text("Estoque inicial")),
                keyboardType: TextInputType.number,
                onSaved: (v) =>
                    estoque = v!.isEmpty ? 0 : int.parse(v),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    form.currentState!.save();
                    Navigator.pop(
                      context,
                      Produto(
                        nome: nome,
                        precoCompra: compra,
                        precoVenda: venda,
                        estoque: estoque,
                      ),
                    );
                  }
                },
                child: const Text("Cadastrar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
