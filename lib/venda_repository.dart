import 'package:hive/hive.dart';

import 'models/produto.dart';
import 'models/venda.dart';

class VendaRepository {
  final Box<Venda> _box = Hive.box<Venda>('vendasBox');

  List<Venda> listar() {
    return _box.values.toList();
  }

  Future<void> registrar({
    required Produto produto,
    required int quantidade,
    DateTime? data,
  }) async {
    await _box.add(
      Venda(
        produtoNome: produto.nome,
        categoria: produto.categoria,
        precoCompra: produto.precoCompra,
        precoVenda: produto.precoVenda,
        quantidade: quantidade,
        data: data ?? DateTime.now(),
      ),
    );
  }
}
