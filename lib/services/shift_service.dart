import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/shift.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShiftService extends ChangeNotifier {
  List<User> _users = [
    User(
      id: '1',
      name: '田中 太郎',
      role: UserRole.staff,
      contact: '090-1111-2222',
      loginId: 'user1',
      password: '1234',
    ),
    User(
      id: '2',
      name: '佐藤 花子',
      role: UserRole.staff,
      contact: '090-3333-4444',
      loginId: 'user2',
      password: '1234',
    ),
    User(
      id: '3',
      name: 'リーダー',
      role: UserRole.leader,
      contact: '090-5555-6666',
      loginId: 'leader1',
      password: '1234',
    ),
    User(
      id: '4',
      name: '店長',
      role: UserRole.manager,
      contact: '090-7777-8888',
      loginId: 'manager1',
      password: '1234',
    ),
  ];

  final List<Shift> _shifts = [];

  User? _currentUser;

  ShiftService() {
    _init();
  }

  Future<void> _init() async {
    await _loadShifts();
    await _loadUsers();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('custom_users');
    if (usersJson != null) {
      for (var jsonStr in usersJson) {
        final map = jsonDecode(jsonStr);
        final user = User(
          id: map['id'],
          name: map['name'],
          role: UserRole.values.firstWhere((e) => e.toString() == map['role']),
          contact: map['contact'],
          loginId: map['loginId'],
          password: map['password'],
        );
        // 重複チェック
        if (!_users.any((u) => u.loginId == user.loginId)) {
          _users.add(user);
        }
      }
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('custom_users') ?? [];
    usersJson.add(
      jsonEncode({
        'id': user.id,
        'name': user.name,
        'role': user.role.toString(),
        'contact': user.contact,
        'loginId': user.loginId,
        'password': user.password,
      }),
    );
    await prefs.setStringList('custom_users', usersJson);
  }

  Future<void> _loadShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final shiftsJson = prefs.getStringList('all_shifts');
    if (shiftsJson != null) {
      _shifts.clear();
      for (var jsonStr in shiftsJson) {
        _shifts.add(Shift.fromJson(jsonDecode(jsonStr)));
      }
    } else {
      // 初期データ（初回起動時のみ）
      _shifts.addAll([
        Shift(
          id: 's1',
          userId: '1',
          userName: '田中 太郎',
          date: DateTime.now(),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          status: ShiftStatus.submitted,
        ),
        Shift(
          id: 's2',
          userId: '2',
          userName: '佐藤 花子',
          date: DateTime.now(),
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          status: ShiftStatus.confirmed,
        ),
      ]);
      await _saveShifts();
    }
  }

  Future<void> _saveShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final shiftsJson = _shifts.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('all_shifts', shiftsJson);
  }

  List<User> get users => _users;
  List<Shift> get shifts => _shifts;
  User? get currentUser => _currentUser;

  bool login(String loginId, String password) {
    try {
      final user = _users.firstWhere(
        (u) =>
            u.loginId?.toLowerCase() == loginId.toLowerCase() &&
            u.password == password,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> register(
    String name,
    String contact,
    String loginId,
    String password,
  ) async {
    final newUser = User(
      id: DateTime.now().toString(),
      name: name,
      role: UserRole.staff,
      contact: contact,
      loginId: loginId,
      password: password,
    );
    _users.add(newUser);
    await _saveUser(newUser);
    _currentUser = newUser;
    notifyListeners();
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void addShift(Shift shift) {
    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index != -1) {
      _shifts[index] = shift;
    } else {
      _shifts.add(shift);
    }
    _saveShifts();
    notifyListeners();
  }

  void addShifts(List<Shift> shifts) {
    for (var shift in shifts) {
      final index = _shifts.indexWhere((s) => s.id == shift.id);
      if (index != -1) {
        _shifts[index] = shift;
      } else {
        _shifts.add(shift);
      }
    }
    _saveShifts();
    notifyListeners();
  }

  void deleteShift(String shiftId) {
    _shifts.removeWhere((s) => s.id == shiftId);
    _saveShifts();
    notifyListeners();
  }

  void updateShiftStatus(String shiftId, ShiftStatus status) {
    final index = _shifts.indexWhere((s) => s.id == shiftId);
    if (index != -1) {
      _shifts[index] = _shifts[index].copyWith(status: status);
      _saveShifts();
      notifyListeners();
    }
  }

  void bulkUpdateShiftStatus(List<String> ids, ShiftStatus status) {
    for (var id in ids) {
      final index = _shifts.indexWhere((s) => s.id == id);
      if (index != -1) {
        _shifts[index] = _shifts[index].copyWith(status: status);
      }
    }
    _saveShifts();
    notifyListeners();
  }

  void updateShiftBreak(
    String shiftId,
    int duration,
    TimeOfDay? start,
    TimeOfDay? end,
  ) {
    final index = _shifts.indexWhere((s) => s.id == shiftId);
    if (index != -1) {
      _shifts[index] = _shifts[index].copyWith(
        breakDurationMinutes: duration,
        breakStartTime: start,
        breakEndTime: end,
      );
      _saveShifts();
      notifyListeners();
    }
  }

  void bulkUpdateShiftBreak(
    List<String> ids,
    int duration,
    TimeOfDay? start,
    TimeOfDay? end,
  ) {
    for (var id in ids) {
      final index = _shifts.indexWhere((s) => s.id == id);
      if (index != -1) {
        _shifts[index] = _shifts[index].copyWith(
          breakDurationMinutes: duration,
          breakStartTime: start,
          breakEndTime: end,
        );
      }
    }
    _saveShifts();
    notifyListeners();
  }

  Future<void> resetUserShifts(String userId) async {
    // 指定されたユーザーのシフトを全て削除
    _shifts.removeWhere((s) => s.userId == userId);

    await _saveShifts();
    notifyListeners();
  }

  List<Shift> getShiftsForUser(String userId) {
    return _shifts.where((s) => s.userId == userId).toList();
  }

  List<Shift> getShiftsForDate(DateTime date) {
    return _shifts
        .where(
          (s) =>
              s.date.year == date.year &&
              s.date.month == date.month &&
              s.date.day == date.day,
        )
        .toList();
  }
}
