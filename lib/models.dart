import 'package:flutter/material.dart';

// ─── Theme Definitions ────────────────────────────────────────────────────────

enum AppTheme { light, dark, colorful, manly }

class ThemeColors {
  final String name;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color danger;
  final Color accent1;
  final Color accent2;
  final Color accent3;

  const ThemeColors({
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.danger,
    this.accent1 = Colors.transparent,
    this.accent2 = Colors.transparent,
    this.accent3 = Colors.transparent,
  });
}

const lightTheme = ThemeColors(
  name: 'Light',
  primary:      Color(0xFF5C7A5C),
  primaryLight: Color(0xFFE8EDE8),
  primaryDark:  Color(0xFF3D5C3D),
  background:   Color(0xFFF5F2EF),
  surface:      Color(0xFFFFFFFF),
  border:       Color(0xFFE0DBD4),
  textPrimary:  Color(0xFF2C2A27),
  textMuted:    Color(0xFF8A8780),
  danger:       Color(0xFFC0392B),
);

const darkTheme = ThemeColors(
  name: 'Dark',
  primary:      Color(0xFF7A9A7A),
  primaryLight: Color(0xFF2A3A2A),
  primaryDark:  Color(0xFF9DB89D),
  background:   Color(0xFF121212),
  surface:      Color(0xFF1E1E1E),
  border:       Color(0xFF2E2E2E),
  textPrimary:  Color(0xFFECECEC),
  textMuted:    Color(0xFF888888),
  danger:       Color(0xFFE57373),
);

const colorfulTheme = ThemeColors(
  name: 'Colorful',
  primary:      Color(0xFF7C6BAE),
  primaryLight: Color(0xFFF0EDF8),
  primaryDark:  Color(0xFF5A4A8A),
  background:   Color(0xFFFDF6F0),
  surface:      Color(0xFFFFFFFF),
  border:       Color(0xFFE8DFF5),
  textPrimary:  Color(0xFF2C2A3A),
  textMuted:    Color(0xFF9A8FAA),
  danger:       Color(0xFFE05C7A),
  accent1:      Color(0xFFE8A87C),
  accent2:      Color(0xFF7ABFB0),
  accent3:      Color(0xFFE87C9A),
);

const manlyTheme = ThemeColors(
  name: 'MAN*LY',
  primary:      Color(0xFF2E6DA4),
  primaryLight: Color(0xFF1A2535),
  primaryDark:  Color(0xFF5B9BD5),
  background:   Color(0xFF0D0D0D),
  surface:      Color(0xFF1A1A1A),
  border:       Color(0xFF2A2A2A),
  textPrimary:  Color(0xFFE8E8E8),
  textMuted:    Color(0xFF6A6A6A),
  danger:       Color(0xFFE05555),
);

const allThemes     = [lightTheme, darkTheme, colorfulTheme, manlyTheme];
const allThemeEnums = [AppTheme.light, AppTheme.dark, AppTheme.colorful, AppTheme.manly];

// ─── Theme Notifier ───────────────────────────────────────────────────────────

class AppThemeNotifier extends InheritedNotifier<ValueNotifier<AppTheme>> {
  const AppThemeNotifier({
    super.key,
    required ValueNotifier<AppTheme> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<AppTheme> of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<AppThemeNotifier>()!.notifier!;
}

ThemeColors colorsOf(BuildContext ctx) {
  final theme = AppThemeNotifier.of(ctx).value;
  return allThemes[allThemeEnums.indexOf(theme)];
}

// ─── User Profile ─────────────────────────────────────────────────────────────

class UserProfile {
  final String name;
  final String email;
  final String password;

  const UserProfile({
    required this.name,
    required this.email,
    required this.password,
  });

  UserProfile copyWith({String? name, String? email, String? password}) => UserProfile(
    name:     name     ?? this.name,
    email:    email    ?? this.email,
    password: password ?? this.password,
  );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class GoalTask {
  final int id;
  final String text;
  bool done;
  GoalTask({required this.id, required this.text, this.done = false});
  GoalTask copyWith({bool? done}) =>
      GoalTask(id: id, text: text, done: done ?? this.done);
}

class Goal {
  final int id;
  String name, type, deadline;
  double target, saved;
  List<GoalTask> tasks;

  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.saved,
    required this.deadline,
    required this.tasks,
  });

  double get pct => (saved / target).clamp(0, 1);

  Goal copyWith({
    String? name,
    String? type,
    String? deadline,
    double? target,
    double? saved,
    List<GoalTask>? tasks,
  }) =>
      Goal(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        target: target ?? this.target,
        saved: saved ?? this.saved,
        deadline: deadline ?? this.deadline,
        tasks: tasks ?? this.tasks,
      );
}

class DayEvent {
  final String time;
  final String title;
  final DateTime date;
  final String details;

  DayEvent(this.time, this.title, [DateTime? date, this.details = ''])
      : date = date ?? DateTime.now();
}

class DayData {
  final String focus;
  final List<DayEvent> events;
  List<GoalTask> tasks;
  DayData({required this.focus, required this.events, required this.tasks});
}

class HabitEntry {
  final String name;
  final List<bool> days;
  HabitEntry(this.name, this.days);
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

const defaultUser = UserProfile(
  name:     'Jenny Wilson',
  email:    'jennywilson@gmail.com',
  password: 'password123',
);

List<Goal> sampleGoals() => [
  Goal(
    id: 1, name: 'Emergency Fund', type: 'Financial',
    target: 2500, saved: 1125, deadline: '2024-09-30',
    tasks: [
      GoalTask(id: 1, text: 'Add \$100 to savings', done: true),
      GoalTask(id: 2, text: 'Set up monthly transfer', done: true),
      GoalTask(id: 3, text: 'Review budget for next month'),
      GoalTask(id: 4, text: 'Cut entertainment expenses'),
    ],
  ),
  Goal(
    id: 2, name: 'Europe Vacation', type: 'Personal',
    target: 5000, saved: 3000, deadline: '2025-06-01',
    tasks: [
      GoalTask(id: 1, text: 'Research flight prices', done: true),
      GoalTask(id: 2, text: 'Set up monthly transfer', done: true),
      GoalTask(id: 3, text: 'Review budget for trip'),
    ],
  ),
  Goal(
    id: 3, name: 'New Laptop', type: 'Financial',
    target: 1500, saved: 300, deadline: '2024-12-01',
    tasks: [
      GoalTask(id: 1, text: 'Compare models'),
      GoalTask(id: 2, text: 'Set savings target'),
    ],
  ),
  Goal(
    id: 4, name: 'Home Renovation', type: 'Financial',
    target: 10000, saved: 7200, deadline: '2025-03-01',
    tasks: [
      GoalTask(id: 1, text: 'Get contractor quotes', done: true),
      GoalTask(id: 2, text: 'Set up monthly transfer', done: true),
      GoalTask(id: 3, text: 'Review budget for renovation'),
    ],
  ),
];

Map<int, DayData> sampleWeek() {
  final monday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  return {
    0: DayData(focus: 'Weekly cleaning chores',
      events: [
        DayEvent('9:30 AM',  'Meeting with the team',  monday),
        DayEvent('11:30 AM', "Doctor's appointment",   monday),
      ],
      tasks: [
        GoalTask(id: 1, text: 'Clean bathroom & kitchen', done: true),
        GoalTask(id: 2, text: 'Vacuum entire house',       done: true),
        GoalTask(id: 3, text: 'Laundry (wash + fold)'),
        GoalTask(id: 4, text: 'Clear email inbox'),
      ]),
    1: DayData(focus: 'Catch up on work for the week',
      events: [DayEvent('11:00 AM', 'Zoom team meeting', monday.add(const Duration(days: 1)))],
      tasks: [
        GoalTask(id: 1, text: 'Finish client proposal', done: true),
        GoalTask(id: 2, text: 'Send follow-up emails'),
        GoalTask(id: 3, text: 'Pay phone bill'),
      ]),
    2: DayData(focus: 'Finish organizing pantry',
      events: [
        DayEvent('4:30 PM', 'Vet appointment', monday.add(const Duration(days: 2))),
        DayEvent('7:30 PM', 'Trivia night',    monday.add(const Duration(days: 2))),
      ],
      tasks: [
        GoalTask(id: 1, text: 'Prep social media posts', done: true),
        GoalTask(id: 2, text: 'Sort pantry items',        done: true),
        GoalTask(id: 3, text: 'Wipe down shelves'),
      ]),
    3: DayData(focus: 'Admin & errands',
      events: [DayEvent('10:00 AM', 'Grocery run', monday.add(const Duration(days: 3)))],
      tasks: [
        GoalTask(id: 1, text: 'Pay credit card'),
        GoalTask(id: 2, text: 'Book dentist appt'),
      ]),
    4: DayData(focus: 'Deep work day', events: [],
      tasks: [
        GoalTask(id: 1, text: 'Finish weekly report'),
        GoalTask(id: 2, text: 'Review goals'),
      ]),
    5: DayData(focus: 'Rest & reset',
      events: [DayEvent('11:00 AM', 'Brunch with friends', monday.add(const Duration(days: 5)))],
      tasks: [GoalTask(id: 1, text: 'Meal prep for next week')]),
    6: DayData(focus: 'Family & recharge', events: [],
      tasks: [
        GoalTask(id: 1, text: 'Plan next week'),
        GoalTask(id: 2, text: 'Journal entry'),
      ]),
  };
}
List<HabitEntry> sampleHabits() => [
  HabitEntry('8 hrs sleep',       [true,  true,  true,  false, true,  false, false]),
  HabitEntry('Morning walk',      [true,  false, true,  true,  false, true,  false]),
  HabitEntry('No social after 9', [true,  true,  false, true,  true,  false, false]),
  HabitEntry('Take vitamins',     [true,  true,  true,  true,  false, false, false]),
  HabitEntry('Journal entry',     [false, true,  false, false, true,  true,  false]),
  HabitEntry('Floss',             [true,  true,  true,  true,  true,  false, false]),
];

List<GoalTask> sampleWeeklyTodos() => [
  GoalTask(id: 1, text: 'Refill prescription',      done: true),
  GoalTask(id: 2, text: 'Book dentist appointment', done: true),
  GoalTask(id: 3, text: 'Return online order',      done: true),
  GoalTask(id: 4, text: 'Back up phone photos'),
  GoalTask(id: 5, text: 'Organize Dropbox files'),
  GoalTask(id: 6, text: 'Schedule car service'),
];