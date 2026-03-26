import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'models.dart';

class FirebaseService {
  static final _auth        = FirebaseAuth.instance;
  static final _db          = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  // ── Current user ─────────────────────────────────────────────
  static User? get currentUser       => _auth.currentUser;
  static bool  get isLoggedIn        => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign Up ───────────────────────────────────────────────────
  static Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    required int    avatarIconIndex,
    required int    appThemeIndex,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password);
    await cred.user!.updateDisplayName(name);

    final profile = UserProfile(
      name:            name,
      email:           email,
      password:        '',
      avatarIconIndex: avatarIconIndex,
      theme:           AppTheme.values[appThemeIndex],
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'name':            name,
      'email':           email,
      'avatarIconIndex': avatarIconIndex,
      'themeIndex':      appThemeIndex,
      'createdAt':       FieldValue.serverTimestamp(),
    });

    await _createStarterData(cred.user!.uid);
    return profile;
  }

  // ── Sign In (email/password) ──────────────────────────────────
  static Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password);

    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('User profile not found.');

    final data = doc.data()!;
    return UserProfile(
      name:            data['name']            ?? '',
      email:           data['email']           ?? email,
      password:        '',
      avatarIconIndex: data['avatarIconIndex'] ?? 0,
      theme:           AppTheme.values[data['themeIndex'] ?? 0],
    );
  }

  // ── Sign In with Google ───────────────────────────────────────
  static Future<UserProfile?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final uid  = cred.user!.uid;
    final doc  = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      // First time Google sign in — create profile + starter data
      final name  = cred.user!.displayName ?? googleUser.displayName ?? 'User';
      final email = cred.user!.email       ?? googleUser.email;

      await _db.collection('users').doc(uid).set({
        'name':            name,
        'email':           email,
        'avatarIconIndex': 0,
        'themeIndex':      0,
        'createdAt':       FieldValue.serverTimestamp(),
      });

      await _createStarterData(uid);

      return UserProfile(
        name:            name,
        email:           email,
        password:        '',
        avatarIconIndex: 0,
        theme:           AppTheme.light,
      );
    } else {
      // Returning Google user — load existing profile
      final data = doc.data()!;
      return UserProfile(
        name:            data['name']            ?? '',
        email:           data['email']           ?? '',
        password:        '',
        avatarIconIndex: data['avatarIconIndex'] ?? 0,
        theme:           AppTheme.values[data['themeIndex'] ?? 0],
      );
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _googleSignIn.signOut(); // also sign out of Google
    await _auth.signOut();
  }

  // ── Update profile ────────────────────────────────────────────
  static Future<void> updateProfile(UserProfile profile) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'name':            profile.name,
      'email':           profile.email,
      'avatarIconIndex': profile.avatarIconIndex,
      'themeIndex':      AppTheme.values.indexOf(profile.theme),
    });
    if (profile.name.isNotEmpty) {
      await currentUser!.updateDisplayName(profile.name);
    }
  }

  // ── Update password ───────────────────────────────────────────
  static Future<void> updatePassword(String newPassword) async {
    await currentUser!.updatePassword(newPassword);
  }

  // ── Goals ─────────────────────────────────────────────────────
  static CollectionReference _goalsRef() =>
    _db.collection('users').doc(currentUser!.uid).collection('goals');

  static Future<List<Goal>> loadGoals() async {
    final snap = await _goalsRef().orderBy('createdAt').get();
    return snap.docs.map((d) => _goalFromDoc(d)).toList();
  }

  static Future<void> saveGoal(Goal goal) async {
    await _goalsRef().doc(goal.id.toString()).set(_goalToMap(goal));
  }

  static Future<void> deleteGoal(int id) async {
    await _goalsRef().doc(id.toString()).delete();
  }

  // ── Weekly data ───────────────────────────────────────────────
  static DocumentReference _weekRef() =>
    _db.collection('users').doc(currentUser!.uid).collection('weekly').doc('current');

  static Future<Map<int, DayData>> loadWeek() async {
    final doc = await _weekRef().get();
    if (!doc.exists) return sampleWeek();
    final data = doc.data() as Map<String, dynamic>;
    final Map<int, DayData> week = {};
    for (int i = 0; i < 7; i++) {
      final day = data['day_$i'] as Map<String, dynamic>?;
      if (day != null) {
        week[i] = DayData(
          focus:  day['focus'] ?? '',
          events: (day['events'] as List? ?? []).map((e) => DayEvent(
            e['time']    ?? '',
            e['title']   ?? '',
            e['date']    != null ? (e['date'] as Timestamp).toDate() : null,
            e['details'] ?? '',
          )).toList(),
          tasks: (day['tasks'] as List? ?? []).map((t) => GoalTask(
            id:   t['id']   ?? 0,
            text: t['text'] ?? '',
            done: t['done'] ?? false,
          )).toList(),
        );
      }
    }
    return week.isEmpty ? sampleWeek() : week;
  }

  static Future<void> saveDay(int dayIndex, DayData data) async {
    await _weekRef().set({
      'day_$dayIndex': {
        'focus':  data.focus,
        'events': data.events.map((e) => {
          'time':    e.time,
          'title':   e.title,
          'date':    Timestamp.fromDate(e.date),
          'details': e.details,
        }).toList(),
        'tasks': data.tasks.map((t) => {
          'id':   t.id,
          'text': t.text,
          'done': t.done,
        }).toList(),
      }
    }, SetOptions(merge: true));
  }

  // ── Weekly todos ──────────────────────────────────────────────
  static DocumentReference _todosRef() =>
    _db.collection('users').doc(currentUser!.uid).collection('weekly').doc('todos');

  static Future<List<GoalTask>> loadWeeklyTodos() async {
    final doc = await _todosRef().get();
    if (!doc.exists) return sampleWeeklyTodos();
    final data = doc.data() as Map<String, dynamic>;
    return (data['todos'] as List? ?? []).map((t) => GoalTask(
      id:   t['id']   ?? 0,
      text: t['text'] ?? '',
      done: t['done'] ?? false,
    )).toList();
  }

  static Future<void> saveWeeklyTodos(List<GoalTask> todos) async {
    await _todosRef().set({
      'todos': todos.map((t) => {
        'id': t.id, 'text': t.text, 'done': t.done,
      }).toList(),
    });
  }

  // ── Habits ────────────────────────────────────────────────────
  static DocumentReference _habitsRef() =>
    _db.collection('users').doc(currentUser!.uid).collection('weekly').doc('habits');

  static Future<List<HabitEntry>> loadHabits() async {
    final doc = await _habitsRef().get();
    if (!doc.exists) return sampleHabits();
    final data = doc.data() as Map<String, dynamic>;
    return (data['habits'] as List? ?? []).map((h) => HabitEntry(
      h['name'] ?? '',
      List<bool>.from(h['days'] ?? List.filled(7, false)),
    )).toList();
  }

  static Future<void> saveHabits(List<HabitEntry> habits) async {
    await _habitsRef().set({
      'habits': habits.map((h) => {
        'name': h.name,
        'days': h.days,
      }).toList(),
    });
  }

  // ── Starter data for new users ────────────────────────────────
  static Future<void> _createStarterData(String uid) async {
    final batch = _db.batch();
    final now   = DateTime.now();

    // Starter goals
    for (final g in starterGoals()) {
      batch.set(
        _db.collection('users').doc(uid).collection('goals').doc(g.id.toString()),
        _goalToMap(g),
      );
    }

    // Starter week
    final week     = starterWeek(now);
    final weekData = <String, dynamic>{};
    week.forEach((i, data) {
      weekData['day_$i'] = {
        'focus':  data.focus,
        'events': data.events.map((e) => {
          'time':    e.time,
          'title':   e.title,
          'date':    Timestamp.fromDate(e.date),
          'details': e.details,
        }).toList(),
        'tasks': data.tasks.map((t) => {
          'id': t.id, 'text': t.text, 'done': t.done,
        }).toList(),
      };
    });
    batch.set(
      _db.collection('users').doc(uid).collection('weekly').doc('current'),
      weekData,
    );

    // Starter todos
    batch.set(
      _db.collection('users').doc(uid).collection('weekly').doc('todos'),
      {
        'todos': starterWeeklyTodos().map((t) => {
          'id': t.id, 'text': t.text, 'done': t.done,
        }).toList(),
      },
    );

    // Starter habits
    batch.set(
      _db.collection('users').doc(uid).collection('weekly').doc('habits'),
      {
        'habits': sampleHabits().map((h) => {
          'name': h.name, 'days': h.days,
        }).toList(),
      },
    );

    await batch.commit();
  }

  // ── Helpers ───────────────────────────────────────────────────
  static Goal _goalFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Goal(
      id:       int.tryParse(doc.id) ?? 0,
      name:     d['name']     ?? '',
      type:     d['type']     ?? 'Personal',
      target:   (d['target']  ?? 0).toDouble(),
      saved:    (d['saved']   ?? 0).toDouble(),
      deadline: d['deadline'] ?? '',
      tasks: (d['tasks'] as List? ?? []).map((t) => GoalTask(
        id:   t['id']   ?? 0,
        text: t['text'] ?? '',
        done: t['done'] ?? false,
      )).toList(),
    );
  }

  static Map<String, dynamic> _goalToMap(Goal g) => {
    'name':      g.name,
    'type':      g.type,
    'target':    g.target,
    'saved':     g.saved,
    'deadline':  g.deadline,
    'createdAt': FieldValue.serverTimestamp(),
    'tasks': g.tasks.map((t) => {
      'id': t.id, 'text': t.text, 'done': t.done,
    }).toList(),
  };
}