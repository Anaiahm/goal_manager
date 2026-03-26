import 'package:flutter/material.dart';
import 'dart:math';

// ─── Icon Types & Definitions ─────────────────────────────────

enum AppIconType { heart, butterfly, target, star, bolt, smiley, user, flame }

class AppIconDef {
  final Color bg, primary;
  final String label;
  final AppIconType type;
  const AppIconDef({
    required this.bg,
    required this.primary,
    required this.label,
    required this.type,
  });
}

const kAppIcons = [
  AppIconDef(bg: Color(0xFFFF69B4), primary: Color(0xFFFFFFFF), label: 'Heart',     type: AppIconType.heart),
  AppIconDef(bg: Color(0xFF7C6BAE), primary: Color(0xFFFFFFFF), label: 'Butterfly', type: AppIconType.butterfly),
  AppIconDef(bg: Color(0xFF2E6DA4), primary: Color(0xFFFFFFFF), label: 'Target',    type: AppIconType.target),
  AppIconDef(bg: Color(0xFFE8C87C), primary: Color(0xFFFFFFFF), label: 'Star',      type: AppIconType.star),
  AppIconDef(bg: Color(0xFF0D0D0D), primary: Color(0xFFFFFFFF), label: 'Bolt',      type: AppIconType.bolt),
  AppIconDef(bg: Color(0xFFE8A87C), primary: Color(0xFFFFFFFF), label: 'Smiley',    type: AppIconType.smiley),
  AppIconDef(bg: Color(0xFF5C7A5C), primary: Color(0xFFFFFFFF), label: 'User',      type: AppIconType.user),
  AppIconDef(bg: Color(0xFFE05555), primary: Color(0xFFFFFFFF), label: 'Flame',     type: AppIconType.flame),
];

// ─── App Icon Widget ──────────────────────────────────────────

class AppIconWidget extends StatelessWidget {
  final int index;
  final double size;
  const AppIconWidget({super.key, required this.index, this.size = 44});

  @override
  Widget build(BuildContext ctx) {
    final def = kAppIcons[index.clamp(0, kAppIcons.length - 1)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: def.bg,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: CustomPaint(
        painter: _AppIconPainter(def.type, def.primary),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────

class _AppIconPainter extends CustomPainter {
  final AppIconType type;
  final Color fg;
  const _AppIconPainter(this.type, this.fg);

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    switch (type) {
      case AppIconType.heart:     _drawHeart(c, cx, cy, s);     break;
      case AppIconType.butterfly: _drawButterfly(c, cx, cy, s); break;
      case AppIconType.target:    _drawTarget(c, cx, cy, s);    break;
      case AppIconType.star:      _drawStar(c, cx, cy, s);      break;
      case AppIconType.bolt:      _drawBolt(c, cx, cy, s);      break;
      case AppIconType.smiley:    _drawSmiley(c, cx, cy, s);    break;
      case AppIconType.user:      _drawUser(c, cx, cy, s);      break;
      case AppIconType.flame:     _drawFlame(c, cx, cy, s);     break;
    }
  }

  Paint _fp(Color color) =>
    Paint()..color = color..style = PaintingStyle.fill;

  Paint _sp(Color color, double sw) =>
    Paint()..color = color..style = PaintingStyle.stroke
      ..strokeWidth = sw..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

  void _drawHeart(Canvas c, double cx, double cy, Size s) {
    final sc = s.width / 80.0;
    final path = Path();
    path.moveTo(cx, cy + 22 * sc);
    path.cubicTo(cx - 2  * sc, cy + 20 * sc,
                 cx - 28 * sc, cy + 4  * sc,
                 cx - 28 * sc, cy - 12 * sc);
    path.cubicTo(cx - 28 * sc, cy - 26 * sc,
                 cx - 18 * sc, cy - 32 * sc,
                 cx - 9  * sc, cy - 28 * sc);
    path.cubicTo(cx - 5  * sc, cy - 26 * sc,
                 cx - 2  * sc, cy - 22 * sc,
                 cx,           cy - 18 * sc);
    path.cubicTo(cx + 2  * sc, cy - 22 * sc,
                 cx + 5  * sc, cy - 26 * sc,
                 cx + 9  * sc, cy - 28 * sc);
    path.cubicTo(cx + 18 * sc, cy - 32 * sc,
                 cx + 28 * sc, cy - 26 * sc,
                 cx + 28 * sc, cy - 12 * sc);
    path.cubicTo(cx + 28 * sc, cy + 4  * sc,
                 cx + 2  * sc, cy + 20 * sc,
                 cx,           cy + 22 * sc);
    path.close();
    c.drawPath(path, _fp(fg));
  }

  void _drawButterfly(Canvas c, double cx, double cy, Size s) {
    final sc = s.width / 80.0;
    // Upper wings
    final ul = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx, cy, cx - 22 * sc, cy - 20 * sc,
                cx - 20 * sc, cy - 8 * sc)
      ..cubicTo(cx - 18 * sc, cy + 2 * sc, cx - 8 * sc, cy + 6 * sc, cx, cy);
    c.drawPath(ul, _fp(fg.withOpacity(0.95)));

    final ur = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx, cy, cx + 22 * sc, cy - 20 * sc,
                cx + 20 * sc, cy - 8 * sc)
      ..cubicTo(cx + 18 * sc, cy + 2 * sc, cx + 8 * sc, cy + 6 * sc, cx, cy);
    c.drawPath(ur, _fp(fg.withOpacity(0.95)));

    // Lower wings
    final ll = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx, cy, cx - 16 * sc, cy + 14 * sc,
                cx - 12 * sc, cy + 20 * sc)
      ..cubicTo(cx - 8 * sc, cy + 24 * sc, cx - 2 * sc, cy + 18 * sc, cx, cy);
    c.drawPath(ll, _fp(fg.withOpacity(0.7)));

    final lr = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx, cy, cx + 16 * sc, cy + 14 * sc,
                cx + 12 * sc, cy + 20 * sc)
      ..cubicTo(cx + 8 * sc, cy + 24 * sc, cx + 2 * sc, cy + 18 * sc, cx, cy);
    c.drawPath(lr, _fp(fg.withOpacity(0.7)));

    // Body
    c.drawCircle(Offset(cx, cy), 3 * sc, _fp(fg));
    c.drawLine(Offset(cx, cy + 3 * sc), Offset(cx, cy + 14 * sc),
      _sp(fg, 2 * sc));
  }

  void _drawTarget(Canvas c, double cx, double cy, Size s) {
    final sw = s.width * 0.055;
    for (final r in [s.width * 0.36, s.width * 0.23, s.width * 0.10]) {
      c.drawCircle(Offset(cx, cy), r,
        Paint()..color = fg..style = PaintingStyle.stroke..strokeWidth = sw);
    }
  }

  void _drawStar(Canvas c, double cx, double cy, Size s) {
    final sc    = s.width / 80.0;
    const pts   = 5;
    final outer = 28.0 * sc;
    final inner = 11.0 * sc;
    final path  = Path();
    for (int i = 0; i < pts * 2; i++) {
      final r     = i.isEven ? outer : inner;
      final angle = (i * pi / pts) - pi / 2;
      final x     = cx + r * cos(angle);
      final y     = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    c.drawPath(path, _fp(fg));
  }
  void _drawBolt(Canvas c, double cx, double cy, Size s) {
    final sc = s.width / 80.0;
    final path = Path()
      ..moveTo(cx + 6  * sc, cy - 28 * sc)
      ..lineTo(cx - 10 * sc, cy + 2  * sc)
      ..lineTo(cx + 2  * sc, cy + 2  * sc)
      ..lineTo(cx - 8  * sc, cy + 28 * sc)
      ..lineTo(cx + 12 * sc, cy - 4  * sc)
      ..lineTo(cx + 0  * sc, cy - 4  * sc)
      ..close();
    c.drawPath(path, _fp(fg));
  }

  void _drawSmiley(Canvas c, double cx, double cy, Size s) {
    final sc = s.width / 80.0;
    final r  = 26 * sc;
    c.drawCircle(Offset(cx, cy), r,
      Paint()..color = fg..style = PaintingStyle.stroke..strokeWidth = 4 * sc);
    c.drawCircle(Offset(cx - 9 * sc, cy - 7 * sc), 3.5 * sc, _fp(fg));
    c.drawCircle(Offset(cx + 9 * sc, cy - 7 * sc), 3.5 * sc, _fp(fg));
    final smile = Path()
      ..moveTo(cx - 12 * sc, cy + 8 * sc)
      ..quadraticBezierTo(cx, cy + 20 * sc, cx + 12 * sc, cy + 8 * sc);
    c.drawPath(smile, _sp(fg, 3.5 * sc));
  }

  void _drawUser(Canvas c, double cx, double cy, Size s) {
    final sc = s.width / 80.0;
    // Head
    c.drawCircle(Offset(cx, cy - 12 * sc), 14 * sc, _fp(fg));
    // Body
    final body = Path()
      ..moveTo(cx - 28 * sc, cy + 32 * sc)
      ..cubicTo(cx - 28 * sc, cy + 8  * sc,
                cx + 28 * sc, cy + 8  * sc,
                cx + 28 * sc, cy + 32 * sc)
      ..close();
    c.drawPath(body, _fp(fg));
  }

  void _drawFlame(Canvas c, double cx, double cy, Size s) {
    final sc = s.width / 80.0;
    final path = Path()
      ..moveTo(cx, cy + 26 * sc)
      ..cubicTo(cx - 14 * sc, cy + 26 * sc,
                cx - 22 * sc, cy + 14 * sc,
                cx - 20 * sc, cy + 2  * sc)
      ..cubicTo(cx - 18 * sc, cy - 8  * sc,
                cx - 10 * sc, cy - 14 * sc,
                cx - 6  * sc, cy - 22 * sc)
      ..cubicTo(cx - 4  * sc, cy - 18 * sc,
                cx - 2  * sc, cy - 10 * sc,
                cx + 2  * sc, cy - 8  * sc)
      ..cubicTo(cx + 6  * sc, cy - 18 * sc,
                cx + 4  * sc, cy - 28 * sc,
                cx,           cy - 34 * sc)
      ..cubicTo(cx + 10 * sc, cy - 22 * sc,
                cx + 22 * sc, cy - 10 * sc,
                cx + 20 * sc, cy + 6  * sc)
      ..cubicTo(cx + 18 * sc, cy + 18 * sc,
                cx + 10 * sc, cy + 26 * sc,
                cx,           cy + 26 * sc)
      ..close();
    c.drawPath(path, _fp(fg));
  }

  @override
  bool shouldRepaint(_AppIconPainter o) => o.type != type;
}