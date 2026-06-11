import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'home_page.dart';

// ─────────────────────────────────────────────
//  PALETA  (Dark Ink  ·  Cobalt Violet  ·  Gold)
// ─────────────────────────────────────────────
const _kBg        = Color(0xFF0D0F14); // Deep Ink
const _kSurface   = Color(0xFF13161D); // Dark surface
const _kBorder    = Color(0xFF252A35); // Divisor fino
const _kAccent    = Color(0xFF7C6FED); // Violeta cobalt
const _kGold      = Color(0xFFC9A96E); // Ouro financeiro
const _kTextPri   = Color(0xFFE8EAF0); // Branco suave
const _kTextSec   = Color(0xFF8891A4); // Cinza médio
const _kGoogleBg  = Color(0xFFF8F8F8); // Branco Google

// ─────────────────────────────────────────────
//  LOGOTIPO GEOMÉTRICO — LumioMark
//  Dois hexágonos regulares sobrepostos (ouro + violeta),
//  lembrando "L" entalhado e "inteligência em camadas".
//  → Para usar o asset real, substitua o widget LumioMark
//    pelo Image.asset('assets/icon.png') e remova o CustomPainter.
// ─────────────────────────────────────────────
class _LumioMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;

    Path _hexPath(double centerX, double centerY, double radius, double rotation) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60 - 90 + rotation) * (3.14159265 / 180);
        final x = centerX + radius * _cos(angle);
        final y = centerY + radius * _sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      return path;
    }

    final offset = size.width * 0.12;

    // Hexágono ouro (fundo, deslocado para baixo-direita)
    canvas.drawPath(
      _hexPath(cx + offset * 0.5, cy + offset * 0.3, r * 0.88, 0),
      Paint()
        ..color = _kGold.withOpacity(0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      _hexPath(cx + offset * 0.5, cy + offset * 0.3, r * 0.88, 0),
      Paint()
        ..color = _kGold.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Hexágono violeta (frente, deslocado para cima-esquerda)
    canvas.drawPath(
      _hexPath(cx - offset * 0.3, cy - offset * 0.3, r, 30),
      Paint()
        ..color = _kAccent.withOpacity(0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      _hexPath(cx - offset * 0.3, cy - offset * 0.3, r, 30),
      Paint()
        ..color = _kAccent.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Ponto central (dot de intersecção)
    canvas.drawCircle(
      Offset(cx + 1, cy + 1),
      size.width * 0.055,
      Paint()..color = _kGold.withOpacity(0.9),
    );
  }

  // Aproximações de cos/sin sem dart:math (compatível com tree-shake)
  double _cos(double rad) {
    // Série de Taylor (5 termos) — precisão suficiente para desenho
    double r = 1 - (rad * rad) / 2 + (rad * rad * rad * rad) / 24;
    return r;
  }

  double _sin(double rad) {
    double r = rad - (rad * rad * rad) / 6 + (rad * rad * rad * rad * rad) / 120;
    return r;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  BOTÃO GOOGLE AUTÊNTICO
//  Fundo claro, texto escuro, logo G desenhado
//  via arcos coloridos (sem pacote externo).
// ─────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const sw = 3.2;
    const pi = 3.14159265;

    final colors = [
      const Color(0xFF4285F4), // azul
      const Color(0xFFEA4335), // vermelho
      const Color(0xFFFBBC05), // amarelo
      const Color(0xFF34A853), // verde
    ];
    final starts = [
      -pi * 0.08,
      pi * 0.42,
      pi * 0.92,
      pi * 1.42,
    ];
    final sweeps = [
      pi * 0.50,
      pi * 0.50,
      pi * 0.50,
      pi * 0.50,
    ];

    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - sw / 2),
        starts[i],
        sweeps[i],
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  LOGIN PAGE
// ─────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loading = false;

  Future<void> loginGoogle() async {
    setState(() => loading = true);

    final result = await AuthService().signInWithGoogle();

    if (!mounted) return;

    setState(() => loading = false);

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return const HomePage();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SEÇÃO DE LOGO CENTRALIZADA ────────────────────
                  // Halo + marca geométrica + nome do app em destaque.
                  // → Para usar o asset real, substitua o CustomPaint abaixo por:
                  //   Image.asset('assets/icon.png', width: 96, height: 96, fit: BoxFit.contain)
                  Center(
                    child: Column(
                      children: [
                        // Halo externo (glow suave)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _kAccent.withOpacity(0.15),
                                _kBg.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: Center(
                            // Moldura quadrada com borda sutil
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: _kSurface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: _kBorder,
                                  width: 1.2,
                                ),
                              ),
                            padding: const EdgeInsets.all(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/iconn.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Nome do app logo abaixo da marca
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Lu',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                  color: _kTextPri,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'mio',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _kGold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 44),

                  // ── HEADLINE ──────────────────────────────────────
                  // Contraste de peso: "light + bold" na mesma frase
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.15,
                        letterSpacing: -0.5,
                        color: _kTextPri,
                      ),
                      children: [
                        TextSpan(
                          text: 'Controle\n',
                          style: TextStyle(fontWeight: FontWeight.w300),
                        ),
                        TextSpan(
                          text: 'financeiro.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Vendas, produtos e relatórios\nno lugar certo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _kTextSec,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 56),

                  // ── SEPARADOR COM LABEL ──────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: _kBorder, thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ACESSE SUA CONTA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kTextSec,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: _kBorder, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── BOTÃO GOOGLE AUTÊNTICO ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: loading ? null : loginGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: loading ? _kSurface : _kGoogleBg,
                        foregroundColor: const Color(0xFF1F1F1F),
                        disabledBackgroundColor: _kSurface,
                        disabledForegroundColor: _kTextSec,
                        side: BorderSide(
                          color: loading ? _kBorder : Colors.transparent,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kAccent,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CustomPaint(
                                    painter: _GoogleLogoPainter(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continuar com Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F1F1F),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── NOTA DE PRIVACIDADE ──────────────────────────
                  Center(
                    child: Text(
                      'Ao entrar, você concorda com nossos Termos de Uso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: _kTextSec.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 64),

                  // ── RODAPÉ ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Lumio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kGold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: '  ·  Finanças inteligentes',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _kTextSec,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'v1.0.0',
                        style: TextStyle(fontSize: 11, color: _kTextSec),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}