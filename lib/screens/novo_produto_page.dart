import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/produto.dart';

class NovoProdutoPage extends StatefulWidget {
  final Produto? produto;

  const NovoProdutoPage({super.key, this.produto});

  @override
  State<NovoProdutoPage> createState() => _NovoProdutoPageState();
}

class _NovoProdutoPageState extends State<NovoProdutoPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────
  late final TextEditingController _nomeController;
  late final TextEditingController _compraController;
  late final TextEditingController _vendaController;
  late final TextEditingController _estoqueController;

  String? _categoriaSelecionada;
  bool _salvando = false;

  late AnimationController _previewAnim;
  late Animation<double> _previewFade;

  // ── Paleta (idêntica à EstatisticasPage) ─────────────────────────────────
  static const _purple      = Color(0xFF534AB7);
  static const _purpleDark  = Color(0xFF3C3489);
  static const _purpleLight = Color(0xFFEDE9FB);
  static const _greenMid    = Color(0xFF639922);
  static const _greenLight  = Color(0xFFEAF3DE);
  static const _green       = Color(0xFF3B6D11);
  static const _redMid      = Color(0xFFE24B4A);
  static const _redLight    = Color(0xFFFCEBEB);
  static const _red         = Color(0xFFA32D2D);
  static const _amber       = Color(0xFFBA7517);
  static const _amberLight  = Color(0xFFFAEEDA);
  static const _bg          = Color(0xFFF7F6FB);
  static const _grey        = Color(0xFF888780);
  static const _border      = Color(0xFFE4E2F5);

  // ── Categorias ────────────────────────────────────────────────────────────
  static const _categorias = [
    {'nome': 'Vestuário',   'icon': Icons.checkroom_outlined},
    {'nome': 'Eletrônicos', 'icon': Icons.devices_outlined},
    {'nome': 'Alimentos',   'icon': Icons.restaurant_outlined},
    {'nome': 'Beleza',      'icon': Icons.spa_outlined},
    {'nome': 'Casa',        'icon': Icons.home_outlined},
    {'nome': 'Esporte',     'icon': Icons.fitness_center_outlined},
    {'nome': 'Educação',    'icon': Icons.menu_book_outlined},
    {'nome': 'Outros',      'icon': Icons.category_outlined},
  ];

  // ── Derivados ─────────────────────────────────────────────────────────────
  double get _compra =>
      double.tryParse(_compraController.text.replaceAll(',', '.')) ?? 0;
  double get _venda =>
      double.tryParse(_vendaController.text.replaceAll(',', '.')) ?? 0;
  double get _lucro  => _venda - _compra;
  double get _margem => _venda == 0 ? 0 : (_lucro / _venda * 100);
  bool   get _temPreview => _compra > 0 || _venda > 0;

  // ── Init / Dispose ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final p = widget.produto;

    _nomeController    = TextEditingController(text: p?.nome ?? '');
    _compraController  = TextEditingController(
        text: p != null ? p.precoCompra.toStringAsFixed(2) : '');
    _vendaController   = TextEditingController(
        text: p != null ? p.precoVenda.toStringAsFixed(2) : '');
    _estoqueController = TextEditingController(
        text: p != null ? p.estoque.toString() : '0');

    if (p != null) {
      _categoriaSelecionada = _categorias
          .any((c) => c['nome'] == p.categoria)
          ? p.categoria
          : null;
    }

    _previewAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _previewFade =
        CurvedAnimation(parent: _previewAnim, curve: Curves.easeOut);

    _compraController.addListener(_onPrecoChanged);
    _vendaController.addListener(_onPrecoChanged);

    if (p != null && (_compra > 0 || _venda > 0)) {
      _previewAnim.forward();
    }
  }

  void _onPrecoChanged() {
    setState(() {});
    if (_temPreview) {
      _previewAnim.forward();
    } else {
      _previewAnim.reverse();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _compraController.dispose();
    _vendaController.dispose();
    _estoqueController.dispose();
    _previewAnim.dispose();
    super.dispose();
  }

  // ── Salvar ────────────────────────────────────────────────────────────────
  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSelecionada == null) {
      _snack('Selecione uma categoria', erro: true);
      return;
    }

    setState(() => _salvando = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final p = widget.produto;
    if (p != null) {
      p.nome        = _nomeController.text.trim();
      p.categoria   = _categoriaSelecionada!;
      p.precoCompra = _compra;
      p.precoVenda  = _venda;
      p.estoque     = int.tryParse(_estoqueController.text) ?? 0;
      Navigator.of(context).pop(true);
    } else {
      final novo = Produto(
        nome:        _nomeController.text.trim(),
        categoria:   _categoriaSelecionada!,
        precoCompra: _compra,
        precoVenda:  _venda,
        estoque:     int.tryParse(_estoqueController.text) ?? 0,
      );
      Navigator.of(context).pop(novo);
    }
  }

  void _snack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? _redMid : _purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final editando = widget.produto != null;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _appBar(editando),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Preview card animado ────────────────────────────
                    FadeTransition(
                      opacity: _previewFade,
                      child: SizeTransition(
                        sizeFactor: _previewFade,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 4),
                          child: _previewCard(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Informações ─────────────────────────────────────
                    _label('Informações do produto'),
                    const SizedBox(height: 10),
                    _card(Column(children: [
                      _inputField(
                        ctrl: _nomeController,
                        hint: 'Nome do produto',
                        icon: Icons.label_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                      ),
                    ])),

                    const SizedBox(height: 20),

                    // ── Categoria ───────────────────────────────────────
                    _label('Categoria'),
                    const SizedBox(height: 10),
                    _categoriaGrid(),

                    const SizedBox(height: 20),

                    // ── Precificação ────────────────────────────────────
                    _label('Precificação'),
                    const SizedBox(height: 10),
                    _card(Column(children: [
                      _inputField(
                        ctrl: _compraController,
                        hint: 'Preço de compra (custo)',
                        icon: Icons.arrow_downward_rounded,
                        iconColor: _redMid,
                        prefix: 'R\$',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        formatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d,.]'))
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Informe o custo';
                          if (_compra <= 0)
                            return 'Valor deve ser maior que zero';
                          return null;
                        },
                      ),
                      _divider(),
                      _inputField(
                        ctrl: _vendaController,
                        hint: 'Preço de venda',
                        icon: Icons.arrow_upward_rounded,
                        iconColor: _greenMid,
                        prefix: 'R\$',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        formatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d,.]'))
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Informe o preço de venda';
                          if (_venda <= 0)
                            return 'Valor deve ser maior que zero';
                          if (_venda <= _compra)
                            return 'Preço de venda deve ser maior que o custo';
                          return null;
                        },
                      ),
                    ])),

                    // ── Badge de margem ─────────────────────────────────
                    if (_temPreview && _compra > 0 && _venda > 0)
                      _margemBadge(),

                    const SizedBox(height: 20),

                    // ── Estoque ─────────────────────────────────────────
                    _label('Estoque inicial'),
                    const SizedBox(height: 10),
                    _estoqueCard(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _botaoSalvar(editando),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═════════════════════════════════════════════════════════════════════════

  // ── AppBar ────────────────────────────────────────────────────────────────
  SliverAppBar _appBar(bool editando) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      backgroundColor: Colors.white,
      foregroundColor: _purpleDark,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: _purple, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(60, 0, 16, 14),
        title: Text(
          editando ? 'Editar produto' : 'Novo produto',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _purpleDark),
        ),
        background: Container(
          color: Colors.white,
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 42),
          child: Text(
            editando
                ? 'Atualize as informações abaixo'
                : 'Preencha os dados para cadastrar',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
        ),
      ),
    );
  }

  // ── Preview card ──────────────────────────────────────────────────────────
  Widget _previewCard() {
    final isLucro = _lucro > 0;
    final gradColors = isLucro
        ? [_purple, const Color(0xFF7F77DD)]
        : [_redMid, const Color(0xFFC93A39)];

    String emoji;
    String msg;
    if (_margem >= 50)  { emoji = '🏆'; msg = 'Margem excelente!'; }
    else if (_margem >= 30) { emoji = '✅'; msg = 'Margem saudável'; }
    else if (_lucro > 0)    { emoji = '⚠️'; msg = 'Margem baixa — revise o preço'; }
    else                    { emoji = '❌'; msg = 'Prejuízo — venda abaixo do custo'; }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: gradColors[0].withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Preview em tempo real',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            Icon(
              isLucro
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: Colors.white70,
              size: 20),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _previewStat('Lucro/unit.',
                isLucro
                    ? '+R\$ ${_lucro.toStringAsFixed(2)}'
                    : '-R\$ ${_lucro.abs().toStringAsFixed(2)}'),
            _previewDivider(),
            _previewStat('Margem', '${_margem.toStringAsFixed(1)}%'),
            _previewDivider(),
            _previewStat('Custo', 'R\$ ${_compra.toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_margem.clamp(0, 100)) / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text('$emoji  $msg',
              style: const TextStyle(
                  fontSize: 12, color: Colors.white, height: 1.3)),
        ],
      ),
    );
  }

  Widget _previewStat(String label, String value) => Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white60)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ]),
      );

  Widget _previewDivider() => Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 10));

  // ── Badge de margem ───────────────────────────────────────────────────────
  Widget _margemBadge() {
    Color cor;
    Color bg;
    IconData ico;

    if (_lucro <= 0) {
      cor = _red; bg = _redLight; ico = Icons.cancel_outlined;
    } else if (_margem >= 50) {
      cor = _green; bg = _greenLight; ico = Icons.verified_outlined;
    } else if (_margem >= 30) {
      cor = _green; bg = _greenLight; ico = Icons.check_circle_outline;
    } else {
      cor = _amber; bg = _amberLight; ico = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(ico, color: cor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Margem: ${_margem.toStringAsFixed(1)}%  ·  '
            'Lucro por unidade: R\$ ${_lucro.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 12, color: cor, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  // ── Grid de categorias ────────────────────────────────────────────────────
  Widget _categoriaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: _categorias.length,
      itemBuilder: (_, i) {
        final cat = _categorias[i];
        final sel = _categoriaSelecionada == cat['nome'];
        return GestureDetector(
          onTap: () => setState(
              () => _categoriaSelecionada = cat['nome'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: sel ? _purple : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: sel ? _purple : _border,
                  width: sel ? 2 : 1),
              boxShadow: sel
                  ? [
                      BoxShadow(
                          color: _purple.withOpacity(0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]
                  : [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 5,
                          offset: const Offset(0, 2))
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: sel
                        ? Colors.white.withOpacity(0.2)
                        : _purpleLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat['icon'] as IconData,
                      size: 20,
                      color: sel ? Colors.white : _purple),
                ),
                const SizedBox(height: 6),
                Text(cat['nome'] as String,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : _grey),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Estoque card ──────────────────────────────────────────────────────────
  Widget _estoqueCard() {
    final qtd = int.tryParse(_estoqueController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2_outlined,
                color: _purple, size: 19),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantidade em estoque',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Unidades disponíveis para venda',
                      style:
                          TextStyle(fontSize: 11, color: _grey)),
                ]),
          ),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _stepBtn(
            icon: Icons.remove_rounded,
            onTap: () {
              final v =
                  (int.tryParse(_estoqueController.text) ?? 0) - 1;
              if (v >= 0) setState(() => _estoqueController.text = '$v');
            },
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _estoqueController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _purpleDark),
              decoration: InputDecoration(
                filled: true,
                fillColor: _purpleLight,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: _purple, width: 2)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o estoque';
                if (int.tryParse(v) == null) return 'Inválido';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 16),
          _stepBtn(
            icon: Icons.add_rounded,
            onTap: () {
              final v =
                  (int.tryParse(_estoqueController.text) ?? 0) + 1;
              setState(() => _estoqueController.text = '$v');
            },
            primary: true,
          ),
        ]),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            key: ValueKey(qtd),
            qtd == 0
                ? 'Sem estoque inicial'
                : qtd == 1
                    ? '1 unidade em estoque'
                    : '$qtd unidades em estoque',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: qtd == 0 ? _grey : _purple),
          ),
        ),
      ]),
    );
  }

  Widget _stepBtn(
      {required IconData icon,
      required VoidCallback onTap,
      bool primary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: primary ? _purple : _purpleLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: primary
              ? [
                  BoxShadow(
                      color: _purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Icon(icon,
            color: primary ? Colors.white : _purple, size: 22),
      ),
    );
  }

  // ── Botão salvar ──────────────────────────────────────────────────────────
  Widget _botaoSalvar(bool editando) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _salvando ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _purple.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _salvando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      editando
                          ? Icons.save_outlined
                          : Icons.add_circle_outline_rounded,
                      size: 20),
                    const SizedBox(width: 8),
                    Text(
                      editando
                          ? 'Salvar alterações'
                          : 'Cadastrar produto',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                  ]),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _purpleDark,
                letterSpacing: 0.2)),
      );

  Widget _card(Widget child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget _divider() => const Divider(
      height: 1,
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFF0EEF8));

  Widget _inputField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    Color? iconColor,
    String? prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    final icoClr = iconColor ?? _purple;

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w500, color: _purpleDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _grey),
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: icoClr.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: icoClr),
          ),
        ),
        prefixText: prefix != null ? '$prefix  ' : null,
        prefixStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: _purpleDark),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: const TextStyle(fontSize: 11, color: _redMid),
      ),
    );
  }
}