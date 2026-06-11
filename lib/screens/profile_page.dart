import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

// ─────────────────────────────────────────────
//  PALETA  (mesma da LoginPage — Dark Ink · Cobalt Violet · Gold)
// ─────────────────────────────────────────────
const _kBg       = Color(0xFF0D0F14);
const _kSurface  = Color(0xFF13161D);
const _kBorder   = Color(0xFF252A35);
const _kAccent   = Color(0xFF7C6FED);
const _kGold     = Color(0xFFC9A96E);
const _kTextPri  = Color(0xFFE8EAF0);
const _kTextSec  = Color(0xFF8891A4);
const _kDanger   = Color(0xFFE05C5C);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // ── LOGOUT COM DIALOG ────────────────────────────────────────────
  Future<void> logout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone + título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kDanger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: _kDanger,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sair da conta',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kTextPri,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Tem certeza que deseja encerrar a sessão?',
                style: TextStyle(
                  fontSize: 14,
                  color: _kTextSec,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextSec,
                        side: const BorderSide(color: _kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kDanger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Sair',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nome  = user?.displayName ?? 'Usuário';
    final email = user?.email ?? '';
    // Primeira letra do nome para o avatar monograma
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: _kBg,

      // ── APP BAR TRANSPARENTE ───────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _kTextPri,
            letterSpacing: 0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: _kTextSec,
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HERO DO USUÁRIO ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorder, width: 1),
              ),
              child: Column(
                children: [
                  // Avatar monograma com halo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo externo
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _kAccent.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kBg,
                          border: Border.all(color: _kAccent.withOpacity(0.5), width: 1.5),
                        ),
                        // → Se o Google retornar photoURL, use:
                        // backgroundImage: user?.photoURL != null
                        //     ? NetworkImage(user!.photoURL!) : null
                        child: Center(
                          child: Text(
                            inicial,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _kAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Nome
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kTextPri,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Email
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kTextSec,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Badge "Conta Google" — indica o método de login
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mini logo G (4 quadrantes coloridos)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CustomPaint(painter: _MiniGooglePainter()),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Autenticado via Google',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kTextSec,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── LABEL DE SEÇÃO ───────────────────────────────────────
            _sectionLabel('CONFIGURAÇÕES'),
            const SizedBox(height: 12),

            // ── CARDS DE AÇÃO ─────────────────────────────────────────
            _buildActionTile(
              icon: Icons.person_outline_rounded,
              label: 'Minha Conta',
              subtitle: 'Informações da conta',
              accent: _kAccent,
            ),
            _buildActionTile(
              icon: Icons.shield_outlined,
              label: 'Segurança',
              subtitle: 'Configurações de acesso',
              accent: const Color(0xFF5BA4CF),
            ),
            _buildActionTile(
              icon: Icons.cloud_sync_outlined,
              label: 'Sincronizar Dados',
              subtitle: 'Atualizar produtos na nuvem',
              accent: const Color(0xFF4CAF7D),
            ),
            _buildActionTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notificações',
              subtitle: 'Alertas e lembretes',
              accent: _kGold,
            ),

            const SizedBox(height: 28),

            _sectionLabel('SESSÃO'),
            const SizedBox(height: 12),

            // ── BOTÃO SAIR ────────────────────────────────────────────
            GestureDetector(
              onTap: () => logout(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: _kDanger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kDanger.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _kDanger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: _kDanger,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sair da Conta',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kDanger,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Encerrar sessão atual',
                            style: TextStyle(
                              fontSize: 12,
                              color: _kTextSec,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _kDanger,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── RODAPÉ ────────────────────────────────────────────────
            Center(
              child: RichText(
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
                      text: '  ·  v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextSec,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _kTextSec,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Row(
        children: [
          // Ícone com cor de accent individual
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kTextPri,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextSec,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: _kTextSec,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Mini logo Google (4 quadrantes coloridos)
//  Usado no badge "Autenticado via Google"
// ─────────────────────────────────────────────
class _MiniGooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height / 2;
    final w = size.width / 2;
    final rects = [
      Rect.fromLTWH(0, 0, w - 0.5, h - 0.5),
      Rect.fromLTWH(w + 0.5, 0, w - 0.5, h - 0.5),
      Rect.fromLTWH(0, h + 0.5, w - 0.5, h - 0.5),
      Rect.fromLTWH(w + 0.5, h + 0.5, w - 0.5, h - 0.5),
    ];
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
    ];
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i], const Radius.circular(1.5)),
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}