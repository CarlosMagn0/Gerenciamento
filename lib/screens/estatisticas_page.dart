import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/produto.dart';
import '../models/venda.dart';

class EstatisticasPage extends StatefulWidget {
  final List<Produto> produtos;

  const EstatisticasPage({super.key, required this.produtos});

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _periodoSelecionado = DateTime.now();
  bool _periodoPorDia = false;

  // ─── Paleta ───────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF534AB7);
  static const _purpleLight = Color(0xFFEDE9FB);
  static const _green = Color(0xFF3B6D11);
  static const _greenLight = Color(0xFFEAF3DE);
  static const _greenMid = Color(0xFF639922);
  static const _red = Color(0xFFA32D2D);
  static const _redLight = Color(0xFFFCEBEB);
  static const _redMid = Color(0xFFE24B4A);
  static const _amber = Color(0xFFBA7517);
  static const _amberLight = Color(0xFFFAEEDA);
  static const _amberMid = Color(0xFFEF9F27);
  static const _bg = Color(0xFFF7F6FB);
  static const _grey = Color(0xFF888780);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── Cálculos ─────────────────────────────────────────────────────────────
  static const _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  String get _periodoLabel {
    final mes = _meses[_periodoSelecionado.month - 1];
    if (_periodoPorDia) {
      return '${_periodoSelecionado.day} $mes ${_periodoSelecionado.year}';
    }
    return '$mes ${_periodoSelecionado.year}';
  }

  DateTime get _hoje {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _mesFuturo(int ano, int mes) {
    final atual = DateTime(_hoje.year, _hoje.month, 1);
    return DateTime(ano, mes, 1).isAfter(atual);
  }

  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Venda> get _vendasPeriodo {
    final vendas = Hive.box<Venda>('vendasBox').values;
    return vendas.where((venda) {
      if (_periodoPorDia) {
        return _mesmaData(venda.data, _periodoSelecionado);
      }
      return venda.data.year == _periodoSelecionado.year &&
          venda.data.month == _periodoSelecionado.month;
    }).toList();
  }

  bool get _semVendasPeriodo => _vendasPeriodo.isEmpty;

  double get receitaTotal =>
      _vendasPeriodo.fold(0.0, (s, venda) => s + venda.receita);

  double get despesaTotal =>
      _vendasPeriodo.fold(0.0, (s, venda) => s + venda.despesa);

  double get lucroTotal =>
      _vendasPeriodo.fold(0.0, (s, venda) => s + venda.lucro);

  double get margemPct =>
      receitaTotal == 0 ? 0 : (lucroTotal / receitaTotal) * 100;

  Map<String, double> get despesasPorCategoria {
    final m = <String, double>{};
    for (var venda in _vendasPeriodo) {
      m[venda.categoria] = (m[venda.categoria] ?? 0) + venda.despesa;
    }
    return m;
  }

  Map<String, double> get receitasPorProduto {
    final m = <String, double>{};
    for (var venda in _vendasPeriodo) {
      m[venda.produtoNome] =
          (m[venda.produtoNome] ?? 0) + venda.receita;
    }
    return m;
  }

  Map<String, int> get produtosVendidos {
    final m = <String, int>{};
    for (var venda in _vendasPeriodo) {
      m[venda.produtoNome] =
          (m[venda.produtoNome] ?? 0) + venda.quantidade;
    }
    return m;
  }

  Map<String, double> get lucrosPorProduto {
    final m = <String, double>{};
    for (var venda in _vendasPeriodo) {
      m[venda.produtoNome] = (m[venda.produtoNome] ?? 0) + venda.lucro;
    }
    return m;
  }

  Map<String, double> get despesasPorConta => {
        'Fornecedores': despesaTotal * 0.6,
        'Impostos': despesaTotal * 0.25,
        'Outros': despesaTotal * 0.15,
      };

  /// Score de saúde 0–100 baseado em 4 indicadores
  int get healthScore {
    int score = 0;
    // Margem: excelente ≥50%, boa ≥30%, fraca <30%
    if (margemPct >= 50) {
      score += 35;
    } else if (margemPct >= 30) {
      score += 20;
    } else {
      score += 5;
    }
    // Lucro positivo
    if (lucroTotal > 0) score += 25;
    // Diversificação: ≥3 produtos = ótimo, 2 = médio, 1 = fraco
    final np = widget.produtos.length;
    if (np >= 3) {
      score += 25;
    } else if (np == 2) {
      score += 15;
    } else {
      score += 5;
    }
    // Carga tributária (impostos / despesa): <20% ok, <30% médio, ≥30% ruim
    final cargaTrib =
        despesaTotal == 0 ? 0 : (despesaTotal * 0.25) / despesaTotal;
    if (cargaTrib < 0.20) {
      score += 15;
    } else if (cargaTrib < 0.30) {
      score += 8;
    } else {
      score += 2;
    }
    return score.clamp(0, 100);
  }

  String get healthLabel {
    final s = healthScore;
    if (s >= 80) return 'Excelente';
    if (s >= 60) return 'Bom desempenho';
    if (s >= 40) return 'Regular';
    return 'Atenção necessária';
  }

  Color get healthColor {
    final s = healthScore;
    if (s >= 80) return _greenMid;
    if (s >= 60) return _purple;
    if (s >= 40) return _amberMid;
    return _redMid;
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Venda>('vendasBox').listenable(),
      builder: (context, Box<Venda> box, _) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildTabBar(),
              _buildKpiStrip(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _tabVisaoGeral(),
                    _tabProdutos(),
                    _tabAlertas(),
                    _tabSaude(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Financeiro',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      actions: [
        GestureDetector(
          onTap: _abrirSeletorPeriodo,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_periodoLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _purple)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: _purple),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirSeletorPeriodo() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Escolher período',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _periodoOpcao(
                  icon: Icons.calendar_view_month_rounded,
                  title: 'Mês completo',
                  subtitle: 'Ver estatísticas consolidadas do mês',
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarMes();
                  },
                ),
                const SizedBox(height: 8),
                _periodoOpcao(
                  icon: Icons.today_rounded,
                  title: 'Dia específico',
                  subtitle: 'Ver estatísticas detalhadas por dia',
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarDia();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _periodoOpcao({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _purpleLight),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _purple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: _grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _grey),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarDia() async {
    final hoje = _hoje;
    final initialDate = _periodoSelecionado.isAfter(hoje)
        ? hoje
        : _periodoSelecionado;
    final data = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: hoje,
      helpText: 'Escolha o dia',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _purple,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (data == null) return;
    setState(() {
      _periodoSelecionado = data;
      _periodoPorDia = true;
    });
  }

  Future<void> _selecionarMes() async {
    final hoje = _hoje;
    var ano = _periodoSelecionado.isAfter(hoje)
        ? hoje.year
        : _periodoSelecionado.year;
    final selecionado = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Escolha o mês'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setDialogState(() => ano--),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Text('$ano',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: ano < hoje.year
                              ? () => setDialogState(() => ano++)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.4,
                      ),
                      itemBuilder: (context, index) {
                        final mes = index + 1;
                        final futuro = _mesFuturo(ano, mes);
                        final ativo = !_periodoPorDia &&
                            _periodoSelecionado.year == ano &&
                            _periodoSelecionado.month == mes;
                        return OutlinedButton(
                          onPressed: futuro
                              ? null
                              : () => Navigator.pop(
                                  context,
                                  DateTime(ano, mes, 1),
                                ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: ativo ? _purple : Colors.white,
                            foregroundColor: futuro
                                ? _grey
                                : ativo
                                    ? Colors.white
                                    : _purple,
                            side: BorderSide(
                                color: ativo ? _purple : _purpleLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_meses[index].substring(0, 3)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selecionado == null) return;
    setState(() {
      _periodoSelecionado = selecionado;
      _periodoPorDia = false;
    });
  }

  // ─── TabBar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Visão Geral',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Produtos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Alertas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Saúde',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Strip (fixo em todas as abas) ───────────────────────────────────
  Widget _buildKpiStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          _kpiMini('Receita', 'R\$ ${receitaTotal.toStringAsFixed(2)}',
              Icons.arrow_upward_rounded, _greenLight, _green),
          const SizedBox(width: 8),
          _kpiMini('Despesas', 'R\$ ${despesaTotal.toStringAsFixed(2)}',
              Icons.arrow_downward_rounded, _redLight, _red),
          const SizedBox(width: 8),
          _kpiMiniHighlight('Lucro', 'R\$ ${lucroTotal.toStringAsFixed(2)}',
              '${margemPct.toStringAsFixed(0)}% margem'),
        ],
      ),
    );
  }

  Widget _kpiMini(
      String label, String value, IconData icon, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: fg.withOpacity(0.8))),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _kpiMiniHighlight(String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_purple, Color(0xFF7F77DD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.trending_up_rounded,
                size: 14, color: Colors.white70),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(sub,
                style: const TextStyle(fontSize: 9, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 1 – VISÃO GERAL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabVisaoGeral() {
    if (_semVendasPeriodo) {
      return _emptyPeriodo();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Resumo estratégico'),
          _card(_strategicOverview()),
          const SizedBox(height: 14),
          _sectionLabel('Composição do resultado'),
          _card(_waterfallChart()),
          const SizedBox(height: 14),
          _sectionLabel('Margem por categoria'),
          _card(_margemBars()),
          const SizedBox(height: 14),
          _sectionLabel('Despesas por tipo'),
          _card(_donutDespesas()),
        ],
      ),
    );
  }

  Widget _emptyPeriodo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.event_busy_rounded,
                  color: _purple, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Sem vendas neste período',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _periodoPorDia
                  ? 'Nenhuma venda foi registrada em $_periodoLabel.'
                  : 'Nenhuma venda foi registrada em $_periodoLabel.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strategicOverview() {
    final vendidosTotal = produtosVendidos.values.fold(0, (a, b) => a + b);
    final ticketMedio = vendidosTotal == 0 ? 0.0 : receitaTotal / vendidosTotal;
    final metaReceita = (despesaTotal * 1.35).clamp(500.0, double.infinity);
    final progressoMeta =
        metaReceita == 0 ? 0.0 : (receitaTotal / metaReceita).clamp(0.0, 1.0);
    final eficiencia =
        receitaTotal == 0 ? 0.0 : (lucroTotal / receitaTotal).clamp(-1.0, 1.0);
    final runwayDias = despesaTotal <= 0
        ? 0
        : ((lucroTotal.abs() + receitaTotal) / (despesaTotal / 30)).round();
    final recomendacao = _recomendacaoFinanceira(progressoMeta, eficiencia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _strategyMetric(
            'Meta',
            '${(progressoMeta * 100).toStringAsFixed(0)}%',
            Icons.flag_rounded,
            progressoMeta >= 0.85 ? _greenMid : _purple,
            progressoMeta >= 0.85 ? _greenLight : _purpleLight,
          ),
          const SizedBox(width: 8),
          _strategyMetric(
            'Ticket médio',
            'R\$ ${ticketMedio.toStringAsFixed(2)}',
            Icons.payments_rounded,
            _amberMid,
            _amberLight,
          ),
          const SizedBox(width: 8),
          _strategyMetric(
            'Runway',
            '${runwayDias.clamp(0, 999)}d',
            Icons.speed_rounded,
            lucroTotal >= 0 ? _greenMid : _redMid,
            lucroTotal >= 0 ? _greenLight : _redLight,
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E6F5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Receita alvo',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(
                      'R\$ ${receitaTotal.toStringAsFixed(0)} / R\$ ${metaReceita.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _purple)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressoMeta,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(
                      progressoMeta >= 0.85 ? _greenMid : _purple),
                ),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: recomendacao.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(recomendacao.icon,
                      size: 16, color: recomendacao.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recomendacao.title,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: recomendacao.color)),
                      const SizedBox(height: 2),
                      Text(recomendacao.desc,
                          style: const TextStyle(
                              fontSize: 11, color: _grey, height: 1.35)),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _strategyMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(fontSize: 10, color: _grey)),
          ],
        ),
      ),
    );
  }

  _Insight _recomendacaoFinanceira(double progressoMeta, double eficiencia) {
    if (lucroTotal < 0) {
      return _Insight(
        Icons.warning_rounded,
        'Cortar perda primeiro',
        'O resultado está negativo. Revise preços, custos de compra e produtos com margem baixa.',
        _redMid,
      );
    }
    if (progressoMeta < 0.65) {
      return _Insight(
        Icons.campaign_rounded,
        'Acelerar vendas',
        'A meta ainda está distante. Priorize produtos campeões e faça uma ação comercial curta.',
        _amberMid,
      );
    }
    if (eficiencia >= 0.45) {
      return _Insight(
        Icons.rocket_launch_rounded,
        'Escalar com controle',
        'A margem está forte. Reponha os produtos de maior lucro e mantenha estoque mínimo.',
        _greenMid,
      );
    }
    return _Insight(
      Icons.tune_rounded,
      'Ajustar margem',
      'A operação vende, mas pode lucrar mais. Revise preço e custo dos itens mais vendidos.',
      _purple,
    );
  }

  // Waterfall chart
  Widget _waterfallChart() {
    final bars = [
      _WFBar('Receita', receitaTotal, _greenMid),
      _WFBar('Despesas', despesaTotal, _redMid),
      _WFBar('Lucro', lucroTotal, _purple),
    ];
    final maxY = receitaTotal * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cascata financeira',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Receita → Despesas → Lucro',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, m) => Text(
                      'R\$${v.toInt()}',
                      style: const TextStyle(fontSize: 9, color: _grey),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= bars.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(bars[i].label,
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(bars.length, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: bars[i].value,
                    width: 36,
                    color: bars[i].color,
                    borderRadius: BorderRadius.circular(8),
                    rodStackItems: [],
                  ),
                ]);
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend([
          _LegendItem('Receita', _greenMid),
          _LegendItem('Despesas', _redMid),
          _LegendItem('Lucro', _purple),
        ]),
      ],
    );
  }

  // Barras de margem por categoria
  Widget _margemBars() {
    final cats = despesasPorCategoria.entries.toList();
    if (cats.isEmpty) {
      return const Text('Sem dados', style: TextStyle(color: _grey));
    }
    final colors = [_purple, _greenMid, _amberMid, _redMid];
    return Column(
      children: List.generate(cats.length, (i) {
        final name = cats[i].key;
        final despesa = cats[i].value;
        final receita = receitasPorProduto.entries
            .where((_) => true)
            .fold(0.0, (s, e) => s + e.value);
        final margem = receita == 0
            ? 0.0
            : ((receita - despesa) / receita * 100).clamp(0, 100);
        final color = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('${margem.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: margem / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Donut despesas
  Widget _donutDespesas() {
    final data = despesasPorConta;
    final colors = [_purple, _greenMid, _amberMid];
    final keys = data.keys.toList();
    final vals = data.values.toList();
    final total = vals.fold(0.0, (a, b) => a + b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                centerSpaceRadius: 36,
                sectionsSpace: 3,
                sections: List.generate(keys.length, (i) {
                  return PieChartSectionData(
                    value: vals[i],
                    color: colors[i % colors.length],
                    radius: 44,
                    title: '',
                  );
                }),
              )),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total',
                      style: TextStyle(fontSize: 9, color: _grey)),
                  Text('R\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _purple)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: List.generate(keys.length, (i) {
              final pct = total == 0 ? 0 : (vals[i] / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(keys[i],
                            style: const TextStyle(fontSize: 12))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('R\$ ${vals[i].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _red)),
                        Text('${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 10, color: _grey)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 2 – PRODUTOS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabProdutos() {
    final sorted = produtosVendidos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Receita vs Custo por produto'),
          _card(_receitaVsCustoChart()),
          const SizedBox(height: 14),
          _sectionLabel('Ranking de produtos'),
          ...sorted.map((entry) => _produtoRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _receitaVsCustoChart() {
    final nomes = receitasPorProduto.keys.toList();
    if (nomes.isEmpty) return const Text('Sem dados');

    final maxY = nomes.map((n) {
      final receita = receitasPorProduto[n] ?? 0;
      return receita * 1.2;
    }).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Receita · Custo · Lucro',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Comparativo por produto',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= nomes.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(nomes[i],
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, m) => Text(
                      'R\$${v.toInt()}',
                      style: const TextStyle(fontSize: 9, color: _grey),
                    ),
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: List.generate(nomes.length, (i) {
                final nome = nomes[i];
                final p = widget.produtos.firstWhere((e) => e.nome == nome,
                    orElse: () => widget.produtos.first);
                final receita = receitasPorProduto[nome] ?? 0;
                final custo = p.precoCompra * p.vendidos;
                final lucro = p.lucroTotal;
                return BarChartGroupData(
                  x: i,
                  groupVertically: false,
                  barRods: [
                    BarChartRodData(
                        toY: receita,
                        color: _purple,
                        width: 14,
                        borderRadius: BorderRadius.circular(5)),
                    BarChartRodData(
                        toY: custo,
                        color: _redMid,
                        width: 14,
                        borderRadius: BorderRadius.circular(5)),
                    BarChartRodData(
                        toY: lucro,
                        color: _greenMid,
                        width: 14,
                        borderRadius: BorderRadius.circular(5)),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend([
          _LegendItem('Receita', _purple),
          _LegendItem('Custo', _redMid),
          _LegendItem('Lucro', _greenMid),
        ]),
      ],
    );
  }

Widget _produtoRow(String nome, int vendidos) {
  final p = widget.produtos
      .firstWhere((e) => e.nome == nome, orElse: () => widget.produtos.first);

  // ✅ Usa o lucro real do período (calculado de _vendasPeriodo)
  final receita = receitasPorProduto[nome] ?? 0.0;
  final lucro = lucrosPorProduto[nome] ?? 0.0;
  final margem = receita == 0 ? 0.0 : (lucro / receita * 100);

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _purpleLight,
              child: Text(nome[0].toUpperCase(),
                  style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('$vendidos vendido(s)',
                      style: const TextStyle(fontSize: 11, color: _grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('R\$ ${receita.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _green,
                        fontSize: 14)),
                Text('Lucro R\$ ${lucro.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: _purple)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Margem:',
                style: TextStyle(fontSize: 11, color: _grey)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (margem / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(margem >= 50
                      ? _greenMid
                      : margem >= 30
                          ? _amberMid
                          : _redMid),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${margem.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: margem >= 50
                        ? _green
                        : margem >= 30
                            ? _amber
                            : _red)),
          ],
        ),
        const SizedBox(height: 10),
        _miniTabela([
          ['Preço venda', 'R\$ ${p.precoVenda.toStringAsFixed(2)}'],
          ['Custo compra', 'R\$ ${p.precoCompra.toStringAsFixed(2)}'],
          ['Lucro no período', 'R\$ ${lucro.toStringAsFixed(2)}'],
        ]),
      ],
    ),
  );
}   

  Widget _miniTabela(List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r[0], style: const TextStyle(fontSize: 11, color: _grey)),
                Text(r[1],
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 3 – ALERTAS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabAlertas() {
    // Gera alertas dinamicamente
    final alertas = <_Alerta>[];
    final positivos = <_Alerta>[];

    // Concentração
    if (widget.produtos.length == 1) {
      alertas.add(_Alerta(
        Icons.warning_amber_rounded,
        'Baixa diversificação',
        '100% da receita concentrada em 1 produto. Risco alto caso haja problemas de estoque ou demanda.',
        _amberLight,
        const Color(0xFFFAC775),
        const Color(0xFF633806),
      ));
    }

    // Impostos
    final impostos = despesaTotal * 0.25;
    if (impostos > 0) {
      alertas.add(_Alerta(
        Icons.account_balance_wallet_outlined,
        'Impostos: ${(impostos / despesaTotal * 100).toStringAsFixed(0)}% das despesas',
        'R\$ ${impostos.toStringAsFixed(2)} em impostos neste período. Avalie enquadramento tributário para otimizar.',
        _amberLight,
        const Color(0xFFFAC775),
        const Color(0xFF633806),
      ));
    }

    // Margem baixa
    if (margemPct < 20) {
      alertas.add(_Alerta(
        Icons.trending_down_rounded,
        'Margem abaixo do ideal',
        'Margem de ${margemPct.toStringAsFixed(0)}% está abaixo da média do varejo (30–40%). Reavalie precificação.',
        _redLight,
        const Color(0xFFF7C1C1),
        const Color(0xFF791F1F),
      ));
    }

    // Margem excelente
    if (margemPct >= 50) {
      positivos.add(_Alerta(
        Icons.trending_up_rounded,
        'Margem excelente (${margemPct.toStringAsFixed(0)}%)',
        'Margem acima de 50% está excelente frente à média do varejo (30–40%). Continue priorizando produtos de alta margem.',
        _greenLight,
        const Color(0xFFC0DD97),
        const Color(0xFF27500A),
      ));
    } else if (margemPct >= 30) {
      positivos.add(_Alerta(
        Icons.trending_up_rounded,
        'Boa margem (${margemPct.toStringAsFixed(0)}%)',
        'Margem saudável, acima da média de mercado.',
        _greenLight,
        const Color(0xFFC0DD97),
        const Color(0xFF27500A),
      ));
    }

    // Lucro positivo
    if (lucroTotal > 0) {
      positivos.add(_Alerta(
        Icons.check_circle_outline_rounded,
        'Negócio lucrativo',
        'R\$ ${lucroTotal.toStringAsFixed(2)} de lucro líquido neste período. Negócio com resultado positivo.',
        _greenLight,
        const Color(0xFFC0DD97),
        const Color(0xFF27500A),
      ));
    }

    // Oportunidade
    if (lucroTotal > 0 && widget.produtos.length < 3) {
      positivos.add(_Alerta(
        Icons.lightbulb_outline_rounded,
        'Oportunidade de crescimento',
        'Com margens saudáveis, reinvestir parte do lucro em novos produtos pode acelerar o crescimento.',
        _purpleLight,
        const Color(0xFFCECBF6),
        const Color(0xFF3C3489),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo
          Row(
            children: [
              _kpiMini('Alertas', '${alertas.length}',
                  Icons.warning_amber_rounded, _amberLight, _amber),
              const SizedBox(width: 8),
              _kpiMini('Positivos', '${positivos.length}', Icons.check_rounded,
                  _greenLight, _green),
            ],
          ),
          const SizedBox(height: 16),
          if (alertas.isNotEmpty) ...[
            _sectionLabel('Pontos de atenção'),
            ...alertas.map(_alertaCard),
            const SizedBox(height: 8),
          ],
          if (positivos.isNotEmpty) ...[
            _sectionLabel('Destaques positivos'),
            ...positivos.map(_alertaCard),
          ],
        ],
      ),
    );
  }

  Widget _alertaCard(_Alerta a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: a.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: a.borderColor, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: a.borderColor, borderRadius: BorderRadius.circular(9)),
            child: Icon(a.icon, size: 18, color: a.textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: a.textColor)),
                const SizedBox(height: 4),
                Text(a.desc,
                    style: TextStyle(
                        fontSize: 12,
                        color: a.textColor.withOpacity(0.8),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABA 4 – SAÚDE FINANCEIRA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _tabSaude() {
    final score = healthScore;
    final color = healthColor;
    final label = healthLabel;

    final indicadores = [
      _Indicador(
        'Margem bruta (${margemPct.toStringAsFixed(0)}%)',
        margemPct >= 50
            ? 'Excelente'
            : margemPct >= 30
                ? 'Boa'
                : 'Fraca',
        margemPct >= 50
            ? _greenMid
            : margemPct >= 30
                ? _amberMid
                : _redMid,
      ),
      _Indicador(
        'Resultado (${lucroTotal >= 0 ? "lucrativo" : "prejuízo"})',
        lucroTotal >= 0 ? 'Ótimo' : 'Atenção',
        lucroTotal >= 0 ? _greenMid : _redMid,
      ),
      _Indicador(
        'Diversificação (${widget.produtos.length} produto(s))',
        widget.produtos.length >= 3
            ? 'Ótimo'
            : widget.produtos.length == 2
                ? 'Regular'
                : 'Fraco',
        widget.produtos.length >= 3
            ? _greenMid
            : widget.produtos.length == 2
                ? _amberMid
                : _redMid,
      ),
      _Indicador(
        'Carga tributária (25% das despesas)',
        despesaTotal * 0.25 / (despesaTotal == 0 ? 1 : despesaTotal) < 0.20
            ? 'Ok'
            : 'Moderado',
        _amberMid,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          _card(Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 104,
                    height: 104,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size.square(104),
                          painter: _HealthScorePainter(
                            value: score / 100,
                            color: color,
                            bgColor: Colors.grey.withOpacity(0.12),
                            strokeWidth: 8,
                          ),
                        ),
                        Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$score',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: color)),
                            const Text('score',
                                style: TextStyle(fontSize: 10, color: _grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _purpleLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _periodoPorDia
                                ? 'Detalhe do dia: $_periodoLabel'
                                : 'Período mensal: $_periodoLabel',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _purple),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lucroTotal > 0
                              ? 'Negócio com fundamentos sólidos. ${margemPct >= 50 ? "Margem excelente." : "Foco em expandir margem."}'
                              : 'Resultado negativo. Reavalie custos e precificação.',
                          style: const TextStyle(
                              fontSize: 12, color: _grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...indicadores.map((ind) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: ind.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(ind.label,
                                style: const TextStyle(
                                    fontSize: 12, color: _grey))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ind.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(ind.grade,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ind.color)),
                        ),
                      ],
                    ),
                  )),
            ],
          )),

          const SizedBox(height: 14),
          _sectionLabel('Evolução (simulação)'),
          _card(_trendChart()),
        ],
      ),
    );
  }

  Widget _trendChart() {
    final base = lucroTotal;
    final List<FlSpot> receitas = List.generate(6, (i) {
      return FlSpot(i.toDouble(), receitaTotal * (0.72 + i * 0.056));
    });
    final List<FlSpot> lucros = List.generate(6, (i) {
      return FlSpot(i.toDouble(), base * (0.63 + i * 0.074));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Projeção 6 meses',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Com base na tendência atual',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
                      final i = v.toInt();
                      if (i < 0 || i >= months.length) return const SizedBox();
                      return Text(months[i],
                          style: const TextStyle(fontSize: 10, color: _grey));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, m) => Text(
                      'R\$${v.toInt()}',
                      style: const TextStyle(fontSize: 9, color: _grey),
                    ),
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: receitas,
                  isCurved: true,
                  color: _purple,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData:
                      BarAreaData(show: true, color: _purple.withOpacity(0.07)),
                ),
                LineChartBarData(
                  spots: lucros,
                  isCurved: true,
                  color: _greenMid,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: _greenMid.withOpacity(0.07)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend([
          _LegendItem('Receita', _purple),
          _LegendItem('Lucro', _greenMid),
        ]),
      ],
    );
  }

  // ─── Helpers UI ───────────────────────────────────────────────────────────
  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _grey,
            letterSpacing: 0.6),
      ),
    );
  }

  Widget _legend(List<_LegendItem> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 5),
                  Text(item.label,
                      style: const TextStyle(fontSize: 11, color: _grey)),
                ],
              ))
          .toList(),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────
class _WFBar {
  final String label;
  final double value;
  final Color color;
  _WFBar(this.label, this.value, this.color);
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem(this.label, this.color);
}

class _Alerta {
  final IconData icon;
  final String title;
  final String desc;
  final Color bg;
  final Color borderColor;
  final Color textColor;
  _Alerta(this.icon, this.title, this.desc, this.bg, this.borderColor,
      this.textColor);
}

class _Indicador {
  final String label;
  final String grade;
  final Color color;
  _Indicador(this.label, this.grade, this.color);
}

class _Insight {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  _Insight(this.icon, this.title, this.desc, this.color);
}

class _HealthScorePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _HealthScorePainter({
    required this.value,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    canvas.drawArc(
      rect,
      -1.5708,
      6.2832 * value.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HealthScorePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
