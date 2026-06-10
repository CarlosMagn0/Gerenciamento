import 'package:hive/hive.dart';
import '../models/produto.dart';
import '../services/firestore_service.dart';

class ProdutoRepository {
  // Box do Hive
  final Box<Produto> _box = Hive.box<Produto>('produtosBox');

  // Firestore
  final FirestoreService _firestore = FirestoreService();

  /// Lista todos os produtos
  List<Produto> listar() {
    return _box.values.toList();
  }

  /// Adiciona produto
  Future<void> adicionar(Produto produto) async {
    try {
      print("SALVANDO HIVE");

      await _box.add(produto);

      print("SALVANDO FIRESTORE");

      await _firestore.salvarProduto(produto);

      print("FINALIZOU");
    } catch (e) {
      print("ERRO AO SALVAR PRODUTO: $e");
    }
  }

  /// Atualiza produto
  Future<void> atualizar(int index, Produto produto) async {
    await _box.putAt(index, produto);
  }

  /// Remove produto
  Future<void> remover(int index) async {
    await _box.deleteAt(index);
  }

  /// Limpa todos os produtos
  Future<void> limpar() async {
    await _box.clear();
  }
}