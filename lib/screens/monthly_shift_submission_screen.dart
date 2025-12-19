import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/shift_service.dart';
import '../models/shift.dart';
import '../models/user.dart';

class MonthlyShiftSubmissionScreen extends StatefulWidget {
  const MonthlyShiftSubmissionScreen({super.key});

  @override
  State<MonthlyShiftSubmissionScreen> createState() =>
      _MonthlyShiftSubmissionScreenState();
}

class _MonthlyShiftSubmissionScreenState
    extends State<MonthlyShiftSubmissionScreen> {
  late DateTime _selectedMonth;
  final Map<int, String> _patterns =
      {}; // 'none', 'morning', 'late', 'full', 'custom'
  final Map<int, TimeOfDay> _startTimes = {};
  final Map<int, TimeOfDay> _endTimes = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month + 1, 1);
    _initMonthData();
  }

  void _initMonthData() {
    _patterns.clear();
    _startTimes.clear();
    _endTimes.clear();
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      _patterns[i] = 'none';
      _startTimes[i] = const TimeOfDay(hour: 9, minute: 0);
      _endTimes[i] = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  void _applyPatternToAll(String pattern) {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    setState(() {
      for (int i = 1; i <= daysInMonth; i++) {
        _patterns[i] = pattern;
        if (pattern == 'morning') {
          _startTimes[i] = const TimeOfDay(hour: 9, minute: 0);
          _endTimes[i] = const TimeOfDay(hour: 17, minute: 0);
        } else if (pattern == 'late') {
          _startTimes[i] = const TimeOfDay(hour: 17, minute: 0);
          _endTimes[i] = const TimeOfDay(hour: 22, minute: 0);
        } else if (pattern == 'full') {
          _startTimes[i] = const TimeOfDay(hour: 9, minute: 0);
          _endTimes[i] = const TimeOfDay(hour: 22, minute: 0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftService = Provider.of<ShiftService>(context);
    final user = shiftService.currentUser!;
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(title: const Text('1ヶ月分まとめて提出')),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildQuickActions(),
          Expanded(
            child: ListView.builder(
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  day,
                );
                return _buildDayRow(day, date);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSubmitButton(context, shiftService, user),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.indigo.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                  1,
                );
                _initMonthData();
              });
            },
          ),
          Text(
            DateFormat('yyyy年MM月').format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                  1,
                );
                _initMonthData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '一括設定:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickBtn('早番(9-17)', () => _applyPatternToAll('morning')),
              _buildQuickBtn('遅番(17-22)', () => _applyPatternToAll('late')),
              _buildQuickBtn('通し(9-22)', () => _applyPatternToAll('full')),
              _buildQuickBtn(
                'リセット',
                () => _applyPatternToAll('none'),
                isReset: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(
    String label,
    VoidCallback onTap, {
    bool isReset = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: isReset ? Colors.grey.shade200 : Colors.indigo.shade50,
        foregroundColor: isReset ? Colors.grey.shade700 : Colors.indigo,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }

  Widget _buildDayRow(int day, DateTime date) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final currentPattern = _patterns[day];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: currentPattern == 'none' ? 0 : 2,
      color: currentPattern == 'none' ? Colors.grey.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                DateFormat('dd(E)', 'ja_JP').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isWeekend
                          ? (date.weekday == DateTime.sunday
                              ? Colors.red
                              : Colors.blue)
                          : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 4,
                children: [
                  _buildPatternChip(day, 'none', '休み'),
                  _buildPatternChip(day, 'morning', '早'),
                  _buildPatternChip(day, 'late', '遅'),
                  _buildPatternChip(day, 'full', '通'),
                  _buildPatternChip(day, 'custom', '他'),
                ],
              ),
            ),
            if (currentPattern != 'none') ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap:
                    currentPattern == 'custom'
                        ? () => _showTimePickerDialog(day)
                        : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_startTimes[day]!.format(context)}-${_endTimes[day]!.format(context)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternChip(int day, String pattern, String label) {
    final isSelected = _patterns[day] == pattern;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _patterns[day] = pattern;
            if (pattern == 'morning') {
              _startTimes[day] = const TimeOfDay(hour: 9, minute: 0);
              _endTimes[day] = const TimeOfDay(hour: 17, minute: 0);
            } else if (pattern == 'late') {
              _startTimes[day] = const TimeOfDay(hour: 17, minute: 0);
              _endTimes[day] = const TimeOfDay(hour: 22, minute: 0);
            } else if (pattern == 'full') {
              _startTimes[day] = const TimeOfDay(hour: 9, minute: 0);
              _endTimes[day] = const TimeOfDay(hour: 22, minute: 0);
            } else if (pattern == 'custom' && !isSelected) {
              _showTimePickerDialog(day);
            }
          });
        }
      },
      selectedColor: Colors.indigo,
      backgroundColor: Colors.grey.shade200,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showTimePickerDialog(int day) async {
    final start = await showTimePicker(
      context: context,
      initialTime: _startTimes[day]!,
    );
    if (start == null) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _endTimes[day]!,
    );
    if (end == null) return;

    setState(() {
      _startTimes[day] = start;
      _endTimes[day] = end;
      _patterns[day] = 'custom';
    });
  }

  Widget _buildSubmitButton(
    BuildContext context,
    ShiftService service,
    User user,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          final List<Shift> shiftsToAdd = [];
          _patterns.forEach((day, pattern) {
            if (pattern != 'none') {
              shiftsToAdd.add(
                Shift(
                  id:
                      '${user.id}_${_selectedMonth.year}_${_selectedMonth.month}_$day',
                  userId: user.id,
                  userName: user.name,
                  date: DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month,
                    day,
                  ),
                  startTime: _startTimes[day]!,
                  endTime: _endTimes[day]!,
                  status: ShiftStatus.submitted,
                ),
              );
            }
          });

          if (shiftsToAdd.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('出勤する日を選択してください')));
            return;
          }

          _showSubmitConfirmation(context, service, shiftsToAdd);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'まとめて提出する',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showSubmitConfirmation(
    BuildContext context,
    ShiftService service,
    List<Shift> shifts,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('シフトの提出'),
            content: Text('${shifts.length}日分のシフトを提出しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  service.addShifts(shifts);
                  Navigator.pop(context); // ダイアログを閉じる
                  Navigator.pop(context); // 画面を閉じる
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('シフトを提出しました')));
                },
                child: const Text(
                  '提出する',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }
}
