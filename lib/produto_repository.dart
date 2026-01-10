import 'package:hive/hive.dart';
import '../models/produto.dart';

class ProdutoRepository {
  // Box correta (mesmo nome do main.dart)
  final Box<Produto> _box = Hive.box<Produto>('produtosBox');

  /// Lista todos os produtos
  List<Produto> listar() {
    return _box.values.toList();
  }

  /// Adiciona um novo produto
  Future<void> adicionar(Produto produto) async {
    await _box.add(produto);
  }

  /// Atualiza um produto pelo índice
  Future<void> atualizar(int index, Produto produto) async {
    await _box.putAt(index, produto);
  }

  /// Remove um produto
  Future<void> remover(int index) async {
    await _box.deleteAt(index);
  }

  /// Limpa todos os produtos
  Future<void> limpar() async {
    await _box.clear();
  }
}
