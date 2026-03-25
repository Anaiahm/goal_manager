import 'package:flutter/material.dart';
import 'models.dart';

void main() => runApp(const GoalManagerApp());

// ─── App Root ─────────────────────────────────────────────────────────────────

class GoalManagerApp extends StatefulWidget {
  const GoalManagerApp({super.key});
  @override
  State<GoalManagerApp> createState() => _GoalManagerAppState();
}

class _GoalManagerAppState extends State<GoalManagerApp> {
  final _themeNotifier = ValueNotifier<AppTheme>(AppTheme.light);

  @override
  Widget build(BuildContext ctx) {
    return AppThemeNotifier(
      notifier: _themeNotifier,
      child: ValueListenableBuilder<AppTheme>(
        valueListenable: _themeNotifier,
        builder: (ctx, theme, _) {
          final c = allThemes[allThemeEnums.indexOf(theme)];
          final isDark = theme == AppTheme.dark || theme == AppTheme.manly;
          return MaterialApp(
            title: 'Goal Manager',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: c.primary,
                brightness: isDark ? Brightness.dark : Brightness.light,
              ),
              scaffoldBackgroundColor: c.background,
              useMaterial3: true,
            ),
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

// ─── Main Shell ───────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  List<Goal> _goals = sampleGoals();
  final Map<int, DayData> _week = sampleWeek();
  final List<HabitEntry> _habits = sampleHabits();
  late List<GoalTask> _weeklyTodos = sampleWeeklyTodos();
  UserProfile _user = defaultUser;

  void _upsertGoal(Goal g) => setState(() {
    final i = _goals.indexWhere((x) => x.id == g.id);
    if (i >= 0) { _goals[i] = g; } else { _goals.add(g); }
  });

  // Adds a new event to the correct weekday slot
  void _onEventAdded(DayEvent event) {
    setState(() {
      final weekday = event.date.weekday - 1; // Mon=0 … Sun=6
      final data    = _week[weekday]!;
      _week[weekday] = DayData(
        focus:  data.focus,
        events: [...data.events, event],
        tasks:  data.tasks,
      );
    });
  }

  void _onEventEdited(DayEvent oldEvent, DayEvent newEvent) {
    setState(() {
      for (int di = 0; di < 7; di++) {
        final data = _week[di]!;
        final idx  = data.events.indexWhere((e) =>
          e.title == oldEvent.title &&
          e.time  == oldEvent.time  &&
          e.date.day   == oldEvent.date.day   &&
          e.date.month == oldEvent.date.month &&
          e.date.year  == oldEvent.date.year);
        if (idx >= 0) {
          final updated = List<DayEvent>.from(data.events);
          updated[idx] = newEvent;
          _week[di] = DayData(focus: data.focus, events: updated, tasks: data.tasks);
          break;
        }
      }
    });
  }

  void _onEventDeleted(DayEvent event) {
    setState(() {
      for (int di = 0; di < 7; di++) {
        final data = _week[di]!;
        final before = data.events.length;
        final updated = data.events.where((e) =>
          !(e.title == event.title &&
            e.time  == event.time  &&
            e.date.day   == event.date.day   &&
            e.date.month == event.date.month &&
            e.date.year  == event.date.year)).toList();
        if (updated.length < before) {
          _week[di] = DayData(focus: data.focus, events: updated, tasks: data.tasks);
          break;
        }
      }
    });
  }

  static const _labels = ['Dashboard', 'Weekly', 'Calendar', 'Goals', 'Settings'];
  static const _icons  = [
    Icons.grid_view_rounded, Icons.view_week_outlined,
    Icons.calendar_month_outlined, Icons.flag_outlined, Icons.settings_outlined,
  ];

@override
  Widget build(BuildContext ctx) {
    final c       = colorsOf(ctx);
    final wide    = MediaQuery.of(ctx).size.width >= kMobileBreak;
    final pages   = [
      DashboardPage(user: _user, goals: _goals, onGoalTap: _goToGoal, onAdd: _goToAdd),
      WeeklyPage(
        week: _week, habits: _habits, weeklyTodos: _weeklyTodos,
        onTodosChanged: (t) => setState(() => _weeklyTodos = t),
        onWeekChanged:  (d, data) => setState(() => _week[d] = data),
      ),
      CalendarPage(
        goals: _goals, week: _week,
        onEventAdded: _onEventAdded,
        onEventEdited: _onEventEdited,
        onEventDeleted: _onEventDeleted,
      ),
      GoalsListPage(goals: _goals, onGoalTap: _goToGoal, onAdd: _goToAdd),
      SettingsPage(user: _user, onUserChanged: (u) => setState(() => _user = u)),
    ];

    const labels = ['Dashboard', 'Weekly', 'Calendar', 'Goals', 'Settings'];
    const icons  = [
      Icons.grid_view_rounded, Icons.view_week_outlined,
      Icons.calendar_month_outlined, Icons.flag_outlined, Icons.settings_outlined,
    ];

    // ── Desktop layout: persistent left sidebar ──────────────
    if (wide) {
      return Scaffold(
        backgroundColor: c.background,
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 200,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(right: BorderSide(color: c.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title / logo area
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                    child: Text('Goal Manager',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: c.primary)),
                  ),
                  Divider(height: 1, color: c.border),
                  const SizedBox(height: 8),
                  // Nav items
                  ...List.generate(5, (i) {
                    final sel = _tab == i;
                    return GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: sel ? c.primaryLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(icons[i], size: 18,
                            color: sel ? c.primary : c.textMuted),
                          const SizedBox(width: 12),
                          Text(labels[i],
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                              color: sel ? c.primary : c.textMuted)),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Main content — centered + constrained
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxWidth),
                  child: pages[_tab],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile layout: bottom nav bar (unchanged) ────────────
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: c.surface,
        indicatorColor: c.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(5, (i) => NavigationDestination(
          icon: Icon(icons[i], color: c.textMuted),
          selectedIcon: Icon(icons[i], color: c.primary),
          label: labels[i],
        )),
      ),
    );
  }


  void _goToGoal(Goal g) => Navigator.push(context,
    MaterialPageRoute(builder: (_) => GoalDetailPage(goal: g, onUpdate: _upsertGoal)));
  void _goToAdd() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => AddGoalPage(onAdd: _upsertGoal)));
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class AppBar2 extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  const AppBar2({super.key, required this.title, this.actions, this.showBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext ctx) {
    final c    = colorsOf(ctx);
    final wide = MediaQuery.of(ctx).size.width >= kMobileBreak;
    return AppBar(
      backgroundColor: c.surface,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: c.primary),
              onPressed: () => Navigator.pop(ctx),
            )
          : (wide ? const SizedBox.shrink() : null),
      // On desktop hide the hamburger / leading space cleanly
      automaticallyImplyLeading: !wide,
      title: Text(title,
        style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500, fontSize: 18)),
      actions: actions,
    );
  }
}

class SageBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SageBtn({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class Card2 extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const Card2({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

class CheckRow extends StatelessWidget {
  final String text;
  final bool done;
  final void Function(bool) onChanged;
  const CheckRow({super.key, required this.text, required this.done, required this.onChanged});

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return GestureDetector(
      onTap: () => onChanged(!done),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: done ? c.primary : c.border,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: done ? c.textMuted : c.textPrimary,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double pct;
  final Color bg, fg;
  const RingPainter(this.pct, this.bg, this.fg);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 4;
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = bg..style = PaintingStyle.stroke..strokeWidth = 5,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -3.14159 / 2,
      2 * 3.14159 * pct,
      false,
      Paint()..color = fg..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(RingPainter o) => o.pct != pct;
}

class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final int? total;
  const SectionHeader({super.key, required this.title, required this.count, this.total});

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const SizedBox(width: 8),
        Text(
          total != null ? '$count / $total' : '$count',
          style: TextStyle(fontSize: 12, color: c.textMuted),
        ),
      ],
    );
  }
}

Widget inputField(
  BuildContext ctx,
  TextEditingController ctrl,
  String hint, {
  String? prefix,
  TextInputType type = TextInputType.text,
}) {
  final c = colorsOf(ctx);
  return TextField(
    controller: ctrl,
    keyboardType: type,
    style: TextStyle(color: c.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

const double kMobileBreak  = 600;
const double kMaxWidth     = 900;  // max content width on desktop

class Responsive extends StatelessWidget {
  final Widget child;
  const Responsive({super.key, required this.child});

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= kMobileBreak;

  @override
  Widget build(BuildContext ctx) {
    final wide = MediaQuery.of(ctx).size.width >= kMobileBreak;
    if (!wide) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxWidth),
        child: child,
      ),
    );
  }
}
// ─── Goal Card ────────────────────────────────────────────────────────────────

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  const GoalCard({super.key, required this.goal, required this.onTap});

  @override
  Widget build(BuildContext ctx) {
    final c   = colorsOf(ctx);
    final pct = (goal.pct * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + ring
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 52, height: 52,
                  child: CustomPaint(
                    painter: RingPainter(goal.pct, c.border, c.primary),
                    child: Center(
                      child: Text(
                        '$pct%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$pct% Saved',
              style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: goal.pct, minHeight: 4, color: c.primary, backgroundColor: c.border,
              ),
            ),
            const SizedBox(height: 8),
            // Tasks preview
            ...goal.tasks.take(3).map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      t.done ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 13,
                      color: t.done ? c.primary : c.border,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        t.text,
                        style: TextStyle(
                          fontSize: 11,
                          color: t.done ? c.textMuted : c.textPrimary,
                          decoration: t.done ? TextDecoration.lineThrough : null,
                          decorationColor: c.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),         // ← replaces Spacer()
            Text(
              'View Goal →',
              style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class DashboardPage extends StatelessWidget {
  final UserProfile user;                                   // ← NEW
  final List<Goal> goals;
  final void Function(Goal) onGoalTap;
  final VoidCallback onAdd;
  const DashboardPage({
    super.key,
    required this.user,                                     // ← NEW
    required this.goals,
    required this.onGoalTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext ctx) {
    final c          = colorsOf(ctx);
    final totalSaved = goals.fold(0.0, (s, g) => s + g.saved);
    final onTrack    = goals.where((g) => g.pct >= 0.4).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(
        title: 'Hi, ${user.name.split(' ').first}',         // ← uses real name
        actions: [
          CircleAvatar(
            radius: 17,
            backgroundColor: c.primaryLight,
            child: Text(
              user.initials,                                // ← uses real initials
              style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 28 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              StatCard(label: 'Total Goals', value: '${goals.length}'),
              const SizedBox(width: 10),
              StatCard(label: 'Total Saved', value: '\$${totalSaved.toStringAsFixed(0)}'),
              const SizedBox(width: 10),
              StatCard(label: 'On Track',    value: '$onTrack On Track'),
            ]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Goals', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary)),
                SageBtn(label: '+ Add Goal', onTap: onAdd),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
              ),
              itemCount: goals.length,
              itemBuilder: (_, i) => GoalCard(goal: goals[i], onTap: () => onGoalTap(goals[i])),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label, value;
  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ─── Weekly View ──────────────────────────────────────────────────────────────


class WeeklyPage extends StatefulWidget {
  final Map<int, DayData> week;
  final List<HabitEntry> habits;
  final List<GoalTask> weeklyTodos;
  final void Function(List<GoalTask>) onTodosChanged;
  final void Function(int, DayData) onWeekChanged;

  const WeeklyPage({
    super.key,
    required this.week,
    required this.habits,
    required this.weeklyTodos,
    required this.onTodosChanged,
    required this.onWeekChanged,
  });

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage> {
  static const _short = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _dayAccents = [
    Color(0xFFE8A87C), Color(0xFF7C6BAE), Color(0xFF7ABFB0),
    Color(0xFFE87C9A), Color(0xFFE8C87C), Color(0xFF7CA8E8), Color(0xFF9AE87C),
  ];

  DateTime get _weekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }
  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  String _fmtDate(DateTime d) => '${_mn(d.month)} ${d.day}, ${d.year}';
  String _mn(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun',
                                  'Jul','Aug','Sep','Oct','Nov','Dec'][m];

  void _toggleHabit(int hi, int di) => setState(() =>
    widget.habits[hi].days[di] = !widget.habits[hi].days[di]);

  void _toggleTodo(GoalTask t) => widget.onTodosChanged(
    widget.weeklyTodos.map((x) => x.id == t.id ? x.copyWith(done: !x.done) : x).toList());

  void _toggleDayTask(int di, GoalTask t) {
    final data  = widget.week[di]!;
    final tasks = data.tasks.map((x) => x.id == t.id ? x.copyWith(done: !x.done) : x).toList();
    widget.onWeekChanged(di, DayData(focus: data.focus, events: data.events, tasks: tasks));
  }

  @override
  Widget build(BuildContext ctx) {
    final c          = colorsOf(ctx);
    final isColorful = AppThemeNotifier.of(ctx).value == AppTheme.colorful;
    
final double availableW = MediaQuery.of(ctx).size.width >= kMobileBreak
    ? MediaQuery.of(ctx).size.width - 200  // subtract sidebar width
    : MediaQuery.of(ctx).size.width;
final double leftW = availableW * 0.275;
final double dayW  = (availableW - leftW) / 7;
    // Left column = 27.5% of screen width (was ~220px fixed)

    final totalChecks = widget.habits.fold(0, (s, h) => s + h.days.where((d) => d).length);
    final maxChecks   = widget.habits.length * 7;
    final habitPct    = maxChecks > 0 ? totalChecks / maxChecks : 0.0;
    final doneTodos   = widget.weeklyTodos.where((t) => t.done).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(title: 'Weekly Plan'),
      body: SingleChildScrollView(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── LEFT COLUMN ─────────────────────────────────────
              SizedBox(
                width: leftW,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border(right: BorderSide(color: c.border, width: 1.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        color: c.primary,
                        child: Text('WEEKLY PLAN',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 1.2)),
                      ),

                      // Week dates
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                        child: Column(children: [
                          _dateChip(c, 'WEEK START', _fmtDate(_weekStart), leftW),
                          const SizedBox(height: 6),
                          _dateChip(c, 'WEEK END',   _fmtDate(_weekEnd),   leftW),
                        ]),
                      ),

                      // Habits header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('WEEKLY HABITS',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                color: c.textMuted, letterSpacing: 1)),
                            Text('${(habitPct * 100).round()}%',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: c.primary)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: habitPct, minHeight: 3,
                            color: c.primary, backgroundColor: c.border),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Day letter headers for habits
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: LayoutBuilder(builder: (ctx, cons) {
                          // space left after habit name column
                          const nameW = 0.52; // 52% for name
                          final boxW  = cons.maxWidth * (1 - nameW) / 7;
                          return Row(children: [
                            SizedBox(width: cons.maxWidth * nameW),
                            ..._short.asMap().entries.map((e) => SizedBox(
                              width: boxW,
                              child: Center(child: Text(e.value[0],
                                style: TextStyle(fontSize: 8,
                                  color: isColorful ? _dayAccents[e.key] : c.textMuted,
                                  fontWeight: FontWeight.w700))),
                            )),
                          ]);
                        }),
                      ),
                      const SizedBox(height: 3),

                      // Habit rows
                      ...widget.habits.asMap().entries.map((he) {
                        final hi = he.key; final h = he.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          child: LayoutBuilder(builder: (ctx, cons) {
                            const nameW = 0.52;
                            final boxW  = cons.maxWidth * (1 - nameW) / 7;
                            return Row(children: [
                              SizedBox(
                                width: cons.maxWidth * nameW,
                                child: Text(h.name,
                                  style: TextStyle(fontSize: 10, color: c.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                              ),
                              ...List.generate(7, (di) => GestureDetector(
                                onTap: () => _toggleHabit(hi, di),
                                child: SizedBox(
                                  width: boxW,
                                  child: Center(child: Container(
                                    width: 13, height: 13,
                                    decoration: BoxDecoration(
                                      color: h.days[di]
                                        ? (isColorful ? _dayAccents[di] : c.primary)
                                        : Colors.transparent,
                                      border: Border.all(
                                        color: h.days[di]
                                          ? (isColorful ? _dayAccents[di] : c.primary)
                                          : c.border,
                                        width: 1.2),
                                      borderRadius: BorderRadius.circular(3)),
                                    child: h.days[di]
                                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                                      : null,
                                  )),
                                ),
                              )),
                            ]);
                          }),
                        );
                      }),

                      // Weekly To-Do
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('WEEKLY TO-DO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                color: c.textMuted, letterSpacing: 1)),
                            Text('$doneTodos/${widget.weeklyTodos.length}',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: c.primary)),
                          ],
                        ),
                      ),
                      ...widget.weeklyTodos.map((t) => GestureDetector(
                        onTap: () => _toggleTodo(t),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                          child: Row(children: [
                            Container(
                              width: 13, height: 13,
                              decoration: BoxDecoration(
                                color: t.done ? c.primary : Colors.transparent,
                                border: Border.all(color: t.done ? c.primary : c.border, width: 1.2),
                                borderRadius: BorderRadius.circular(3)),
                              child: t.done
                                ? const Icon(Icons.check, size: 8, color: Colors.white)
                                : null,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(t.text,
                              style: TextStyle(fontSize: 11,
                                color: t.done ? c.textMuted : c.textPrimary,
                                decoration: t.done ? TextDecoration.lineThrough : null,
                                decorationColor: c.textMuted),
                              overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── DAY COLUMNS ──────────────────────────────────────
              ...List.generate(7, (di) {
                final data      = widget.week[di]!;
                final accent    = isColorful ? _dayAccents[di] : c.primary;
                final date      = _weekStart.add(Duration(days: di));
                final doneTasks = data.tasks.where((t) => t.done).length;

                return SizedBox(
                  width: dayW,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: c.border))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Day header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            border: Border(bottom: BorderSide(color: c.border))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_short[di],
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: accent, letterSpacing: 0.8)),
                            Text('${_mn(date.month)} ${date.day}',
                              style: TextStyle(fontSize: 9, color: c.textMuted)),
                          ]),
                        ),

                        // Focus
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.07),
                            border: Border(bottom: BorderSide(color: c.border))),
                          child: Text(data.focus,
                            style: TextStyle(fontSize: 9, color: accent,
                              fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                        ),

                        // Events
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                          child: Text('EVENTS',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                              color: c.textMuted, letterSpacing: 0.8)),
                        ),
                        if (data.events.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                            child: Text('—', style: TextStyle(fontSize: 10, color: c.textMuted)))
                        else
                          ...data.events.map((e) => Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(width: 3, height: 3,
                                margin: const EdgeInsets.only(top: 4, right: 4),
                                decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.time,
                                    style: TextStyle(fontSize: 8, color: c.textMuted)),
                                  Text(e.title,
                                    style: TextStyle(fontSize: 9, color: c.textPrimary),
                                    overflow: TextOverflow.ellipsis, maxLines: 2),
                                ],
                              )),
                            ]),
                          )),

                        // Tasks
                        Container(
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 3),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TASKS',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                  color: c.textMuted, letterSpacing: 0.8)),
                              Text('$doneTasks/${data.tasks.length}',
                                style: TextStyle(fontSize: 8, color: accent, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: data.tasks.isEmpty ? 0 : doneTasks / data.tasks.length,
                              minHeight: 3, color: accent, backgroundColor: c.border),
                          ),
                        ),
                        ...data.tasks.map((t) => GestureDetector(
                          onTap: () => _toggleDayTask(di, t),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 5),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 12, height: 12,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: t.done ? accent : Colors.transparent,
                                  border: Border.all(color: t.done ? accent : c.border, width: 1.1),
                                  borderRadius: BorderRadius.circular(3)),
                                child: t.done
                                  ? const Icon(Icons.check, size: 7, color: Colors.white)
                                  : null,
                              ),
                              const SizedBox(width: 4),
                              Expanded(child: Text(t.text,
                                style: TextStyle(fontSize: 10,
                                  color: t.done ? c.textMuted : c.textPrimary,
                                  decoration: t.done ? TextDecoration.lineThrough : null,
                                  decorationColor: c.textMuted))),
                            ]),
                          ),
                        )),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              }),
            ],
        ),
      ),
    );
  }

  Widget _dateChip(ThemeColors c, String label, String value, double parentW) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
            color: c.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textPrimary),
          overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── Calendar ─────────────────────────────────────────────────────────────────

class CalendarPage extends StatefulWidget {
  final List<Goal> goals;
  final Map<int, DayData> week;
  final void Function(DayEvent) onEventAdded;
  final void Function(DayEvent old, DayEvent updated) onEventEdited;
  final void Function(DayEvent) onEventDeleted;

  const CalendarPage({
    super.key,
    required this.goals,
    required this.week,
    required this.onEventAdded,
    required this.onEventEdited,
    required this.onEventDeleted,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _sel;

  List<Goal> _goalsForDay(DateTime d) => widget.goals.where((g) {
    try {
      final dl = DateTime.parse(g.deadline);
      return dl.year == d.year && dl.month == d.month && dl.day == d.day;
    } catch (_) { return false; }
  }).toList();

  // Pull events for a specific date from the shared week map
  List<DayEvent> _eventsForDay(DateTime d) {
  final weekday = d.weekday - 1; // Mon=0 … Sun=6
  final data = widget.week[weekday];
  if (data == null) return [];
  return data.events.where((e) {
    // guard against any null date
    try {
      return e.date.year  == d.year  &&
             e.date.month == d.month &&
             e.date.day   == d.day;
    } catch (_) {
      return false;
    }
  }).toList();
}

bool _hasEvent(DateTime d) => _eventsForDay(d).isNotEmpty;
  String _mn(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun',
                                  'Jul','Aug','Sep','Oct','Nov','Dec'][m];

  static const _quotes = [
    ("A goal without a plan is just a wish.",                                     "Antoine de Saint-Exupéry"),
    ("The secret of getting ahead is getting started.",                           "Mark Twain"),
    ("It always seems impossible until it's done.",                               "Nelson Mandela"),
    ("Small steps every day lead to big results.",                                "Anonymous"),
    ("You don't have to be great to start, but you have to start to be great.",  "Zig Ziglar"),
    ("Discipline is choosing between what you want now and what you want most.",  "Abraham Lincoln"),
    ("Focus on progress, not perfection.",                                        "Anonymous"),
    ("The best time to plant a tree was 20 years ago. The second best time is now.", "Chinese Proverb"),
  ];

  void _openAddEvent(BuildContext ctx) async {
    final event = await Navigator.push<DayEvent>(
      ctx,
      MaterialPageRoute(
        builder: (_) => AddEventPage(initialDate: _sel),
      ),
    );
    if (event != null) {
      widget.onEventAdded(event);
      setState(() {});
    }
  }

  void _openEventDetail(BuildContext ctx, DayEvent event) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      ctx,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
    if (result == null) return;
    if (result['action'] == 'delete') {
      widget.onEventDeleted(event);
      setState(() {});
    } else if (result['action'] == 'edit') {
      widget.onEventEdited(event, result['event'] as DayEvent);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final c           = colorsOf(ctx);
    final firstDay    = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;
    final quote       = _quotes[DateTime.now().day % _quotes.length];
    final selEvents   = _sel != null ? _eventsForDay(_sel!) : <DayEvent>[];
    final selGoals    = _sel != null ? _goalsForDay(_sel!) : <Goal>[];

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(
        title: 'Calendar',
        actions: [
          GestureDetector(
            onTap: () => _openAddEvent(ctx),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.add, color: Colors.white, size: 15),
                const SizedBox(width: 4),
                const Text('Add Event',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // Month navigator
            Container(
              color: c.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: c.primary),
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1))),
                  Text('${_mn(_month.month)} ${_month.year}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: c.primary),
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1))),
                ],
              ),
            ),

            // Weekday headers
            Container(
              color: c.surface,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: ['M','T','W','T','F','S','S'].map((d) => Expanded(
                  child: Center(child: Text(d,
                    style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w500))),
                )).toList(),
              ),
            ),

            // Day grid
            Container(
              color: c.surface,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
                itemCount: startOffset + daysInMonth,
                itemBuilder: (_, i) {
                  if (i < startOffset) return const SizedBox();
                  final day = DateTime(_month.year, _month.month, i - startOffset + 1);
                  final now     = DateTime.now();
                  final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                  final isSel   = _sel != null &&
                    _sel!.day == day.day && _sel!.month == day.month && _sel!.year == day.year;
                  final hasGoal  = _goalsForDay(day).isNotEmpty;
                  final hasEvent = _hasEvent(day);

                  return GestureDetector(
                    onTap: () => setState(() => _sel = day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel ? c.primary : isToday ? c.primaryLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(20)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${day.day}', style: TextStyle(fontSize: 13,
                          color: isSel ? Colors.white : isToday ? c.primary : c.textPrimary,
                          fontWeight: isToday || isSel ? FontWeight.w600 : FontWeight.w400)),
                        // Two dots: one for goals, one for events
                        if (hasGoal || hasEvent)
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            if (hasGoal) Container(width: 4, height: 4,
                              margin: const EdgeInsets.only(top: 2, right: 2),
                              decoration: BoxDecoration(
                                color: isSel ? Colors.white : c.primary,
                                borderRadius: BorderRadius.circular(2))),
                            if (hasEvent) Container(width: 4, height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: isSel ? Colors.white.withOpacity(0.7) : c.primaryDark,
                                borderRadius: BorderRadius.circular(2))),
                          ]),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // Quote (no date selected)
            if (_sel == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Column(children: [
                  Icon(Icons.format_quote_rounded, size: 32, color: c.primary.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(quote.$1, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic,
                      color: c.textPrimary, height: 1.5)),
                  const SizedBox(height: 10),
                  Text('— ${quote.$2}', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  Text('Tap a date to see events & goals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
                ]),
              ),

// Selected day detail
            if (_sel != null)
              Padding(
                padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 28 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_sel!.day} ${_mn(_sel!.month)} ${_sel!.year}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
                        ),
                        GestureDetector(
                          onTap: () => _openAddEvent(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: c.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(children: [
                              Icon(Icons.add, size: 13, color: c.primary),
                              const SizedBox(width: 3),
                              Text('Event',
                                style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Events
                    if (selEvents.isNotEmpty) ...[
                      Text('Events',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted)),
                      const SizedBox(height: 8),
                      ...selEvents.map((e) => GestureDetector(
                        onTap: () => _openEventDetail(ctx, e),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border),
                          ),
                          child: Row(children: [
                            Icon(Icons.schedule, size: 14, color: c.primary),
                            const SizedBox(width: 8),
                            Text(e.time,
                              style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(e.title,
                              style: TextStyle(fontSize: 13, color: c.textPrimary))),
                            Icon(Icons.chevron_right, size: 16, color: c.textMuted),
                          ]),
                        ),
                      )),
                    ],                          // ← this was the missing ],

                    // Goal deadlines
                    if (selGoals.isNotEmpty) ...[
                      Text('Goal Deadlines',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted)),
                      const SizedBox(height: 8),
                      ...selGoals.map((g) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(children: [
                          SizedBox(
                            width: 44, height: 44,
                            child: CustomPaint(
                              painter: RingPainter(g.pct, c.border, c.primary),
                              child: Center(child: Text(
                                '${(g.pct * 100).round()}%',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.textPrimary),
                              )),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                              Text(
                                '${g.type} · \$${g.saved.toStringAsFixed(0)} / \$${g.target.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 12, color: c.textMuted)),
                            ],
                          )),
                        ]),
                      )),
                    ],

                    // Empty state
                    if (selEvents.isEmpty && selGoals.isEmpty)
                      Text('Nothing scheduled for this day.',
                        style: TextStyle(fontSize: 13, color: c.textMuted)),

                  ],
                ),
              ),

          ],
        ),
      ),
    );
  }
}

// ─── Goals List ───────────────────────────────────────────────────────────────

class GoalsListPage extends StatefulWidget {
  final List<Goal> goals;
  final void Function(Goal) onGoalTap;
  final VoidCallback onAdd;
  const GoalsListPage({super.key, required this.goals, required this.onGoalTap, required this.onAdd});
  @override
  State<GoalsListPage> createState() => _GoalsListPageState();
}

class _GoalsListPageState extends State<GoalsListPage> {
  String _filter = 'All';
  final _types = ['All', 'Financial', 'Personal', 'Habit'];

  @override
  Widget build(BuildContext ctx) {
    final c     = colorsOf(ctx);
    final shown = _filter == 'All'
        ? widget.goals
        : widget.goals.where((g) => g.type == _filter).toList();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(
        title: 'My Goals',
        actions: [SageBtn(label: '+ Add', onTap: widget.onAdd), const SizedBox(width: 12)],
      ),
      body: Column(
        children: [
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _filter == t ? c.primary : c.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _filter == t ? c.primary : c.border),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 13,
                            color: _filter == t ? Colors.white : c.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 28 : 16),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => GoalCard(goal: shown[i], onTap: () => widget.onGoalTap(shown[i])),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Goal Detail ──────────────────────────────────────────────────────────────

class GoalDetailPage extends StatefulWidget {
  final Goal goal;
  final void Function(Goal) onUpdate;
  const GoalDetailPage({super.key, required this.goal, required this.onUpdate});
  @override
  State<GoalDetailPage> createState() => _GoalDetailState();
}

class _GoalDetailState extends State<GoalDetailPage> {
  late Goal _goal;
  final _taskCtrl = TextEditingController();
  final _addCtrl  = TextEditingController();

  @override
  void initState() { super.initState(); _goal = widget.goal; }

  void _save(Goal g) { setState(() => _goal = g); widget.onUpdate(g); }

  @override
  Widget build(BuildContext ctx) {
    final c    = colorsOf(ctx);
    final pct  = (_goal.pct * 100).round();
    final done = _goal.tasks.where((t) => t.done).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(
        title: _goal.name,
        showBack: true,
        actions: [
          IconButton(icon: Icon(Icons.edit_outlined, color: c.primary), onPressed: _edit),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 32 : 20),
        child: Column(
          children: [
            SizedBox(
              width: 120, height: 120,
              child: CustomPaint(
                painter: RingPainter(_goal.pct, c.border, c.primary),
                child: Center(
                  child: Text(
                    '$pct%',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_goal.type} · \$${_goal.target.toStringAsFixed(0)} · ${_goal.deadline}',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_goal.saved.toStringAsFixed(0)} saved of \$${_goal.target.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, color: c.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: inputField(ctx, _addCtrl, 'Add savings amount (\$)', type: TextInputType.number)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    final amt = double.tryParse(_addCtrl.text) ?? 0;
                    if (amt > 0) { _save(_goal.copyWith(saved: _goal.saved + amt)); _addCtrl.clear(); }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: _goal.pct, minHeight: 6, color: c.primary, backgroundColor: c.border),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('To-Do List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                Text('$done / ${_goal.tasks.length} completed', style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            ..._goal.tasks.map(
              (t) => CheckRow(
                text: t.text,
                done: t.done,
                onChanged: (v) => _save(_goal.copyWith(
                  tasks: _goal.tasks.map((x) => x.id == t.id ? x.copyWith(done: v) : x).toList(),
                )),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: inputField(ctx, _taskCtrl, 'Add new task...')),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (_taskCtrl.text.trim().isEmpty) return;
                    _save(_goal.copyWith(tasks: [
                      ..._goal.tasks,
                      GoalTask(id: DateTime.now().millisecondsSinceEpoch, text: _taskCtrl.text.trim()),
                    ]));
                    _taskCtrl.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: c.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.add, color: c.primary, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _save(_goal.copyWith(
                  tasks: _goal.tasks.map((t) => t.copyWith(done: true)).toList(),
                )),
                child: const Text('Mark All Complete', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _edit() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddGoalPage(existing: _goal, onAdd: (g) { _save(g); Navigator.pop(context); }),
    ),
  );
}

// ─── Add / Edit Goal ──────────────────────────────────────────────────────────

class AddGoalPage extends StatefulWidget {
  final Goal? existing;
  final void Function(Goal) onAdd;
  const AddGoalPage({super.key, this.existing, required this.onAdd});
  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  late final _nameCtrl   = TextEditingController(text: widget.existing?.name ?? '');
  late final _targetCtrl = TextEditingController(
    text: widget.existing != null ? widget.existing!.target.toStringAsFixed(0) : '',
  );
  late String _type  = widget.existing?.type ?? 'Financial';
  late DateTime? _dl = widget.existing != null ? DateTime.tryParse(widget.existing!.deadline) : null;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(title: widget.existing != null ? 'Edit Goal' : 'Add Goal', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal Name', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            inputField(ctx, _nameCtrl, 'Enter your goal name...'),
            const SizedBox(height: 18),
            Text('Goal Type', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: ['Financial', 'Personal', 'Habit'].map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _type == t ? c.primary : c.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _type == t ? c.primary : c.border),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 13,
                          color: _type == t ? Colors.white : c.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Target Amount', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            inputField(ctx, _targetCtrl, '0', prefix: '\$ ', type: TextInputType.number),
            const SizedBox(height: 18),
            Text('Target Deadline', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: _dl ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  builder: (c2, child) => Theme(
                    data: Theme.of(c2).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: c.primary)),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _dl = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: c.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _dl != null ? _fmt(_dl!) : 'Select date',
                      style: TextStyle(fontSize: 14, color: _dl != null ? c.textPrimary : c.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  final g = Goal(
                    id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch,
                    name: _nameCtrl.text.trim(),
                    type: _type,
                    target: double.tryParse(_targetCtrl.text) ?? 0,
                    saved: widget.existing?.saved ?? 0,
                    deadline: _dl != null ? _fmt(_dl!) : '',
                    tasks: widget.existing?.tasks ?? [],
                  );
                  widget.onAdd(g);
                  if (widget.existing == null) Navigator.pop(context);
                },
                child: Text(
                  widget.existing != null ? 'Save Changes' : 'Create Goal',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings ─────────────────────────────────────────────────────────────────

class SettingsPage extends StatefulWidget {
  final UserProfile user;
  final void Function(UserProfile) onUserChanged;
  const SettingsPage({super.key, required this.user, required this.onUserChanged});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool weekly = true, deadlines = true, passcode = false, biometric = true;

static const _themeLabels = ['Light', 'Dark', 'Colorful', 'MAN*LY', 'Pink', 'Kelly'];
static const _themeIcons  = [
  Icons.wb_sunny_outlined,  Icons.nightlight_outlined,
  Icons.palette_outlined,   Icons.bolt_outlined,
  Icons.favorite_outline,   Icons.business_outlined,
];

  void _openEditProfile() async {
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(user: widget.user),
      ),
    );
    if (updated != null) widget.onUserChanged(updated);
  }

  @override
  Widget build(BuildContext ctx) {
    final c             = colorsOf(ctx);
    final themeNotifier = AppThemeNotifier.of(ctx);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(title: 'Settings'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 28 : 16),
        child: Column(
          children: [
            // Profile card
            Card2(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: c.primaryLight,
                    child: Text(
                      widget.user.initials,
                      style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                        Text(widget.user.email,
                          style: TextStyle(fontSize: 13, color: c.textMuted)),
                      ],
                    ),
                  ),
                  SageBtn(label: 'Edit', onTap: _openEditProfile),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Theme picker
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('App Theme',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textMuted)),
              ),
            ),
            ValueListenableBuilder<AppTheme>(
              valueListenable: themeNotifier,
              builder: (ctx, currentTheme, _) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.4,
                children: List.generate(6, (i) {
                  final t   = allThemeEnums[i];
                  final tc  = allThemes[i];
                  final sel = currentTheme == t;
                  return GestureDetector(
                    onTap: () => themeNotifier.value = t,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? tc.primary : c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? tc.primary : c.border, width: sel ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(_themeIcons[i], size: 18, color: sel ? Colors.white : c.textMuted),
                          const SizedBox(width: 8),
                          Text(_themeLabels[i],
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: sel ? Colors.white : c.textPrimary)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            _Section(title: 'Notifications', children: [
              _Tile(label: 'Weekly Summary', c: c,
                trailing: Switch(value: weekly, onChanged: (v) => setState(() => weekly = v), activeColor: c.primary)),
              _Tile(label: 'Deadline Reminders', c: c,
                trailing: Switch(value: deadlines, onChanged: (v) => setState(() => deadlines = v), activeColor: c.primary)),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Security', children: [
              _Tile(label: 'Passcode Lock', c: c,
                trailing: Switch(value: passcode, onChanged: (v) => setState(() => passcode = v), activeColor: c.primary)),
              _Tile(label: 'Biometric Unlock', c: c,
                trailing: Switch(value: biometric, onChanged: (v) => setState(() => biometric = v), activeColor: c.primary)),
            ]),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.danger,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {},
                child: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final UserProfile user;
  const EditProfilePage({super.key, required this.user});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _nameCtrl  = TextEditingController(text: widget.user.name);
  late final _emailCtrl = TextEditingController(text: widget.user.email);
  late final _passCtrl  = TextEditingController(text: widget.user.password);
  late final _confirmCtrl = TextEditingController();
  bool _showPass    = false;
  bool _showConfirm = false;
  String? _error;

  void _save() {
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    final conf  = _confirmCtrl.text;

    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email.');
      return;
    }
    if (pass.isNotEmpty && pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass.isNotEmpty && pass != conf) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    final updated = widget.user.copyWith(
      name:     name,
      email:    email,
      password: pass.isNotEmpty ? pass : widget.user.password,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(title: 'Edit Profile', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar preview
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: c.primaryLight,
                child: Text(
                  _nameCtrl.text.trim().isNotEmpty
                      ? UserProfile(name: _nameCtrl.text.trim(), email: '', password: '').initials
                      : '?',
                  style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.danger.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: c.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: c.danger))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name
            Text('Full Name', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _field(ctx, _nameCtrl, 'Your name', onChanged: (_) => setState(() {})),
            const SizedBox(height: 18),

            // Email
            Text('Email', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _field(ctx, _emailCtrl, 'your@email.com', type: TextInputType.emailAddress),
            const SizedBox(height: 18),

            // Divider with label
            Row(children: [
              Expanded(child: Divider(color: c.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Change Password', style: TextStyle(fontSize: 12, color: c.textMuted)),
              ),
              Expanded(child: Divider(color: c.border)),
            ]),
            const SizedBox(height: 18),

            // New password
            Text('New Password', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _passwordField(ctx, _passCtrl, 'Leave blank to keep current', _showPass,
              () => setState(() => _showPass = !_showPass)),
            const SizedBox(height: 18),

            // Confirm password
            Text('Confirm Password', style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _passwordField(ctx, _confirmCtrl, 'Re-enter new password', _showConfirm,
              () => setState(() => _showConfirm = !_showConfirm)),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _save,
                child: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext ctx,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    final c = colorsOf(ctx);
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _passwordField(
    BuildContext ctx,
    TextEditingController ctrl,
    String hint,
    bool visible,
    VoidCallback toggle,
  ) {
    final c = colorsOf(ctx);
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18, color: c.textMuted),
          onPressed: toggle,
        ),
      ),
    );
  }
}


class EventDetailPage extends StatelessWidget {
  final DayEvent event;
  const EventDetailPage({super.key, required this.event});

  String _mn(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  void _confirmDelete(BuildContext ctx, ThemeColors c) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Event',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
          style: TextStyle(color: c.textMuted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(ctx, {'action': 'delete'});
            },
            child: Text('Delete',
              style: TextStyle(color: c.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(title: 'Event Details', showBack: true),
      body: Padding(
        padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Event card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: c.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.event_rounded, color: c.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(event.title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(color: c.border, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: c.textMuted),
                      const SizedBox(width: 10),
                      Text(
                        '${_mn(event.date.month)} ${event.date.day}, ${event.date.year}',
                        style: TextStyle(fontSize: 14, color: c.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 16, color: c.textMuted),
                      const SizedBox(width: 10),
                      Text(event.time,
                        style: TextStyle(fontSize: 14, color: c.textPrimary)),
                    ],
                  ),
                                    if (event.details.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Divider(color: c.border, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_outlined, size: 16, color: c.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.details,
                            style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Edit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Event',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final updated = await Navigator.push<DayEvent>(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => AddEventPage(
                        initialDate: event.date,
                        existing: event,
                      ),
                    ),
                  );
                  if (updated != null && ctx.mounted) {
                    Navigator.pop(ctx, {'action': 'edit', 'event': updated});
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                label: Text('Delete Event',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                    color: c.danger)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.danger.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _confirmDelete(ctx, c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class AddEventPage extends StatefulWidget {
  final DateTime? initialDate;
  final DayEvent? existing;
  const AddEventPage({super.key, this.initialDate, this.existing});
  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _detailsCtrl;
  late DateTime _date;
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.existing?.title   ?? '');
    _detailsCtrl = TextEditingController(text: widget.existing?.details ?? '');
    _date = widget.existing?.date ?? widget.initialDate ?? DateTime.now();
    if (widget.existing != null) {
      try {
        final parts  = widget.existing!.time.split(':');
        final hParts = parts[1].split(' ');
        int hour     = int.parse(parts[0]);
        final min    = int.parse(hParts[0]);
        final isPm   = hParts[1].trim() == 'PM';
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        _time = TimeOfDay(hour: hour, minute: min);
      } catch (_) {
        _time = TimeOfDay.now();
      }
    } else {
      _time = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final h  = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m  = t.minute.toString().padLeft(2, '0');
    final pm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $pm';
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter an event title.');
      return;
    }
    Navigator.pop(context,
      DayEvent(_fmtTime(_time), _titleCtrl.text.trim(), _date, _detailsCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext ctx) {
    final c       = colorsOf(ctx);
    final isEdit  = widget.existing != null;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar2(
        title: isEdit ? 'Edit Event' : 'Add Event',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isDesktop(ctx) ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.danger.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: c.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                      style: TextStyle(fontSize: 13, color: c.danger))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            Text('Event Title',
              style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: "e.g. Doctor's appointment",
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
              ),
            ),
            const SizedBox(height: 18),
// Details (optional)
            Text('Details (optional)',
              style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _detailsCtrl,
              maxLines: 3,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add notes, location, or any extra info...',
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
              ),
            ),
            const SizedBox(height: 18),

            // Date
            Text('Date',
              style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: _date,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  builder: (c2, child) => Theme(
                    data: Theme.of(c2).copyWith(
                      colorScheme: ColorScheme.fromSeed(seedColor: c.primary)),
                    child: child!),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: c.textMuted),
                    const SizedBox(width: 10),
                    Text(_fmtDate(_date),
                      style: TextStyle(fontSize: 14, color: c.textPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Time
            Text('Time',
              style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: _time,
                  builder: (c2, child) => Theme(
                    data: Theme.of(c2).copyWith(
                      colorScheme: ColorScheme.fromSeed(seedColor: c.primary)),
                    child: child!),
                );
                if (t != null) setState(() => _time = t);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 16, color: c.textMuted),
                    const SizedBox(width: 10),
                    Text(_fmtTime(_time),
                      style: TextStyle(fontSize: 14, color: c.textPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _save,
                child: Text(
                  isEdit ? 'Save Changes' : 'Add Event',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext ctx) {
    final c = colorsOf(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textMuted)),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: List.generate(children.length, (i) => Column(
              children: [
                children[i],
                if (i < children.length - 1) Divider(height: 1, color: c.border),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final Widget trailing;
  final ThemeColors c;
  const _Tile({required this.label, required this.trailing, required this.c});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: c.textPrimary)),
        trailing,
      ],
    ),
  );
}