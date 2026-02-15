// lib/main.dart
//
// SmartCast — single-file Flutter WEB demo (no Firebase).
// ✔ RU/EN toggle (global)
// ✔ Auth (doctor/patient), registration
// ✔ Doctor panel: Patients / Alerts / Settings (bottom nav)
// ✔ Patient panel: Dashboard / Checklist / Visits / Photos / Settings (bottom nav) — different UI
// ✔ Patient detail (doctor view): tabs (Overview, Requests, Photos, Timeline, Checklist, Slots calendar)
// ✔ Timeline with real charts (CustomPainter) + readings list (Temp/Humidity/Pressure/pH)
// ✔ Slots calendar (month grid) + visit requests
// ✔ Checklist with HISTORY (each save appends entry) + doctor read-only view
// ✔ Local persistence via window.localStorage (Flutter Web)
//
// Demo accounts (pre-seeded on first launch):
// Doctor:  IIN 111111111111  PASS 1111
// Patient: IIN 222222222222  PASS 2222
// Patient: IIN 333333333333  PASS 3333
// Patient: IIN 444444444444  PASS 4444
//
// Run: flutter run -d chrome (or edge)
//
// NOTE: This file imports dart:html, so it's intended for WEB.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const SmartCastApp());
}

// ============================== THEME / COLORS ==============================

class AppColors {
  // Primary palette (brown-ish, with a bit of accent colors).
  static const primary = Color(0xFF7A4E2E);
  static const primaryDark = Color(0xFF613B22);
  static const bg = Color(0xFFF7F2ED);
  static const card = Color(0xFFFFFFFF);
  static const outline = Color(0xFFE7D7CB);
  static const text = Color(0xFF1C1B1A);
  static const textMuted = Color(0xFF6F6258);

  // Accents (so it’s not “only brown”)
  static const accentBlue = Color(0xFF2F80ED);
  static const accentTeal = Color(0xFF1AAE9F);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentGreen = Color(0xFF27AE60);
  static const accentRed = Color(0xFFEB5757);
  static const accentAmber = Color(0xFFF2A54A);

  static Color chipBg(Color c) => c.withOpacity(0.12);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
      fontFamily: null,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    ),
    // IMPORTANT FIX: use CardThemeData (new API) not CardTheme (widget)
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: AppColors.outline),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.55), width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

// ============================== LOCALIZATION ==============================

enum AppLang { ru, en }

class L10n {
  L10n(this.lang);
  final AppLang lang;

  String t(String key) {
    final ru = <String, String>{
      'smartcast': 'SmartCast',
      'login': 'Вход',
      'register': 'Регистрация',
      'doctor': 'Врач',
      'patient': 'Пациент',
      'iin': 'ИИН (12 цифр)',
      'password': 'Пароль (минимум 4 символа)',
      'fullName': 'ФИО',
      'phone': 'Телефон',
      'signIn': 'Войти',
      'signUp': 'Создать',
      'noAccount': 'Нет аккаунта',
      'haveAccount': 'Есть аккаунт',
      'logout': 'Выйти',
      'patients': 'Пациенты',
      'alerts': 'Оповещения',
      'settings': 'Настройки',
      'addPatient': 'Добавить пациента',
      'search': 'Поиск',
      'overview': 'Обзор',
      'requests': 'Запросы (визиты)',
      'photos': 'Фото гипса',
      'timeline': 'Cast Timeline',
      'checklist': 'Чек-лист ухода',
      'slots': 'Календарь слотов',
      'save': 'Сохранить',
      'lastUpdate': 'Последнее обновление',
      'riskLow': 'RISK • LOW',
      'riskMed': 'RISK • MED',
      'riskHigh': 'RISK • HIGH',
      'visits': 'Визиты',
      'dashboard': 'Панель',
      'myDoctors': 'Мои врачи',
      'health': 'Здоровье',
      'history': 'История',
      'empty': 'Пока пусто',
      'sendRequest': 'Отправить запрос',
      'pickSlot': 'Выбрать слот',
      'note': 'Заметки',
      'language': 'Язык',
      'demo': 'Демо',
      'delete': 'Удалить',
    };

    final en = <String, String>{
      'smartcast': 'SmartCast',
      'login': 'Login',
      'register': 'Register',
      'doctor': 'Doctor',
      'patient': 'Patient',
      'iin': 'IIN (12 digits)',
      'password': 'Password (min 4 chars)',
      'fullName': 'Full name',
      'phone': 'Phone',
      'signIn': 'Sign in',
      'signUp': 'Create',
      'noAccount': 'No account',
      'haveAccount': 'Have an account',
      'logout': 'Logout',
      'patients': 'Patients',
      'alerts': 'Alerts',
      'settings': 'Settings',
      'addPatient': 'Add patient',
      'search': 'Search',
      'overview': 'Overview',
      'requests': 'Requests (visits)',
      'photos': 'Cast photos',
      'timeline': 'Cast Timeline',
      'checklist': 'Care checklist',
      'slots': 'Slots calendar',
      'save': 'Save',
      'lastUpdate': 'Last update',
      'riskLow': 'RISK • LOW',
      'riskMed': 'RISK • MED',
      'riskHigh': 'RISK • HIGH',
      'visits': 'Visits',
      'dashboard': 'Dashboard',
      'myDoctors': 'My doctors',
      'health': 'Health',
      'history': 'History',
      'empty': 'Empty',
      'sendRequest': 'Send request',
      'pickSlot': 'Pick slot',
      'note': 'Notes',
      'language': 'Language',
      'demo': 'Demo',
      'delete': 'Delete',
    };

    return (lang == AppLang.ru ? ru : en)[key] ?? key;
  }
}

// ============================== MODELS ==============================

enum Role { doctor, patient }

class AppUser {
  AppUser({
    required this.role,
    required this.iin,
    required this.password,
    required this.fullName,
    required this.phone,
  });

  final Role role;
  final String iin;
  String password;
  String fullName;
  String phone;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'iin': iin,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      };

  static AppUser fromJson(Map<String, dynamic> j) => AppUser(
        role: Role.values.firstWhere((e) => e.name == j['role']),
        iin: j['iin'],
        password: j['password'],
        fullName: j['fullName'] ?? '',
        phone: j['phone'] ?? '',
      );
}

class Reading {
  Reading({
    required this.ts,
    required this.tempC,
    required this.humidityPct,
    required this.pressure10,
    required this.ph,
  });

  DateTime ts;
  double tempC;
  double humidityPct;
  int pressure10; // 0..10
  double ph;

  Map<String, dynamic> toJson() => {
        'ts': ts.toIso8601String(),
        'tempC': tempC,
        'humidityPct': humidityPct,
        'pressure10': pressure10,
        'ph': ph,
      };

  static Reading fromJson(Map<String, dynamic> j) => Reading(
        ts: DateTime.parse(j['ts']),
        tempC: (j['tempC'] as num).toDouble(),
        humidityPct: (j['humidityPct'] as num).toDouble(),
        pressure10: (j['pressure10'] as num).toInt(),
        ph: (j['ph'] as num).toDouble(),
      );
}

class ChecklistEntry {
  ChecklistEntry({
    required this.ts,
    required this.stayedDry,
    required this.noWaterInside,
    required this.noStrongItch,
    required this.noSwelling,
    required this.noBadSmell,
  });

  DateTime ts;
  bool stayedDry;
  bool noWaterInside;
  bool noStrongItch;
  bool noSwelling;
  bool noBadSmell;

  Map<String, dynamic> toJson() => {
        'ts': ts.toIso8601String(),
        'stayedDry': stayedDry,
        'noWaterInside': noWaterInside,
        'noStrongItch': noStrongItch,
        'noSwelling': noSwelling,
        'noBadSmell': noBadSmell,
      };

  static ChecklistEntry fromJson(Map<String, dynamic> j) => ChecklistEntry(
        ts: DateTime.parse(j['ts']),
        stayedDry: j['stayedDry'] == true,
        noWaterInside: j['noWaterInside'] == true,
        noStrongItch: j['noStrongItch'] == true,
        noSwelling: j['noSwelling'] == true,
        noBadSmell: j['noBadSmell'] == true,
      );
}

class VisitRequest {
  VisitRequest({
    required this.id,
    required this.createdAt,
    required this.slot,
    required this.status, // Pending / Confirmed / Rejected
    required this.note,
  });

  String id;
  DateTime createdAt;
  DateTime slot;
  String status;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'slot': slot.toIso8601String(),
        'status': status,
        'note': note,
      };

  static VisitRequest fromJson(Map<String, dynamic> j) => VisitRequest(
        id: j['id'],
        createdAt: DateTime.parse(j['createdAt']),
        slot: DateTime.parse(j['slot']),
        status: j['status'],
        note: j['note'] ?? '',
      );
}

class PatientProfile {
  PatientProfile({
    required this.iin,
    required this.name,
    required this.doctorIIN,
    List<Reading>? readings,
    List<ChecklistEntry>? checklistHistory,
    List<VisitRequest>? requests,
    List<String>? photoDataUrls,
  })  : readings = readings ?? [],
        checklistHistory = checklistHistory ?? [],
        requests = requests ?? [],
        photoDataUrls = photoDataUrls ?? [];

  String iin;
  String name;
  String doctorIIN;

  List<Reading> readings;
  List<ChecklistEntry> checklistHistory;
  List<VisitRequest> requests;
  List<String> photoDataUrls; // WEB: data:image/...;base64,...

  Map<String, dynamic> toJson() => {
        'iin': iin,
        'name': name,
        'doctorIIN': doctorIIN,
        'readings': readings.map((e) => e.toJson()).toList(),
        'checklistHistory': checklistHistory.map((e) => e.toJson()).toList(),
        'requests': requests.map((e) => e.toJson()).toList(),
        'photoDataUrls': photoDataUrls,
      };

  static PatientProfile fromJson(Map<String, dynamic> j) => PatientProfile(
        iin: j['iin'],
        name: j['name'] ?? '',
        doctorIIN: j['doctorIIN'] ?? '',
        readings: (j['readings'] as List? ?? []).map((e) => Reading.fromJson(Map<String, dynamic>.from(e))).toList(),
        checklistHistory:
            (j['checklistHistory'] as List? ?? []).map((e) => ChecklistEntry.fromJson(Map<String, dynamic>.from(e))).toList(),
        requests: (j['requests'] as List? ?? []).map((e) => VisitRequest.fromJson(Map<String, dynamic>.from(e))).toList(),
        photoDataUrls: (j['photoDataUrls'] as List? ?? []).cast<String>(),
      );
}

// ============================== STORE (localStorage) ==============================

class AppStore extends ChangeNotifier {
  static const _key = 'smartcast_store_v3';

  AppUser? currentUser;

  final List<AppUser> users = [];
  final Map<String, PatientProfile> patients = {}; // by patient IIN

  bool _loaded = false;

  Future<void> loadOrSeed() async {
    if (_loaded) return;
    _loaded = true;

    final raw = html.window.localStorage[_key];
    if (raw == null || raw.trim().isEmpty) {
      _seed();
      _save();
      return;
    }

    try {
      final j = jsonDecode(raw);
      users
        ..clear()
        ..addAll((j['users'] as List).map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))));
      patients
        ..clear()
        ..addEntries((j['patients'] as List)
            .map((e) => PatientProfile.fromJson(Map<String, dynamic>.from(e)))
            .map((p) => MapEntry(p.iin, p)));
    } catch (_) {
      _seed();
      _save();
    }
    notifyListeners();
  }

  void _seed() {
    users.clear();
    patients.clear();

    // Doctor
    users.add(AppUser(
      role: Role.doctor,
      iin: '111111111111',
      password: '1111',
      fullName: 'Dr. A. Sadykova',
      phone: '+7 777 111 22 33',
    ));

    // Patients
    users.addAll([
      AppUser(role: Role.patient, iin: '222222222222', password: '2222', fullName: 'Alex K.', phone: '+7 708 226 5040'),
      AppUser(role: Role.patient, iin: '333333333333', password: '3333', fullName: 'Boris P.', phone: '+7 701 333 1010'),
      AppUser(role: Role.patient, iin: '444444444444', password: '4444', fullName: 'Nora S.', phone: '+7 702 444 2020'),
    ]);

    // Patient profiles linked to doctor
    patients['222222222222'] = PatientProfile(iin: '222222222222', name: 'Alex K.', doctorIIN: '111111111111');
    patients['333333333333'] = PatientProfile(iin: '333333333333', name: 'Boris P.', doctorIIN: '111111111111');
    patients['444444444444'] = PatientProfile(iin: '444444444444', name: 'Nora S.', doctorIIN: '111111111111');

    // Seed readings & checklist history
    for (final p in patients.values) {
      _seedPatientData(p);
    }
  }

  void _seedPatientData(PatientProfile p) {
    final now = DateTime.now();
    final baseTemp = 36.6 + (p.iin.endsWith('2') ? 0.1 : p.iin.endsWith('3') ? 0.3 : 0.0);
    final baseHum = 48 + (p.iin.endsWith('2') ? 6 : p.iin.endsWith('3') ? 10 : 4);
    final basePh = 6.7 + (p.iin.endsWith('3') ? -0.1 : 0.0);
    final rand = math.Random(int.parse(p.iin.substring(0, 3)));

    p.readings.clear();
    for (int i = 0; i < 10; i++) {
      final ts = now.subtract(Duration(hours: i * 6));
      p.readings.add(Reading(
        ts: ts,
        tempC: (baseTemp + (rand.nextDouble() - 0.5) * 0.6),
        humidityPct: (baseHum + (rand.nextDouble() - 0.5) * 18).clamp(20, 90),
        pressure10: (3 + rand.nextInt(5)).clamp(0, 10),
        ph: (basePh + (rand.nextDouble() - 0.5) * 0.5).clamp(5.5, 8.0),
      ));
    }
    p.readings.sort((a, b) => b.ts.compareTo(a.ts));

    p.checklistHistory.clear();
    for (int i = 0; i < 4; i++) {
      final ts = now.subtract(Duration(days: i));
      p.checklistHistory.add(ChecklistEntry(
        ts: ts,
        stayedDry: i != 2,
        noWaterInside: true,
        noStrongItch: i != 1,
        noSwelling: i != 1,
        noBadSmell: true,
      ));
    }
    p.checklistHistory.sort((a, b) => b.ts.compareTo(a.ts));

    p.requests.clear();
    // add one pending for Alex
    if (p.iin == '222222222222') {
      p.requests.add(VisitRequest(
        id: 'req_${now.millisecondsSinceEpoch}',
        createdAt: now.subtract(const Duration(hours: 8)),
        slot: now.add(const Duration(days: 2, hours: 3)),
        status: 'Pending',
        note: 'Pain increased at night.',
      ));
    }
  }

  void _save() {
    final j = {
      'users': users.map((e) => e.toJson()).toList(),
      'patients': patients.values.map((e) => e.toJson()).toList(),
    };
    html.window.localStorage[_key] = jsonEncode(j);
  }

  // -------- Auth --------

  AppUser? login(Role role, String iin, String password) {
    final u = users.where((x) => x.role == role && x.iin == iin && x.password == password).cast<AppUser?>().firstWhere(
          (e) => e != null,
          orElse: () => null,
        );
    currentUser = u;
    notifyListeners();
    return u;
  }

  String? register(Role role, String iin, String password, String fullName, String phone) {
    if (iin.length != 12 || int.tryParse(iin) == null) return 'IIN must be 12 digits';
    if (password.length < 4) return 'Password too short';
    if (users.any((u) => u.iin == iin)) return 'User already exists';

    users.add(AppUser(role: role, iin: iin, password: password, fullName: fullName, phone: phone));

    if (role == Role.patient) {
      // link to first doctor (demo) for this prototype
      final doc = users.firstWhere((u) => u.role == Role.doctor, orElse: () => users.first);
      patients[iin] = PatientProfile(iin: iin, name: fullName.isEmpty ? iin : fullName, doctorIIN: doc.iin);
      _seedPatientData(patients[iin]!);
    }

    _save();
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // -------- Doctor: patients list --------

  List<PatientProfile> doctorPatients(String doctorIIN) {
    final list = patients.values.where((p) => p.doctorIIN == doctorIIN).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  PatientProfile? patientByIIN(String iin) => patients[iin];

  // -------- Risk / Alerts --------

  int computeRisk(PatientProfile p) {
    // Very simple heuristic demo
    final r = p.readings.isEmpty ? null : p.readings.first;
    int score = 0;
    if (r != null) {
      if (r.tempC >= 37.8) score += 25;
      if (r.humidityPct >= 70) score += 20;
      if (r.pressure10 >= 7) score += 25;
      if (r.ph <= 6.0 || r.ph >= 7.8) score += 20;
    }
    final lastChk = p.checklistHistory.isEmpty ? null : p.checklistHistory.first;
    if (lastChk != null) {
      if (!lastChk.stayedDry) score += 10;
      if (!lastChk.noWaterInside) score += 10;
      if (!lastChk.noStrongItch) score += 10;
      if (!lastChk.noSwelling) score += 10;
      if (!lastChk.noBadSmell) score += 10;
    }
    return score.clamp(0, 100);
  }

  List<_AlertItem> doctorAlerts(String doctorIIN) {
    final list = <_AlertItem>[];
    for (final p in doctorPatients(doctorIIN)) {
      final risk = computeRisk(p);
      if (risk >= 45) {
        list.add(_AlertItem(
          patientIIN: p.iin,
          patientName: p.name,
          title: risk >= 70 ? 'High risk' : 'Moderate risk',
          subtitle: 'Risk score: $risk',
          severity: risk >= 70 ? 3 : 2,
        ));
      }
      // pending requests
      for (final req in p.requests.where((x) => x.status == 'Pending')) {
        list.add(_AlertItem(
          patientIIN: p.iin,
          patientName: p.name,
          title: 'Pending visit request',
          subtitle: '${_fmtDateTime(req.slot)}',
          severity: 1,
        ));
      }
    }
    list.sort((a, b) => b.severity.compareTo(a.severity));
    return list;
  }

  // -------- Checklist --------

  void saveChecklist(String patientIIN, ChecklistEntry entry) {
    final p = patients[patientIIN];
    if (p == null) return;
    p.checklistHistory.insert(0, entry);
    _save();
    notifyListeners();
  }

  // -------- Requests / Slots --------

  void addRequest(String patientIIN, DateTime slot, String note) {
    final p = patients[patientIIN];
    if (p == null) return;
    p.requests.insert(
      0,
      VisitRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        slot: slot,
        status: 'Pending',
        note: note,
      ),
    );
    _save();
    notifyListeners();
  }

  void updateRequestStatus(String patientIIN, String requestId, String newStatus) {
    final p = patients[patientIIN];
    if (p == null) return;
    final idx = p.requests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return;
    p.requests[idx].status = newStatus;
    _save();
    notifyListeners();
  }

  // -------- Photos (web upload) --------

  Future<void> addPhoto(String patientIIN) async {
    final p = patients[patientIIN];
    if (p == null) return;

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return;

    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    final dataUrl = (reader.result as String?) ?? '';
    if (dataUrl.isEmpty) return;

    p.photoDataUrls.insert(0, dataUrl);
    _save();
    notifyListeners();
  }

  void deletePhoto(String patientIIN, int index) {
    final p = patients[patientIIN];
    if (p == null) return;
    if (index < 0 || index >= p.photoDataUrls.length) return;
    p.photoDataUrls.removeAt(index);
    _save();
    notifyListeners();
  }
}

class _AlertItem {
  _AlertItem({
    required this.patientIIN,
    required this.patientName,
    required this.title,
    required this.subtitle,
    required this.severity,
  });

  final String patientIIN;
  final String patientName;
  final String title;
  final String subtitle;
  final int severity; // 1..3
}

// ============================== ROOT APP ==============================

class SmartCastApp extends StatefulWidget {
  const SmartCastApp({super.key});

  @override
  State<SmartCastApp> createState() => _SmartCastAppState();
}

class _SmartCastAppState extends State<SmartCastApp> {
  final store = AppStore();
  AppLang lang = AppLang.ru;

  @override
  void initState() {
    super.initState();
    unawaited(store.loadOrSeed());
    final savedLang = html.window.localStorage['smartcast_lang'];
    if (savedLang == 'en') lang = AppLang.en;
  }

  void setLang(AppLang l) {
    setState(() => lang = l);
    html.window.localStorage['smartcast_lang'] = l.name;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final l10n = L10n(lang);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: store.currentUser == null
              ? AuthScreen(
                  store: store,
                  l10n: l10n,
                  lang: lang,
                  onLang: setLang,
                )
              : RoleRouter(
                  store: store,
                  l10n: l10n,
                  lang: lang,
                  onLang: setLang,
                ),
        );
      },
    );
  }
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({
    super.key,
    required this.store,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  Widget build(BuildContext context) {
    final u = store.currentUser!;
    if (u.role == Role.doctor) {
      return DoctorShell(store: store, l10n: l10n, lang: lang, onLang: onLang);
    }
    return PatientShell(store: store, l10n: l10n, lang: lang, onLang: onLang);
  }
}

// ============================== AUTH SCREEN (Login/Register) ==============================

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.store,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  Role role = Role.doctor;

  final iinC = TextEditingController(text: '111111111111');
  final passC = TextEditingController(text: '1111');
  final nameC = TextEditingController();
  final phoneC = TextEditingController();

  String? error;

  void _doAuth() {
    setState(() => error = null);

    final iin = iinC.text.trim();
    final pass = passC.text;

    if (isLogin) {
      final u = widget.store.login(role, iin, pass);
      if (u == null) setState(() => error = widget.lang == AppLang.ru ? 'Неверный логин/пароль' : 'Wrong credentials');
    } else {
      final msg = widget.store.register(
        role,
        iin,
        pass,
        nameC.text.trim(),
        phoneC.text.trim(),
      );
      if (msg != null) {
        setState(() => error = msg);
        return;
      }
      // Auto-login after register
      widget.store.login(role, iin, pass);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 980;
          return Row(
            children: [
              Expanded(
                flex: wide ? 6 : 10,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _AuthCard(
                        l10n: l10n,
                        lang: widget.lang,
                        onLang: widget.onLang,
                        isLogin: isLogin,
                        onToggleMode: () => setState(() => isLogin = !isLogin),
                        role: role,
                        onRole: (r) => setState(() => role = r),
                        iinC: iinC,
                        passC: passC,
                        nameC: nameC,
                        phoneC: phoneC,
                        error: error,
                        onSubmit: _doAuth,
                      ),
                    ),
                  ),
                ),
              ),
              if (wide)
                Expanded(
                  flex: 7,
                  child: _RightBrandPanel(l10n: l10n),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.l10n,
    required this.lang,
    required this.onLang,
    required this.isLogin,
    required this.onToggleMode,
    required this.role,
    required this.onRole,
    required this.iinC,
    required this.passC,
    required this.nameC,
    required this.phoneC,
    required this.error,
    required this.onSubmit,
  });

  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  final bool isLogin;
  final VoidCallback onToggleMode;

  final Role role;
  final ValueChanged<Role> onRole;

  final TextEditingController iinC;
  final TextEditingController passC;
  final TextEditingController nameC;
  final TextEditingController phoneC;

  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // top row: brand pill + lang
            Row(
              children: [
                _BrandPill(),
                const Spacer(),
                _LangPill(lang: lang, onLang: onLang),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              isLogin ? l10n.t('login') : l10n.t('register'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            _RoleSegmented(role: role, onRole: onRole, l10n: l10n),
            const SizedBox(height: 12),

            TextField(
              controller: iinC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.t('iin'),
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: passC,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.t('password'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),

            if (!isLogin) ...[
              const SizedBox(height: 10),
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: l10n.t('fullName'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneC,
                decoration: InputDecoration(
                  labelText: l10n.t('phone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
            ],

            const SizedBox(height: 12),
            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentRed.withOpacity(0.25)),
                ),
                child: Text(error!, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            if (error != null) const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubmit,
                child: Text(isLogin ? l10n.t('signIn') : l10n.t('signUp')),
              ),
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: onToggleMode,
              child: Text(isLogin ? l10n.t('noAccount') : l10n.t('haveAccount')),
            ),

            // IMPORTANT: user asked to remove "Create demo account" — so not here.
          ],
        ),
      ),
    );
  }
}

class _RightBrandPanel extends StatelessWidget {
  const _RightBrandPanel({required this.l10n});

  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final isRu = l10n.lang == AppLang.ru;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('smartcast'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isRu ? 'Современный мониторинг гипса\nмежду визитами.' : 'Modern cast monitoring\nbetween visits.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      // IMPORTANT: user asked to remove the extra sentence box — so we keep it clean.
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Text('SmartCast', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({required this.lang, required this.onLang});

  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onLang(lang == AppLang.ru ? AppLang.en : AppLang.ru),
      icon: const Icon(Icons.language, size: 18),
      label: Text(lang == AppLang.ru ? 'RU' : 'EN'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _RoleSegmented extends StatelessWidget {
  const _RoleSegmented({required this.role, required this.onRole, required this.l10n});

  final Role role;
  final ValueChanged<Role> onRole;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    Widget seg(Role r, IconData icon, String label) {
      final active = role == r;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onRole(r),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.chipBg(AppColors.primary) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? AppColors.primary.withOpacity(0.35) : AppColors.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: active ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg(Role.doctor, Icons.medical_services_outlined, l10n.t('doctor')),
        const SizedBox(width: 10),
        seg(Role.patient, Icons.person_outline, l10n.t('patient')),
      ],
    );
  }
}

// ============================== DOCTOR SHELL ==============================

class DoctorShell extends StatefulWidget {
  const DoctorShell({
    super.key,
    required this.store,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int idx = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final u = widget.store.currentUser!;

    final pages = [
      _DoctorPatientsTab(store: widget.store, l10n: l10n, lang: widget.lang, onLang: widget.onLang),
      _DoctorAlertsTab(store: widget.store, l10n: l10n, lang: widget.lang, onLang: widget.onLang),
      _SettingsTab(store: widget.store, l10n: l10n, lang: widget.lang, onLang: widget.onLang),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.t('smartcast')} • ${u.fullName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _LangPill(lang: widget.lang, onLang: widget.onLang),
          ),
        ],
      ),
      body: SafeArea(child: pages[idx]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (v) => setState(() => idx = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.people_alt_outlined), label: l10n.t('patients')),
          NavigationDestination(icon: const Icon(Icons.notifications_none), label: l10n.t('alerts')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.t('settings')),
        ],
      ),
    );
  }
}

class _DoctorPatientsTab extends StatefulWidget {
  const _DoctorPatientsTab({
    required this.store,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  State<_DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<_DoctorPatientsTab> {
  final searchC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final doctorIIN = widget.store.currentUser!.iin;
    var list = widget.store.doctorPatients(doctorIIN);

    final q = searchC.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.iin.contains(q)).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchC,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.t('search'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  // demo: add random new patient (still no firebase)
                  final next = (math.Random().nextInt(900) + 100).toString().padLeft(3, '0');
                  final iin = '55555555$next$next';
                  final pass = '5555';
                  final name = 'New Patient $next';
                  widget.store.register(Role.patient, iin, pass, name, '+7 700 000 00 00');
                  // link to doctor
                  widget.store.patients[iin]!.doctorIIN = doctorIIN;
                  // persist link
                  html.window.localStorage.remove('dummy'); // no-op
                  // force save
                  widget.store
                    ..notifyListeners();
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(l10n.t('addPatient')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = list[i];
                final risk = widget.store.computeRisk(p);
                final riskColor = risk < 45
                    ? AppColors.accentGreen
                    : risk < 70
                        ? AppColors.accentAmber
                        : AppColors.accentRed;

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DoctorPatientDetailPage(
                          store: widget.store,
                          patientIIN: p.iin,
                          l10n: l10n,
                          lang: widget.lang,
                          onLang: widget.onLang,
                        ),
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          _AvatarCircle(name: p.name, color: AppColors.primary, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                const SizedBox(height: 3),
                                Text(p.iin, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.chipBg(riskColor),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: riskColor.withOpacity(0.28)),
                            ),
                            child: Text(
                              'RISK $risk',
                              style: TextStyle(color: riskColor, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          _DemoCredsHint(l10n: l10n),
        ],
      ),
    );
  }
}

class _DemoCredsHint extends StatelessWidget {
  const _DemoCredsHint({required this.l10n});
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final isRu = l10n.lang == AppLang.ru;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        isRu
            ? 'Демо: врач 111111111111 / 1111 • пациенты 2222..4444'
            : 'Demo: doctor 111111111111 / 1111 • patients 2222..4444',
        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DoctorAlertsTab extends StatelessWidget {
  const _DoctorAlertsTab({
    required this.store,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  Widget build(BuildContext context) {
    final doctorIIN = store.currentUser!.iin;
    final alerts = store.doctorAlerts(doctorIIN);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: alerts.isEmpty
          ? Center(child: Text(l10n.t('empty'), style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800)))
          : ListView.separated(
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = alerts[i];
                final c = a.severity == 3
                    ? AppColors.accentRed
                    : a.severity == 2
                        ? AppColors.accentAmber
                        : AppColors.accentBlue;

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DoctorPatientDetailPage(
                          store: store,
                          patientIIN: a.patientIIN,
                          l10n: l10n,
                          lang: lang,
                          onLang: onLang,
                        ),
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.chipBg(c),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.withOpacity(0.28)),
                            ),
                            child: Icon(Icons.warning_amber_rounded, color: c),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${a.patientName} • ${a.title}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 3),
                                Text(a.subtitle, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================== PATIENT DETAIL (Doctor view) ==============================

class DoctorPatientDetailPage extends StatefulWidget {
  const DoctorPatientDetailPage({
    super.key,
    required this.store,
    required this.patientIIN,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final String patientIIN;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  State<DoctorPatientDetailPage> createState() => _DoctorPatientDetailPageState();
}

class _DoctorPatientDetailPageState extends State<DoctorPatientDetailPage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final p = widget.store.patientByIIN(widget.patientIIN);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('patients'))),
        body: Center(child: Text(l10n.t('empty'))),
      );
    }

    final tabs = [
      (Icons.grid_view_rounded, l10n.t('overview')),
      (Icons.event_available_outlined, l10n.t('requests')),
      (Icons.photo_library_outlined, l10n.t('photos')),
      (Icons.show_chart, l10n.t('timeline')),
      (Icons.checklist_outlined, l10n.t('checklist')),
      (Icons.calendar_month_outlined, l10n.t('slots')),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // user asked: add back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${p.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _LangPill(lang: widget.lang, onLang: widget.onLang),
          ),
        ],
      ),
      body: Column(
        children: [
          // top tabs row (like screenshot)
          Container(
            color: const Color(0xFFF1E8E1),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final active = tab == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? AppColors.outline : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(tabs[i].$1, size: 18, color: active ? AppColors.primary : AppColors.textMuted),
                            const SizedBox(width: 8),
                            Text(
                              tabs[i].$2,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: active ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _DoctorPatientTabBody(
                store: widget.store,
                l10n: l10n,
                patient: p,
                tab: tab,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorPatientTabBody extends StatelessWidget {
  const _DoctorPatientTabBody({
    required this.store,
    required this.l10n,
    required this.patient,
    required this.tab,
  });

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;
  final int tab;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 0:
        return _PatientOverviewCard(store: store, l10n: l10n, patient: patient);
      case 1:
        return _PatientRequestsCard(store: store, l10n: l10n, patient: patient, asDoctor: true);
      case 2:
        return _PhotosCard(store: store, l10n: l10n, patient: patient, canUpload: false);
      case 3:
        return _TimelineCard(store: store, l10n: l10n, patient: patient);
      case 4:
        return _ChecklistCard(store: store, l10n: l10n, patient: patient, editable: false);
      case 5:
        return _SlotsCalendarCard(store: store, l10n: l10n, patient: patient, asDoctor: true);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PatientOverviewCard extends StatelessWidget {
  const _PatientOverviewCard({required this.store, required this.l10n, required this.patient});

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;

  @override
  Widget build(BuildContext context) {
    final risk = store.computeRisk(patient);
    final r = patient.readings.isEmpty ? null : patient.readings.first;

    final riskText = risk < 45
        ? l10n.t('riskLow')
        : risk < 70
            ? l10n.t('riskMed')
            : l10n.t('riskHigh');

    final riskColor = risk < 45
        ? AppColors.accentGreen
        : risk < 70
            ? AppColors.accentAmber
            : AppColors.accentRed;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.chipBg(riskColor),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: riskColor.withOpacity(0.28)),
                  ),
                  child: Center(
                    child: Text(
                      '$risk',
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(riskText, style: TextStyle(color: riskColor, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        l10n.lang == AppLang.ru
                            ? 'Сводка: показатели мониторинга между визитами.'
                            : 'Summary: monitoring indicators between visits.',
                        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lang == AppLang.ru ? 'Vitals' : 'Vitals', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _VitalChip(
                      color: AppColors.accentBlue,
                      label: l10n.lang == AppLang.ru ? 'Температура' : 'Temp',
                      value: r == null ? '—' : '${r.tempC.toStringAsFixed(1)}°C',
                    ),
                    _VitalChip(
                      color: AppColors.accentTeal,
                      label: l10n.lang == AppLang.ru ? 'Влажность' : 'Humidity',
                      value: r == null ? '—' : '${r.humidityPct.toStringAsFixed(0)}%',
                    ),
                    _VitalChip(
                      color: AppColors.accentPurple,
                      label: l10n.lang == AppLang.ru ? 'Давление' : 'Pressure',
                      value: r == null ? '—' : '${r.pressure10}/10',
                    ),
                    _VitalChip(
                      color: AppColors.primary,
                      label: 'pH',
                      value: r == null ? '—' : r.ph.toStringAsFixed(1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${l10n.t('lastUpdate')}: ${r == null ? '—' : _fmtDateTime(r.ts)}',
                  style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VitalChip extends StatelessWidget {
  const _VitalChip({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.chipBg(color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
          const SizedBox(width: 10),
          Text('$label ', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.store, required this.l10n, required this.patient});

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;

  @override
  Widget build(BuildContext context) {
    final readings = [...patient.readings]..sort((a, b) => a.ts.compareTo(b.ts));
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lang == AppLang.ru ? 'Mini chart' : 'Mini chart',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: readings.length < 2
                      ? Center(
                          child: Text(l10n.t('empty'),
                              style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                        )
                      : CustomPaint(
                          painter: _VitalsChartPainter(readings: readings),
                          child: const SizedBox.expand(),
                        ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: const [
                    _LegendDot(color: AppColors.accentBlue, text: 'Temp'),
                    _LegendDot(color: AppColors.accentTeal, text: 'Humidity'),
                    _LegendDot(color: AppColors.accentPurple, text: 'Pressure'),
                    _LegendDot(color: AppColors.primary, text: 'pH'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lang == AppLang.ru ? 'Readings' : 'Readings',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                ...patient.readings.take(12).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: const Icon(Icons.sensors, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_fmtDateTime(r.ts), style: const TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Temp: ${r.tempC.toStringAsFixed(1)}°C   '
                                    'Humidity: ${r.humidityPct.toStringAsFixed(0)}%   '
                                    'Pressure: ${r.pressure10}/10   '
                                    'pH: ${r.ph.toStringAsFixed(1)}',
                                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMuted)),
      ],
    );
  }
}

class _VitalsChartPainter extends CustomPainter {
  _VitalsChartPainter({required this.readings});
  final List<Reading> readings;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 14.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    final temps = readings.map((e) => e.tempC).toList();
    final hums = readings.map((e) => e.humidityPct).toList();
    final prs = readings.map((e) => e.pressure10.toDouble()).toList();
    final phs = readings.map((e) => e.ph).toList();

    double minTemp = temps.reduce(math.min), maxTemp = temps.reduce(math.max);
    double minHum = hums.reduce(math.min), maxHum = hums.reduce(math.max);
    double minPr = prs.reduce(math.min), maxPr = prs.reduce(math.max);
    double minPh = phs.reduce(math.min), maxPh = phs.reduce(math.max);

    // avoid flat lines
    if ((maxTemp - minTemp).abs() < 0.01) {
      maxTemp += 0.5;
      minTemp -= 0.5;
    }
    if ((maxHum - minHum).abs() < 0.01) {
      maxHum += 5;
      minHum -= 5;
    }
    if ((maxPr - minPr).abs() < 0.01) {
      maxPr += 1;
      minPr -= 1;
    }
    if ((maxPh - minPh).abs() < 0.01) {
      maxPh += 0.3;
      minPh -= 0.3;
    }

    // grid
    final gridPaint = Paint()
      ..color = AppColors.outline.withOpacity(0.7)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = pad + h * (i / 4);
      canvas.drawLine(Offset(pad, y), Offset(pad + w, y), gridPaint);
    }

    void drawSeries(List<double> values, double minV, double maxV, Color color) {
      final p = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final x = pad + w * (i / (values.length - 1));
        final t = (values[i] - minV) / (maxV - minV);
        final y = pad + h * (1 - t);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, p);

      // last dot
      final lx = pad + w;
      final lt = (values.last - minV) / (maxV - minV);
      final ly = pad + h * (1 - lt);
      final dot = Paint()..color = color;
      canvas.drawCircle(Offset(lx, ly), 3.4, dot);
    }

    drawSeries(temps, minTemp, maxTemp, AppColors.accentBlue);
    drawSeries(hums, minHum, maxHum, AppColors.accentTeal);
    drawSeries(prs, minPr, maxPr, AppColors.accentPurple);
    drawSeries(phs, minPh, maxPh, AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _VitalsChartPainter oldDelegate) => oldDelegate.readings != readings;
}

class _ChecklistCard extends StatefulWidget {
  const _ChecklistCard({
    required this.store,
    required this.l10n,
    required this.patient,
    required this.editable,
  });

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;
  final bool editable;

  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  late bool stayedDry;
  late bool noWaterInside;
  late bool noStrongItch;
  late bool noSwelling;
  late bool noBadSmell;

  @override
  void initState() {
    super.initState();
    final last = widget.patient.checklistHistory.isEmpty ? null : widget.patient.checklistHistory.first;
    stayedDry = last?.stayedDry ?? true;
    noWaterInside = last?.noWaterInside ?? true;
    noStrongItch = last?.noStrongItch ?? true;
    noSwelling = last?.noSwelling ?? true;
    noBadSmell = last?.noBadSmell ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final last = widget.patient.checklistHistory.isEmpty ? null : widget.patient.checklistHistory.first;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('checklist'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 12),
                if (widget.editable) ...[
                  _SwitchRow(
                    label: l10n.lang == AppLang.ru ? 'Гипс оставался сухим' : 'Cast stayed dry',
                    value: stayedDry,
                    onChanged: (v) => setState(() => stayedDry = v),
                  ),
                  _SwitchRow(
                    label: l10n.lang == AppLang.ru ? 'Вода не попадала под гипс' : 'No water inside cast',
                    value: noWaterInside,
                    onChanged: (v) => setState(() => noWaterInside = v),
                  ),
                  _SwitchRow(
                    label: l10n.lang == AppLang.ru ? 'Не было сильного зуда' : 'No strong itch',
                    value: noStrongItch,
                    onChanged: (v) => setState(() => noStrongItch = v),
                  ),
                  _SwitchRow(
                    label: l10n.lang == AppLang.ru ? 'Не было сильного отека' : 'No swelling',
                    value: noSwelling,
                    onChanged: (v) => setState(() => noSwelling = v),
                  ),
                  _SwitchRow(
                    label: l10n.lang == AppLang.ru ? 'Не было неприятного запаха' : 'No bad smell',
                    value: noBadSmell,
                    onChanged: (v) => setState(() => noBadSmell = v),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: () {
                        widget.store.saveChecklist(
                          widget.patient.iin,
                          ChecklistEntry(
                            ts: DateTime.now(),
                            stayedDry: stayedDry,
                            noWaterInside: noWaterInside,
                            noStrongItch: noStrongItch,
                            noSwelling: noSwelling,
                            noBadSmell: noBadSmell,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.t('save'))));
                      },
                      child: Text(l10n.t('save')),
                    ),
                  ),
                ] else ...[
                  // read-only (doctor view)
                  _ReadOnlyCheck(label: l10n.lang == AppLang.ru ? 'Гипс оставался сухим' : 'Cast stayed dry', ok: last?.stayedDry ?? false),
                  _ReadOnlyCheck(label: l10n.lang == AppLang.ru ? 'Вода не попадала под гипс' : 'No water inside cast', ok: last?.noWaterInside ?? false),
                  _ReadOnlyCheck(label: l10n.lang == AppLang.ru ? 'Не было сильного зуда' : 'No strong itch', ok: last?.noStrongItch ?? false),
                  _ReadOnlyCheck(label: l10n.lang == AppLang.ru ? 'Не было сильного отека' : 'No swelling', ok: last?.noSwelling ?? false),
                  _ReadOnlyCheck(label: l10n.lang == AppLang.ru ? 'Не было неприятного запаха' : 'No bad smell', ok: last?.noBadSmell ?? false),
                ],
                const SizedBox(height: 10),
                Text(
                  '${l10n.t('lastUpdate')}: ${last == null ? '—' : _fmtDateTime(last.ts)}',
                  style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('history'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                if (widget.patient.checklistHistory.isEmpty)
                  Text(l10n.t('empty'), style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))
                else
                  ...widget.patient.checklistHistory.take(12).map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.bg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.outline),
                                  ),
                                  child: const Icon(Icons.fact_check_outlined, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${_fmtDateTime(e.ts)} • '
                                    '${_ok(e.stayedDry)} ${_ok(e.noWaterInside)} ${_ok(e.noStrongItch)} ${_ok(e.noSwelling)} ${_ok(e.noBadSmell)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _ok(bool v) => v ? '✓' : '✕';
}

class _ReadOnlyCheck extends StatelessWidget {
  const _ReadOnlyCheck({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final c = ok ? AppColors.accentGreen : AppColors.accentRed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PatientRequestsCard extends StatefulWidget {
  const _PatientRequestsCard({
    required this.store,
    required this.l10n,
    required this.patient,
    required this.asDoctor,
  });

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;
  final bool asDoctor;

  @override
  State<_PatientRequestsCard> createState() => _PatientRequestsCardState();
}

class _PatientRequestsCardState extends State<_PatientRequestsCard> {
  final noteC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final reqs = widget.patient.requests;

    return ListView(
      children: [
        if (!widget.asDoctor) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('sendRequest'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteC,
                    decoration: InputDecoration(
                      labelText: l10n.t('note'),
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () async {
                      final slot = await showDialog<DateTime>(
                        context: context,
                        builder: (_) => _PickSlotDialog(l10n: l10n),
                      );
                      if (slot == null) return;
                      widget.store.addRequest(widget.patient.iin, slot, noteC.text.trim());
                      noteC.clear();
                    },
                    icon: const Icon(Icons.event_available),
                    label: Text(l10n.t('pickSlot')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('requests'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                if (reqs.isEmpty)
                  Text(l10n.t('empty'), style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))
                else
                  ...reqs.map((r) {
                    final c = r.status == 'Confirmed'
                        ? AppColors.accentGreen
                        : r.status == 'Rejected'
                            ? AppColors.accentRed
                            : AppColors.accentAmber;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.chipBg(c),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: c.withOpacity(0.28)),
                              ),
                              child: Icon(Icons.calendar_month, color: c),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_fmtDateTime(r.slot), style: const TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r.status} • ${r.note}',
                                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.asDoctor && r.status == 'Pending') ...[
                              TextButton(
                                onPressed: () => widget.store.updateRequestStatus(widget.patient.iin, r.id, 'Confirmed'),
                                child: Text(l10n.lang == AppLang.ru ? 'Подтв.' : 'Confirm'),
                              ),
                              TextButton(
                                onPressed: () => widget.store.updateRequestStatus(widget.patient.iin, r.id, 'Rejected'),
                                child: Text(l10n.lang == AppLang.ru ? 'Откл.' : 'Reject'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PickSlotDialog extends StatefulWidget {
  const _PickSlotDialog({required this.l10n});
  final L10n l10n;

  @override
  State<_PickSlotDialog> createState() => _PickSlotDialogState();
}

class _PickSlotDialogState extends State<_PickSlotDialog> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(l10n.t('pickSlot')),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MonthHeader(
              month: month,
              onPrev: () => setState(() => month = DateTime(month.year, month.month - 1, 1)),
              onNext: () => setState(() => month = DateTime(month.year, month.month + 1, 1)),
            ),
            const SizedBox(height: 10),
            MonthCalendar(
              month: month,
              selected: selected,
              onSelect: (d) => setState(() => selected = d),
              mode: CalendarMode.slots,
            ),
            const SizedBox(height: 10),
            if (selected != null)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _slotHoursForDay(selected!).map((h) {
                  final slot = DateTime(selected!.year, selected!.month, selected!.day, h);
                  return OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(slot),
                    child: Text('${h.toString().padLeft(2, '0')}:00'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.lang == AppLang.ru ? 'Отмена' : 'Cancel')),
      ],
    );
  }

  List<int> _slotHoursForDay(DateTime day) => [9, 10, 11, 14, 15, 16];
}

class _SlotsCalendarCard extends StatefulWidget {
  const _SlotsCalendarCard({
    required this.store,
    required this.l10n,
    required this.patient,
    required this.asDoctor,
  });

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;
  final bool asDoctor;

  @override
  State<_SlotsCalendarCard> createState() => _SlotsCalendarCardState();
}

class _SlotsCalendarCardState extends State<_SlotsCalendarCard> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('slots'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                _MonthHeader(
                  month: month,
                  onPrev: () => setState(() => month = DateTime(month.year, month.month - 1, 1)),
                  onNext: () => setState(() => month = DateTime(month.year, month.month + 1, 1)),
                ),
                const SizedBox(height: 10),
                MonthCalendar(
                  month: month,
                  selected: selectedDay,
                  onSelect: (d) => setState(() => selectedDay = d),
                  mode: CalendarMode.slots,
                ),
                const SizedBox(height: 10),
                if (selectedDay != null) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _slotHoursForDay(selectedDay!).map((h) {
                      final slot = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day, h);
                      return OutlinedButton.icon(
                        onPressed: widget.asDoctor
                            ? null
                            : () {
                                widget.store.addRequest(widget.patient.iin, slot, '');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.lang == AppLang.ru ? 'Запрос отправлен' : 'Request sent')),
                                );
                              },
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text('${h.toString().padLeft(2, '0')}:00'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.asDoctor
                        ? (l10n.lang == AppLang.ru ? 'Доктор: слоты только для просмотра' : 'Doctor: view-only slots')
                        : (l10n.lang == AppLang.ru ? 'Нажмите время чтобы отправить запрос' : 'Tap a time to send request'),
                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<int> _slotHoursForDay(DateTime day) => [9, 10, 11, 14, 15, 16];
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({
    required this.store,
    required this.l10n,
    required this.patient,
    required this.canUpload,
  });

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;
  final bool canUpload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(l10n.t('photos'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const Spacer(),
                if (canUpload)
                  FilledButton.icon(
                    onPressed: () => store.addPhoto(patient.iin),
                    icon: const Icon(Icons.upload),
                    label: Text(l10n.lang == AppLang.ru ? 'Загрузить' : 'Upload'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (patient.photoDataUrls.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(l10n.t('empty'), style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800)),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(patient.photoDataUrls.length, (i) {
              final url = patient.photoDataUrls[i];
              return SizedBox(
                width: 260,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(url, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.lang == AppLang.ru ? 'Фото' : 'Photo'} #${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (canUpload)
                              IconButton(
                                tooltip: l10n.t('delete'),
                                onPressed: () => store.deletePhoto(patient.iin, i),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}

// ============================== PATIENT SHELL (different UI) ==============================

class PatientShell extends StatefulWidget {
  const PatientShell({
    super.key,
    required this.store,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int idx = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final u = widget.store.currentUser!;
    final profile = widget.store.patientByIIN(u.iin);

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.t('smartcast')),
          actions: [Padding(padding: const EdgeInsets.only(right: 10), child: _LangPill(lang: widget.lang, onLang: widget.onLang))],
        ),
        body: Center(child: Text(l10n.t('empty'))),
      );
    }

    final pages = [
      _PatientDashboardTab(store: widget.store, l10n: l10n, patient: profile),
      _ChecklistCard(store: widget.store, l10n: l10n, patient: profile, editable: true),
      _PatientRequestsCard(store: widget.store, l10n: l10n, patient: profile, asDoctor: false),
      _PhotosCard(store: widget.store, l10n: l10n, patient: profile, canUpload: true),
      _SettingsTab(store: widget.store, l10n: l10n, lang: widget.lang, onLang: widget.onLang),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.t('smartcast')} • ${u.fullName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _LangPill(lang: widget.lang, onLang: widget.onLang),
          ),
        ],
      ),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: pages[idx])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (v) => setState(() => idx = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: l10n.t('dashboard')),
          NavigationDestination(icon: const Icon(Icons.checklist_outlined), label: l10n.t('checklist')),
          NavigationDestination(icon: const Icon(Icons.event_available_outlined), label: l10n.t('visits')),
          NavigationDestination(icon: const Icon(Icons.photo_library_outlined), label: l10n.t('photos')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.t('settings')),
        ],
      ),
    );
  }
}

class _PatientDashboardTab extends StatelessWidget {
  const _PatientDashboardTab({
    required this.store,
    required this.l10n,
    required this.patient,
  });

  final AppStore store;
  final L10n l10n;
  final PatientProfile patient;

  @override
  Widget build(BuildContext context) {
    final r = patient.readings.isEmpty ? null : patient.readings.first;
    final risk = store.computeRisk(patient);
    final riskColor = risk < 45
        ? AppColors.accentGreen
        : risk < 70
            ? AppColors.accentAmber
            : AppColors.accentRed;

    // Patient dashboard: cards grid (NOT same as doctor)
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth >= 920;
        final colW = twoCols ? (c.maxWidth - 12) / 2 : c.maxWidth;

        Widget card(Widget child) => SizedBox(width: colW, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: child)));

        return SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.t('health'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.chipBg(riskColor),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: riskColor.withOpacity(0.28)),
                          ),
                          child: Text(
                            'RISK $risk',
                            style: TextStyle(color: riskColor, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _VitalChip(
                          color: AppColors.accentBlue,
                          label: l10n.lang == AppLang.ru ? 'Температура' : 'Temp',
                          value: r == null ? '—' : '${r.tempC.toStringAsFixed(1)}°C',
                        ),
                        _VitalChip(
                          color: AppColors.accentTeal,
                          label: l10n.lang == AppLang.ru ? 'Влажность' : 'Humidity',
                          value: r == null ? '—' : '${r.humidityPct.toStringAsFixed(0)}%',
                        ),
                        _VitalChip(
                          color: AppColors.accentPurple,
                          label: l10n.lang == AppLang.ru ? 'Давление' : 'Pressure',
                          value: r == null ? '—' : '${r.pressure10}/10',
                        ),
                        _VitalChip(
                          color: AppColors.primary,
                          label: 'pH',
                          value: r == null ? '—' : r.ph.toStringAsFixed(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: patient.readings.length < 2
                          ? Center(child: Text(l10n.t('empty')))
                          : CustomPaint(
                              painter: _VitalsChartPainter(readings: [...patient.readings]..sort((a, b) => a.ts.compareTo(b.ts))),
                              child: const SizedBox.expand(),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.t('lastUpdate')}: ${r == null ? '—' : _fmtDateTime(r.ts)}',
                      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.lang == AppLang.ru ? 'Запись на приём' : 'Appointment',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),
                    MonthCalendar(
                      month: DateTime(DateTime.now().year, DateTime.now().month, 1),
                      selected: null,
                      onSelect: (_) {},
                      mode: CalendarMode.compact,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.lang == AppLang.ru ? 'Выберите вкладку «Визиты» чтобы отправить запрос' : 'Open “Visits” to send a request',
                      style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.t('myDoctors'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),
                    _DoctorMiniTile(name: 'Dr. A. Sadykova', subtitle: l10n.lang == AppLang.ru ? 'Ортопед' : 'Orthopedist'),
                    const SizedBox(height: 10),
                    _DoctorMiniTile(name: l10n.lang == AppLang.ru ? 'Дежурный врач' : 'On-call doctor', subtitle: l10n.lang == AppLang.ru ? 'Клиника' : 'Clinic'),
                  ],
                ),
              ),
              card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.lang == AppLang.ru ? 'Советы' : 'Tips',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),
                    _TipRow(icon: Icons.check_circle_outline, color: AppColors.accentGreen, text: l10n.lang == AppLang.ru ? 'Заполняйте чек-лист 1 раз в день' : 'Fill the checklist daily'),
                    _TipRow(icon: Icons.photo_camera_outlined, color: AppColors.accentBlue, text: l10n.lang == AppLang.ru ? 'Добавляйте фото при изменениях' : 'Upload photos if changes appear'),
                    _TipRow(icon: Icons.event_available_outlined, color: AppColors.accentAmber, text: l10n.lang == AppLang.ru ? 'При тревоге отправьте запрос на визит' : 'If worried, send a visit request'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DoctorMiniTile extends StatelessWidget {
  const _DoctorMiniTile({required this.name, required this.subtitle});
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        color: Colors.white,
      ),
      child: Row(
        children: [
          _AvatarCircle(name: name, color: AppColors.accentPurple, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

// ============================== SETTINGS ==============================

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.store,
    required this.l10n,
    required this.lang,
    required this.onLang,
  });

  final AppStore store;
  final L10n l10n;
  final AppLang lang;
  final ValueChanged<AppLang> onLang;

  @override
  Widget build(BuildContext context) {
    final u = store.currentUser;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _AvatarCircle(name: u?.fullName ?? '—', color: AppColors.primary, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u?.fullName ?? '—', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(u?.iin ?? '—', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => onLang(lang == AppLang.ru ? AppLang.en : AppLang.ru),
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(lang == AppLang.ru ? 'RU' : 'EN'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('settings'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.t('logout'), style: const TextStyle(fontWeight: FontWeight.w900)),
                  onTap: () => store.logout(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================== CALENDAR ==============================

enum CalendarMode { compact, slots }

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onPrev, required this.onNext});

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final title = '${_monthName(month.month)} ${month.year}';
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Center(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.onSelect,
    required this.mode,
  });

  final DateTime month; // first day of month
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final CalendarMode mode;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekday = (first.weekday + 6) % 7; // Monday=0
    final totalCells = ((weekday + daysInMonth) <= 35) ? 35 : 42;

    final items = List<DateTime?>.filled(totalCells, null);
    for (int i = 0; i < daysInMonth; i++) {
      items[weekday + i] = DateTime(month.year, month.month, i + 1);
    }

    final headerStyle = TextStyle(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w800,
      fontSize: mode == CalendarMode.compact ? 12 : 13,
    );

    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: _Dow('M')),
            Expanded(child: _Dow('T')),
            Expanded(child: _Dow('W')),
            Expanded(child: _Dow('T')),
            Expanded(child: _Dow('F')),
            Expanded(child: _Dow('S')),
            Expanded(child: _Dow('S')),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, i) {
            final d = items[i];
            if (d == null) return const SizedBox.shrink();

            final isSel = selected != null && _sameDate(selected!, d);
            final isToday = _sameDate(DateTime.now(), d);

            final bg = isSel
                ? AppColors.primary.withOpacity(0.18)
                : isToday
                    ? AppColors.accentBlue.withOpacity(0.10)
                    : Colors.white;

            final bd = isSel
                ? AppColors.primary.withOpacity(0.35)
                : isToday
                    ? AppColors.accentBlue.withOpacity(0.25)
                    : AppColors.outline;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(d),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bd),
                ),
                child: Center(
                  child: Text(
                    '${d.day}',
                    style: headerStyle.copyWith(
                      color: isSel ? AppColors.primary : AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.t);
  final String t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        t,
        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ============================== SMALL UI HELPERS ==============================

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.name, required this.color, required this.size});

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = (parts.isEmpty ? '?' : parts.first[0]) + (parts.length > 1 ? parts[1][0] : '');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: size * 0.34),
        ),
      ),
    );
  }
}

// ============================== UTILS ==============================

String _fmtDateTime(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String _monthName(int m) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[(m - 1).clamp(0, 11)];
}

bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
