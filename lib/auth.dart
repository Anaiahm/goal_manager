import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'app_icon.dart';
import 'firebase_service.dart';

// ─── Avatar color options (kept for legacy reference) ─────────
const kAvatarColors = [
  Color(0xFF5C7A5C), Color(0xFF7C6BAE), Color(0xFF2E6DA4),
  Color(0xFFFF69B4), Color(0xFF00B140), Color(0xFFE8A87C),
  Color(0xFF7ABFB0), Color(0xFFE87C9A), Color(0xFFE8C87C),
];

// ─── Sign In Page ─────────────────────────────────────────────

class SignInPage extends StatefulWidget {
  final void Function(UserProfile, AppTheme, bool) onSignIn;
  final void Function(UserProfile, AppTheme)? onRegistered;

  const SignInPage({
    super.key,
    required this.onSignIn,
    this.onRegistered,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _showPass   = false;
  bool _remember   = false;
  bool _loading    = false;
  String? _error;

  // ── Email/password sign in ───────────────────────────────────
  void _signIn() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass  = _passCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email.'); return;
    }
    if (pass.isEmpty) {
      setState(() => _error = 'Please enter your password.'); return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final user = await FirebaseService.signIn(email: email, password: pass);
      widget.onSignIn(user, user.theme, _remember);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':   msg = 'No account found with that email.';    break;
        case 'wrong-password':   msg = 'Incorrect password.';                  break;
        case 'invalid-credential': msg = 'Incorrect email or password.';       break;
        case 'too-many-requests':  msg = 'Too many attempts. Try again later.'; break;
        default:                 msg = 'Sign in failed. Please try again.';
      }
      setState(() { _error = msg; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Something went wrong. Try again.'; _loading = false; });
    }
  }

  // ── Google sign in ───────────────────────────────────────────
  void _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await FirebaseService.signInWithGoogle();
      if (user == null) {
        setState(() => _loading = false); // user cancelled
        return;
      }
      widget.onSignIn(user, user.theme, _remember);
    } catch (e) {
      setState(() {
        _error   = 'Google sign in failed. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    const c = lightTheme;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),

              // Logo + title
              Center(child: Column(children: [
                Container(width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: c.primaryLight,
                    borderRadius: BorderRadius.circular(20)),
                  child: Center(child: SizedBox(width: 52, height: 52,
                    child: CustomPaint(
                      painter: _RingCheckPainter(c.border, c.primary))))),
                const SizedBox(height: 16),
                Text('Goal*ly',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
                const SizedBox(height: 6),
                Text('Sign in to continue',
                  style: TextStyle(fontSize: 14, color: c.textMuted)),
              ])),
              const SizedBox(height: 40),

              // Error banner
              if (_error != null) ...[
                _errorBanner(_error!, c), const SizedBox(height: 16),
              ],

              // Email
              _fieldLabel('Email', c), const SizedBox(height: 6),
              _textField(_emailCtrl, 'your@email.com', c,
                type: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Password
              _fieldLabel('Password', c), const SizedBox(height: 6),
              _passField(_passCtrl, 'Enter your password', _showPass, c,
                () => setState(() => _showPass = !_showPass)),
              const SizedBox(height: 14),

              // Remember me
              GestureDetector(
                onTap: () => setState(() => _remember = !_remember),
                child: Row(children: [
                  _checkbox(_remember, c),
                  const SizedBox(width: 10),
                  Text('Remember me',
                    style: TextStyle(fontSize: 14, color: c.textPrimary)),
                ])),
              const SizedBox(height: 28),

              // Sign in button
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Text('Sign In',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
              const SizedBox(height: 16),

              // Or divider
              Row(children: [
                Expanded(child: Divider(color: c.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                    style: TextStyle(fontSize: 13, color: c.textMuted))),
                Expanded(child: Divider(color: c.border)),
              ]),
              const SizedBox(height: 16),

              // Google sign in button
              SizedBox(width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: c.surface,
                  ),
                  onPressed: _loading ? null : _signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20,
                        child: CustomPaint(painter: _GoogleLogoPainter())),
                      const SizedBox(width: 12),
                      Text('Continue with Google',
                        style: TextStyle(fontSize: 15,
                          color: c.textPrimary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
              const SizedBox(height: 20),

              // Sign up link
              Center(child: GestureDetector(
                onTap: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => SignUpWizard(
                    onComplete: (user, theme) {
                      widget.onRegistered?.call(user, theme);
                      widget.onSignIn(user, theme, false);
                    },
                  ))),
                child: RichText(text: TextSpan(
                  style: TextStyle(fontSize: 14, color: c.textMuted),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(text: 'Sign up',
                      style: TextStyle(
                        color: c.primary, fontWeight: FontWeight.w600)),
                  ])))),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Sign Up Wizard ───────────────────────────────────────────

class SignUpWizard extends StatefulWidget {
  final void Function(UserProfile, AppTheme) onComplete;
  const SignUpWizard({super.key, required this.onComplete});
  @override
  State<SignUpWizard> createState() => _SignUpWizardState();
}

class _SignUpWizardState extends State<SignUpWizard> {
  int _step = 0;

  // Step 1
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _showPass   = false;
  bool _showConf   = false;

  // Step 2
  int _avatarColor = 0;

  // Step 3
  AppTheme _theme = AppTheme.light;

  String? _error;

  ThemeColors get _c => allThemes[allThemeEnums.indexOf(_theme)];

  void _nextStep() {
    setState(() => _error = null);

    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Name is required.'); return;
      }
      if (!_emailCtrl.text.contains('@')) {
        setState(() => _error = 'Enter a valid email.'); return;
      }
      if (_passCtrl.text.length < 6) {
        setState(() => _error = 'Password must be 6+ characters.'); return;
      }
      if (_passCtrl.text != _confCtrl.text) {
        setState(() => _error = 'Passwords do not match.'); return;
      }
    }

    if (_step < 3) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _finish() async {
    if (!mounted) return;
    setState(() {});

    try {
      final user = await FirebaseService.signUp(
        name:            _nameCtrl.text.trim(),
        email:           _emailCtrl.text.trim(),
        password:        _passCtrl.text,
        avatarIconIndex: _avatarColor,
        appThemeIndex:   AppTheme.values.indexOf(_theme),
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete(user, _theme);
        });
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use': msg = 'An account already exists with that email.'; break;
        case 'weak-password':        msg = 'Password is too weak. Use 6+ characters.';   break;
        case 'invalid-email':        msg = 'Please enter a valid email address.';        break;
        default:                     msg = 'Sign up failed. Please try again.';
      }
      if (mounted) setState(() => _error = msg);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final c = _c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.primary),
          onPressed: _step == 0
            ? () => Navigator.pop(ctx)
            : () => setState(() { _step--; _error = null; })),
        title: Text('Create account',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(children: [
            // Progress bar
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: List.generate(4, (i) => Expanded(child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= _step ? c.primary : c.border,
                    borderRadius: BorderRadius.circular(2)))))),
                const SizedBox(height: 8),
                Text('Step ${_step + 1} of 4',
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
              ])),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStep(ctx, c))),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext ctx, ThemeColors c) {
    switch (_step) {
      case 0:  return _step1(c);
      case 1:  return _step2(c);
      case 2:  return _step3(c);
      case 3:  return _step4(c);
      default: return const SizedBox();
    }
  }

  // ── Step 1: Account details ──────────────────────────────────
  Widget _step1(ThemeColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Account details',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)),
      const SizedBox(height: 6),
      Text('Set up your login credentials',
        style: TextStyle(fontSize: 14, color: c.textMuted)),
      const SizedBox(height: 28),
      if (_error != null) ...[_errorBanner(_error!, c), const SizedBox(height: 16)],
      _fieldLabel('Full Name', c), const SizedBox(height: 6),
      _textField(_nameCtrl, 'Your name', c),
      const SizedBox(height: 16),
      _fieldLabel('Email', c), const SizedBox(height: 6),
      _textField(_emailCtrl, 'your@email.com', c, type: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _fieldLabel('Password', c), const SizedBox(height: 6),
      _passField(_passCtrl, 'Min 6 characters', _showPass, c,
        () => setState(() => _showPass = !_showPass)),
      const SizedBox(height: 16),
      _fieldLabel('Confirm Password', c), const SizedBox(height: 6),
      _passField(_confCtrl, 'Re-enter password', _showConf, c,
        () => setState(() => _showConf = !_showConf)),
      const SizedBox(height: 32),
      _nextButton('Continue', c),
    ]);

  // ── Step 2: App icon picker ──────────────────────────────────
  Widget _step2(ThemeColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Choose your app icon',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)),
      const SizedBox(height: 6),
      Text('Pick the icon that fits your vibe',
        style: TextStyle(fontSize: 14, color: c.textMuted)),
      const SizedBox(height: 32),
      Center(child: AppIconWidget(index: _avatarColor, size: 96)),
      const SizedBox(height: 28),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: List.generate(kAppIcons.length, (i) {
          final sel = _avatarColor == i;
          return GestureDetector(
            onTap: () => setState(() => _avatarColor = i),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: sel ? c.primary : Colors.transparent, width: 3)),
                child: AppIconWidget(index: i, size: 64)),
              const SizedBox(height: 6),
              Text(kAppIcons[i].label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: sel ? c.primary : c.textMuted)),
            ]),
          );
        }),
      ),
      const SizedBox(height: 40),
      _nextButton('Continue', c),
    ]);

  // ── Step 3: Theme picker ─────────────────────────────────────
  Widget _step3(ThemeColors c) {
    const labels = ['Light', 'Dark', 'Colorful', 'MAN*LY', 'Pink', 'Kelly'];
    const icons  = [
      Icons.wb_sunny_outlined, Icons.nightlight_outlined,
      Icons.palette_outlined,  Icons.bolt_outlined,
      Icons.favorite_outline,  Icons.business_outlined,
    ];
    const previews = [
      [Color(0xFFF5F2EF), Color(0xFF5C7A5C)],
      [Color(0xFF121212), Color(0xFF7A9A7A)],
      [Color(0xFFFDF6F0), Color(0xFF7C6BAE)],
      [Color(0xFF0D0D0D), Color(0xFF2E6DA4)],
      [Color(0xFFFFF0F6), Color(0xFFFF69B4)],
      [Color(0xFFF5FDF7), Color(0xFF00B140)],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose your theme',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)),
      const SizedBox(height: 6),
      Text('You can change this anytime in Settings',
        style: TextStyle(fontSize: 14, color: c.textMuted)),
      const SizedBox(height: 28),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: List.generate(6, (i) {
          final t   = allThemeEnums[i];
          final sel = _theme == t;
          return GestureDetector(
            onTap: () => setState(() => _theme = t),
            child: Container(
              decoration: BoxDecoration(
                color: previews[i][0],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? previews[i][1] : c.border,
                  width: sel ? 2.5 : 1)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: previews[i][1],
                      borderRadius: BorderRadius.circular(8)),
                    child: Icon(icons[i], size: 14, color: Colors.white)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(labels[i],
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: i == 1 || i == 3
                        ? Colors.white : const Color(0xFF2C2A27)))),
                  if (sel) Icon(Icons.check_circle, size: 16, color: previews[i][1]),
                ]),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 32),
      _nextButton('Continue', c),
    ]);
  }

  // ── Step 4: Welcome ──────────────────────────────────────────
  Widget _step4(ThemeColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 20),
      AppIconWidget(index: _avatarColor, size: 104),
      const SizedBox(height: 24),
      Text('Welcome, ${_nameCtrl.text.trim().split(' ').first}! 🎉',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.textPrimary),
        textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text("You're all set. Let's start reaching your goals.",
        style: TextStyle(fontSize: 15, color: c.textMuted),
        textAlign: TextAlign.center),
      const SizedBox(height: 40),
      Container(
        padding: const EdgeInsets.all(16), width: double.infinity,
        decoration: BoxDecoration(
          color: c.primaryLight, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _summaryRow(c, Icons.person_outline,  'Name',  _nameCtrl.text.trim()),
          const SizedBox(height: 8),
          _summaryRow(c, Icons.email_outlined,   'Email', _emailCtrl.text.trim()),
          const SizedBox(height: 8),
          _summaryRow(c, Icons.palette_outlined, 'Theme',
            const ['Light','Dark','Colorful','MAN*LY','Pink','Kelly']
              [allThemeEnums.indexOf(_theme)]),
        ])),
      const SizedBox(height: 32),
      _nextButton("Let's go →", c),
    ]);

  Widget _summaryRow(ThemeColors c, IconData icon, String label, String value) =>
    Row(children: [
      Icon(icon, size: 16, color: c.primary),
      const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(fontSize: 13, color: c.textMuted)),
      Expanded(child: Text(value,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
        overflow: TextOverflow.ellipsis)),
    ]);

  Widget _nextButton(String label, ThemeColors c) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 15)),
      onPressed: _nextStep,
      child: Text(label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ));
}

// ─── Shared helpers ───────────────────────────────────────────

class _RingCheckPainter extends CustomPainter {
  final Color bg, fg;
  const _RingCheckPainter(this.bg, this.fg);
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2; final cy = s.height / 2; final r = s.width / 2 - 3;
    c.drawCircle(Offset(cx, cy), r,
      Paint()..color = bg..style = PaintingStyle.stroke..strokeWidth = 4.5);
    c.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -3.14159 / 2, 2 * 3.14159 * 0.75, false,
      Paint()..color = fg..style = PaintingStyle.stroke
        ..strokeWidth = 4.5..strokeCap = StrokeCap.round);
    final p = Path()
      ..moveTo(cx - 10, cy + 1)
      ..lineTo(cx - 2,  cy + 9)
      ..lineTo(cx + 12, cy - 9);
    c.drawPath(p, Paint()..color = fg..style = PaintingStyle.stroke
      ..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }
  @override bool shouldRepaint(_) => false;
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  / 2;

    final blue   = Paint()..color = const Color(0xFF4285F4);
    final green  = Paint()..color = const Color(0xFF34A853);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final red    = Paint()..color = const Color(0xFFEA4335);

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.3,  1.6, true, blue);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  1.3,  1.6, true, green);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  2.9,  1.0, true, yellow);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  3.9,  1.7, true, red);

    canvas.drawCircle(Offset(cx, cy), r * 0.6,
      Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.15, r, r * 0.3), blue);
  }
  @override bool shouldRepaint(_) => false;
}

Widget _errorBanner(String msg, ThemeColors c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: c.danger.withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: c.danger.withOpacity(0.4))),
  child: Row(children: [
    Icon(Icons.error_outline, size: 16, color: c.danger),
    const SizedBox(width: 8),
    Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: c.danger))),
  ]));

Widget _fieldLabel(String label, ThemeColors c) =>
  Text(label, style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500));

Widget _textField(TextEditingController ctrl, String hint, ThemeColors c,
    {TextInputType type = TextInputType.text}) =>
  TextField(controller: ctrl, keyboardType: type,
    style: TextStyle(color: c.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
      filled: true, fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)));

Widget _passField(TextEditingController ctrl, String hint, bool visible,
    ThemeColors c, VoidCallback toggle) =>
  TextField(controller: ctrl, obscureText: !visible,
    style: TextStyle(color: c.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
      filled: true, fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: IconButton(
        icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18, color: c.textMuted),
        onPressed: toggle)));

Widget _checkbox(bool checked, ThemeColors c) => Container(
  width: 20, height: 20,
  decoration: BoxDecoration(
    color: checked ? c.primary : Colors.transparent,
    border: Border.all(color: checked ? c.primary : c.border, width: 1.5),
    borderRadius: BorderRadius.circular(5)),
  child: checked ? const Icon(Icons.check, size: 13, color: Colors.white) : null);