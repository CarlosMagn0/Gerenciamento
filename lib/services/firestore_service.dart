import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto.dart';
import '../models/venda.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================
  // PRODUTOS
  // ==========================

  Future<void> salvarProduto(Produto produto) async {
    await _db.collection('produtos').add({
      'nome': produto.nome,
      'categoria': produto.categoria,
      'precoCompra': produto.precoCompra,
      'precoVenda': produto.precoVenda,
      'estoque': produto.estoque,
      'vendidos': produto.vendidos,
    });

  Future<void> salvarProduto(Produto produto) async {
  print("ENTROU NO FIRESTORE");

  await _db.collection('produtos').add({
    'nome': produto.nome,
    'categoria': produto.categoria,
    'precoCompra': produto.precoCompra,
    'precoVenda': produto.precoVenda,
    'estoque': produto.estoque,
    'vendidos': produto.vendidos,
  });

  print("SALVOU NO FIRESTORE");
}
  }

  Future<List<Produto>> buscarProdutos() async {
    final snapshot = await _db.collection('produtos').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Produto(
        nome: data['nome'],
        categoria: data['categoria'],
        precoCompra: (data['precoCompra'] as num).toDouble(),
        precoVenda: (data['precoVenda'] as num).toDouble(),
        estoque: data['estoque'],
        vendidos: data['vendidos'],
      );
    }).toList();
  }

  // ==========================
  // VENDAS
  // ==========================

  Future<void> salvarVenda(Venda venda) async {
    await _db.collection('vendas').add({
      'produtoNome': venda.produtoNome,
      'categoria': venda.categoria,
      'precoCompra': venda.precoCompra,
      'precoVenda': venda.precoVenda,
      'quantidade': venda.quantidade,
      'data': venda.data.toIso8601String(),
    });
  }

  Future<List<Venda>> buscarVendas() async {
    final snapshot = await _db.collection('vendas').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Venda(
        produtoNome: data['produtoNome'],
        categoria: data['categoria'],
        precoCompra: (data['precoCompra'] as num).toDouble(),
        precoVenda: (data['precoVenda'] as num).toDouble(),
        quantidade: data['quantidade'],
        data: DateTime.parse(data['data']),
      );
    }).toList();
  }
}