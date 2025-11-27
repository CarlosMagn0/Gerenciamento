import 'package:flutter/material.dart';
import '../models/produto.dart';

class NovoProdutoPage extends StatefulWidget {
  final Produto? produto; // opcional: para edição

  const NovoProdutoPage({super.key, this.produto});

  @override
  State<NovoProdutoPage> createState() => _NovoProdutoPageState();
}

class _NovoProdutoPageState extends State<NovoProdutoPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers para permitir botões rápidos + edição manual
  late final TextEditingController _nomeController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _compraController;
  late final TextEditingController _vendaController;
  late final TextEditingController _estoqueController;

  // categorias predefinidas (você pode popular dinamicamente)
  final List<String> _categoriasPadrao = [
    'Casa',
    'Alimentação',
    'Educação',
    'Beleza',
    'Eletrônicos',
    'Outros',
  ];

  String? _categoriaSelecionada;
  bool _addingNewCategory = false;

  @override
  void initState() {
    super.initState();

    // se vier produto (edição) preenche
    final p = widget.produto;
    _nomeController = TextEditingController(text: p?.nome ?? '');
    _categoriaController = TextEditingController(text: p?.categoria ?? '');
    _compraController = TextEditingController(text: p != null ? p.precoCompra.toStringAsFixed(2) : '');
    _vendaController = TextEditingController(text: p != null ? p.precoVenda.toStringAsFixed(2) : '');
    _estoqueController = TextEditingController(text: p != null ? (p.estoque ?? 0).toString() : '0');

    if (p?.categoria != null && p!.categoria!.isNotEmpty) {
      if (!_categoriasPadrao.contains(p.categoria)) {
        // adicionar se não existir
        _categoriasPadrao.insert(0, p.categoria!);
      }
      _categoriaSelecionada = p.categoria!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _compraController.dispose();
    _vendaController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }

  // helper para formatar double em string com 2 casas
  String _fmtDouble(double v) => v.toStringAsFixed(2);

  // definir valor direto no controller (mantém cursor no fim)
  void _setMoneyController(TextEditingController c, double value) {
    c.text = _fmtDouble(value);
    c.selection = TextSelection.fromPosition(TextPosition(offset: c.text.length));
  }

  // somar ao estoque atual
  void _addToStock(int delta) {
    final current = int.tryParse(_estoqueController.text) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    _estoqueController.text = next.toString();
  }

  // botões rápidos para preços (valores em reais)
  final List<double> _quickPrices = [10, 25, 50, 100, 200, 500];

  // botões rápidos para estoque (valores fixos)
  final List<int> _quickStock = [0, 1, 5, 10, 50];

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final categoria = _addingNewCategory && _categoriaController.text.trim().isNotEmpty
        ? _categoriaController.text.trim()
        : (_categoriaSelecionada ?? _categoriaController.text.trim());

    final compra = double.tryParse(_compraController.text.replaceAll(',', '.')) ?? 0.0;
    final venda = double.tryParse(_vendaController.text.replaceAll(',', '.')) ?? 0.0;
    final estoque = int.tryParse(_estoqueController.text) ?? 0;

    // criar objeto Produto conforme seu modelo
    final novo = Produto(
      nome: nome,
      categoria: categoria,
      precoCompra: compra,
      precoVenda: venda,
      estoque: estoque,
    );

    Navigator.of(context).pop(novo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do produto',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Insira um nome' : null,
                ),
                const SizedBox(height: 14),

                // Categoria: chips + campo para digitar nova
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Categoria', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _addingNewCategory = !_addingNewCategory);
                      },
                      icon: Icon(_addingNewCategory ? Icons.close : Icons.add_box_outlined),
                      label: Text(_addingNewCategory ? 'Cancelar' : 'Nova categoria'),
                    )
                  ],
                ),
                if (!_addingNewCategory)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 2),
                        ..._categoriasPadrao.map((c) {
                          final selected = c == _categoriaSelecionada;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  _categoriaSelecionada = v ? c : null;
                                  _categoriaController.text = c;
                                });
                              },
                            ),
                          );
                        }).toList(),
                        // opção "Outros"
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Outros'),
                            selected: _categoriaSelecionada == 'Outros',
                            onSelected: (v) {
                              setState(() {
                                _categoriaSelecionada = v ? 'Outros' : null;
                                _categoriaController.text = _categoriaSelecionada ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  )
                else
                  TextFormField(
                    controller: _categoriaController,
                    decoration: const InputDecoration(
                      hintText: 'Digite a nova categoria',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    validator: (v) {
                      if (_addingNewCategory && (v == null || v.trim().isEmpty)) {
                        return 'Informe a nova categoria';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 18),

                // Preço de compra com botões rápidos
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Preço de compra', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _quickPrices.map((val) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () => _setMoneyController(_compraController, val),
                        child: Text('R\$ ${val.toInt()}'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _compraController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o preço de compra';
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null) return 'Valor inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Preço de venda com botões rápidos
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Preço de venda', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _quickPrices.map((val) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton.tonal(
                        onPressed: () => _setMoneyController(_vendaController, val),
                        child: Text('R\$ ${val.toInt()}'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _vendaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o preço de venda';
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null) return 'Valor inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Estoque: quick chips e botões +/- e input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estoque inicial', style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _addToStock(-1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          onPressed: () => _addToStock(1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _quickStock.map((v) {
                    return ChoiceChip(
                      label: Text('$v'),
                      selected: (_estoqueController.text == v.toString()),
                      onSelected: (_) {
                        setState(() {
                          _estoqueController.text = v.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _estoqueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o estoque inicial (0 se não houver)';
                    final parsed = int.tryParse(v);
                    if (parsed == null) return 'Número inválido';
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // botão salvar
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.produto == null ? 'Cadastrar' : 'Salvar alterações'),
                  ),
                ),

                const SizedBox(height: 12),
                // sugestão: botão para limpar formulário
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _nomeController.clear();
                          _categoriaController.clear();
                          _compraController.text = '';
                          _vendaController.text = '';
                          _estoqueController.text = '0';
                          _categoriaSelecionada = null;
                          _addingNewCategory = false;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Limpar'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
