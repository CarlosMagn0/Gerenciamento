import 'package:flutter/material.dart';
import '../models/produto.dart';

class NovoProdutoPage extends StatefulWidget {
  final Produto? produto;

  const NovoProdutoPage({super.key, this.produto});

  @override
  State<NovoProdutoPage> createState() => _NovoProdutoPageState();
}

class _NovoProdutoPageState extends State<NovoProdutoPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _compraController;
  late final TextEditingController _vendaController;
  late final TextEditingController _estoqueController;

  final List<String> _categoriasPadrao = [
    'Casa',
    'Alimentação',
    'Educação',
    'Beleza',
    'Eletrônicos',
    'Outros',
  ];

  String? _categoriaSelecionada;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;

    _nomeController = TextEditingController(text: p?.nome ?? '');
    _categoriaController = TextEditingController(text: p?.categoria ?? '');
    _compraController =
        TextEditingController(text: p != null ? p.precoCompra.toStringAsFixed(2) : '');
    _vendaController =
        TextEditingController(text: p != null ? p.precoVenda.toStringAsFixed(2) : '');
    _estoqueController =
        TextEditingController(text: p != null ? p.estoque.toString() : '0');

    if (p != null && _categoriasPadrao.contains(p.categoria)) {
      _categoriaSelecionada = p.categoria;
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

 void _save() {
  if (!_formKey.currentState!.validate()) return;

  final p = widget.produto;

  if (p != null) {
    // EDITANDO
    p.nome = _nomeController.text.trim();
    p.categoria = _categoriaSelecionada ?? _categoriaController.text.trim();
    p.precoCompra = double.parse(_compraController.text.replaceAll(',', '.'));
    p.precoVenda = double.parse(_vendaController.text.replaceAll(',', '.'));
    p.estoque = int.parse(_estoqueController.text);

    Navigator.of(context).pop(true); // apenas sinaliza que salvou
  } else {
    // NOVO PRODUTO
    final novo = Produto(
      nome: _nomeController.text.trim(),
      categoria: _categoriaSelecionada ?? _categoriaController.text.trim(),
      precoCompra: double.parse(_compraController.text.replaceAll(',', '.')),
      precoVenda: double.parse(_vendaController.text.replaceAll(',', '.')),
      estoque: int.parse(_estoqueController.text),
    );

    Navigator.of(context).pop(novo);
  }
}


  @override
  Widget build(BuildContext context) {
    final editando = widget.produto != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          editando ? 'Editar Produto' : 'Novo Produto',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(editando ? 'Salvar alterações' : 'Cadastrar produto'),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              _sectionCard(
                title: "Informações",
                child: Column(
                  children: [
                    _field(
                      controller: _nomeController,
                      label: "Nome do produto",
                      icon: Icons.label,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _categoriaSelecionada,
                      items: _categoriasPadrao
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _categoriaSelecionada = v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Selecione uma categoria' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _sectionCard(
                title: "Preços",
                child: Column(
                  children: [
                    _moneyField(
                      controller: _compraController,
                      label: "Preço de compra",
                    ),
                    const SizedBox(height: 14),
                    _moneyField(
                      controller: _vendaController,
                      label: "Preço de venda",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _sectionCard(
                title: "Estoque inicial",
                child: _field(
                  controller: _estoqueController,
                  label: "Quantidade",
                  icon: Icons.inventory_2,
                  keyboard: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o estoque';
                    if (int.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 80), // espaço pro botão
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Informe o valor';
        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
        prefixIcon: const Icon(Icons.attach_money),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
