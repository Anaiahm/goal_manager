import 'package:flutter/material.dart';
import 'models.dart';

// ─── Avatar options ───────────────────────────────────────────
const kAvatarColors = [
  Color(0xFF5C7A5C), Color(0xFF7C6BAE), Color(0xFF2E6DA4),
  Color(0xFFFF69B4), Color(0xFF00B140), Color(0xFFE8A87C),
  Color(0xFF7ABFB0), Color(0xFFE87C9A), Color(0xFFE8C87C),
];

// ─── Sign In Page ─────────────────────────────────────────────

class SignInPage extends StatefulWidget {
  final Map<String, UserProfile> accounts;
  final void Function(UserProfile, AppTheme, bool) onSignIn;
  final void Function(UserProfile, AppTheme)? onRegistered;

  const SignInPage({
    super.key,
    required this.accounts,
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
    await Future.delayed(const Duration(milliseconds: 600));

    final account = widget.accounts[email];
    if (account != null && account.password == pass) {
      widget.onSignIn(account, AppTheme.light, _remember);
    } else {
      setState(() { _error = 'Incorrect email or password.'; _loading = false; });
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
                  decoration: BoxDecoration(color: c.primaryLight,
                    borderRadius: BorderRadius.circular(20)),
                  child: Center(child: SizedBox(width: 52, height: 52,
                    child: CustomPaint(
                      painter: _RingCheckPainter(c.border, c.primary))))),
                const SizedBox(height: 16),
                Text('Goal Manager', style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 6),
                Text('Sign in to continue',
                  style: TextStyle(fontSize: 14, color: c.textMuted)),
              ])),
              const SizedBox(height: 40),

              if (_error != null) ...[
                _errorBanner(_error!, c), const SizedBox(height: 16),
              ],

              _fieldLabel('Email', c), const SizedBox(height: 6),
              _textField(_emailCtrl, 'your@email.com', c,
                type: TextInputType.emailAddress),
              const SizedBox(height: 16),

              _fieldLabel('Password', c), const SizedBox(height: 6),
              _passField(_passCtrl, 'Enter your password', _showPass, c,
                () => setState(() => _showPass = !_showPass)),
              const SizedBox(height: 14),

              GestureDetector(
                onTap: () => setState(() => _remember = !_remember),
                child: Row(children: [
                  _checkbox(_remember, c),
                  const SizedBox(width: 10),
                  Text('Remember me',
                    style: TextStyle(fontSize: 14, color: c.textPrimary)),
                ])),
              const SizedBox(height: 28),

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
              const SizedBox(height: 20),

              Center(child: GestureDetector(
                onTap: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => SignUpWizard(
                    onComplete: (user, theme) {
                      widget.onRegistered?.call(user, theme);
                      // Pre-fill email after sign up
                      _emailCtrl.text = user.email;
                      _passCtrl.text  = user.password;
                    },
                  ))),
                child: RichText(text: TextSpan(
                  style: TextStyle(fontSize: 14, color: c.textMuted),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(text: 'Sign up',
                      style: TextStyle(color: c.primary, fontWeight: FontWeight.w600)),
                  ])))),
              const SizedBox(height: 12),

              Center(child: Text(
                'Demo: demo@goalmanager.app / password123',
                style: TextStyle(fontSize: 11, color: c.textMuted))),
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
  final _nameCtrl  = TextEditingController();
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

  void _finish() {
    final user = UserProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      avatarColorIndex: _avatarColor,
    );
    final theme = _theme;

    // Pop the wizard first, THEN call onComplete
    // This ensures the widget is unmounted cleanly before triggering
    // any parent state changes
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Use addPostFrameCallback so the navigation completes
      // before we trigger the parent rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete(user, theme);
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final c = _c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface, elevation: 0,
        leading: _step == 0
          ? IconButton(icon: Icon(Icons.arrow_back, color: c.primary),
              onPressed: () => Navigator.pop(ctx))
          : IconButton(icon: Icon(Icons.arrow_back, color: c.primary),
              onPressed: () => setState(() { _step--; _error = null; })),
        title: Text('Create account', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(children: [
            // Progress bar
            Container(color: c.surface, padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: List.generate(4, (i) => Expanded(child: Container(
                  height: 4, margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= _step ? c.primary : c.border,
                    borderRadius: BorderRadius.circular(2))))),
                ),
                const SizedBox(height: 8),
                Text('Step ${_step + 1} of 4', style: TextStyle(fontSize: 12, color: c.textMuted)),
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
      case 0: return _step1(c);
      case 1: return _step2(c);
      case 2: return _step3(c);
      case 3: return _step4(c);
      default: return const SizedBox();
    }
  }

  // ── Step 1: Account details ──────────────────────────────────
  Widget _step1(ThemeColors c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Account details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)),
    const SizedBox(height: 6),
    Text('Set up your login credentials', style: TextStyle(fontSize: 14, color: c.textMuted)),
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

  // ── Step 2: Avatar ───────────────────────────────────────────
  Widget _step2(ThemeColors c) {
    final initials = _nameCtrl.text.trim().isNotEmpty
      ? UserProfile(name: _nameCtrl.text.trim(), email: '', password: '').initials
      : '?';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose your avatar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)),
      const SizedBox(height: 6),
      Text('Pick a color for your profile', style: TextStyle(fontSize: 14, color: c.textMuted)),
      const SizedBox(height: 32),
      // Large preview
      Center(child: CircleAvatar(radius: 48,
        backgroundColor: kAvatarColors[_avatarColor],
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 28),
      // Color grid
      Center(child: Wrap(spacing: 14, runSpacing: 14,
        children: List.generate(kAvatarColors.length, (i) => GestureDetector(
          onTap: () => setState(() => _avatarColor = i),
          child: Container(width: 48, height: 48,
            decoration: BoxDecoration(
              color: kAvatarColors[i],
              shape: BoxShape.circle,
              border: Border.all(
                color: _avatarColor == i ? c.textPrimary : Colors.transparent,
                width: 3)),
            child: _avatarColor == i
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : null),
        )))),
      const SizedBox(height: 40),
      _nextButton('Continue', c),
    ]);
  }

  // ── Step 3: Theme ────────────────────────────────────────────
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
      Text('Choose your theme', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)),
      const SizedBox(height: 6),
      Text('You can change this anytime in Settings', style: TextStyle(fontSize: 14, color: c.textMuted)),
      const SizedBox(height: 28),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.8,
        children: List.generate(6, (i) {
          final t   = allThemeEnums[i];
          final sel = _theme == t;
          return GestureDetector(
            onTap: () => setState(() => _theme = t),
            child: Container(
              decoration: BoxDecoration(
                color: previews[i][0],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? previews[i][1] : c.border, width: sel ? 2.5 : 1)),
              child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(
                  color: previews[i][1], borderRadius: BorderRadius.circular(8)),
                  child: Icon(icons[i], size: 14, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(child: Text(labels[i], style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: i == 1 || i == 3 ? Colors.white : const Color(0xFF2C2A27)))),
                if (sel) Icon(Icons.check_circle, size: 16, color: previews[i][1]),
              ])),
            ),
          );
        }),
      ),
      const SizedBox(height: 32),
      _nextButton('Continue', c),
    ]);
  }

  // ── Step 4: Welcome ──────────────────────────────────────────
  Widget _step4(ThemeColors c) {
    final initials = UserProfile(name: _nameCtrl.text.trim(), email: '', password: '').initials;
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const SizedBox(height: 20),
      CircleAvatar(radius: 52,
        backgroundColor: kAvatarColors[_avatarColor],
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
      const SizedBox(height: 24),
      Text('Welcome, ${_nameCtrl.text.trim().split(' ').first}! 🎉',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.textPrimary),
        textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text("You're all set. Let's start reaching your goals.",
        style: TextStyle(fontSize: 15, color: c.textMuted), textAlign: TextAlign.center),
      const SizedBox(height: 40),
      Container(padding: const EdgeInsets.all(16), width: double.infinity,
        decoration: BoxDecoration(color: c.primaryLight, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _summaryRow(c, Icons.person_outline, 'Name', _nameCtrl.text.trim()),
          const SizedBox(height: 8),
          _summaryRow(c, Icons.email_outlined, 'Email', _emailCtrl.text.trim()),
          const SizedBox(height: 8),
          _summaryRow(c, Icons.palette_outlined, 'Theme',
            const ['Light','Dark','Colorful','MAN*LY','Pink','Kelly'][allThemeEnums.indexOf(_theme)]),
        ])),
      const SizedBox(height: 32),
      _nextButton("Let's go →", c),
    ]);
  }

  Widget _summaryRow(ThemeColors c, IconData icon, String label, String value) =>
    Row(children: [
      Icon(icon, size: 16, color: c.primary),
      const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(fontSize: 13, color: c.textMuted)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
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
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ));
}

// ─── Shared helpers ───────────────────────────────────────────

class _RingCheckPainter extends CustomPainter {
  final Color bg, fg;
  const _RingCheckPainter(this.bg, this.fg);
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width/2; final cy = s.height/2; final r = s.width/2 - 3;
    c.drawCircle(Offset(cx,cy), r, Paint()..color=bg..style=PaintingStyle.stroke..strokeWidth=4.5);
    c.drawArc(Rect.fromCircle(center: Offset(cx,cy), radius: r),
      -3.14159/2, 2*3.14159*0.75, false,
      Paint()..color=fg..style=PaintingStyle.stroke..strokeWidth=4.5..strokeCap=StrokeCap.round);
    final p = Path()..moveTo(cx-10,cy+1)..lineTo(cx-2,cy+9)..lineTo(cx+12,cy-9);
    c.drawPath(p, Paint()..color=fg..style=PaintingStyle.stroke..strokeWidth=4
      ..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
  }
  @override bool shouldRepaint(_) => false;
}

Widget _errorBanner(String msg, ThemeColors c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: c.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
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
    decoration: InputDecoration(hintText: hint,
      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
      filled: true, fillColor: c.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)));

Widget _passField(TextEditingController ctrl, String hint, bool visible,
    ThemeColors c, VoidCallback toggle) =>
  TextField(controller: ctrl, obscureText: !visible,
    style: TextStyle(color: c.textPrimary, fontSize: 14),
    decoration: InputDecoration(hintText: hint,
      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
      filled: true, fillColor: c.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.primary)),
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