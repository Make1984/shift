import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/shift_service.dart';
import '../models/shift.dart';

class WeeklyShiftScreen extends StatefulWidget {
  const WeeklyShiftScreen({super.key});

  @override
  State<WeeklyShiftScreen> createState() => _WeeklyShiftScreenState();
}

class _WeeklyShiftScreenState extends State<WeeklyShiftScreen> {
  late DateTime _currentWeekMonday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // 今週の月曜日を初期値にする
    _currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));
  }

  void _moveWeek(int weeks) {
    setState(() {
      _currentWeekMonday = _currentWeekMonday.add(Duration(days: weeks * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftService = Provider.of<ShiftService>(context);
    final weekDays = List.generate(
      7,
      (index) => _currentWeekMonday.add(Duration(days: index)),
    );

    final weekRangeText =
        '${DateFormat('MM/dd').format(weekDays.first)} - ${DateFormat('MM/dd').format(weekDays.last)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('週間シフト表'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '今週に戻る',
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _currentWeekMonday = now.subtract(
                  Duration(days: now.weekday - 1),
                );
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekNavigator(weekRangeText),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = weekDays[index];
                final shifts =
                    shiftService
                        .getShiftsForDate(date)
                        .where((s) => s.status == ShiftStatus.confirmed)
                        .toList();

                return _buildDaySection(context, date, shifts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator(String rangeText) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.indigo.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => _moveWeek(-1),
          ),
          Text(
            rangeText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => _moveWeek(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<Shift> shifts,
  ) {
    final isToday =
        DateFormat('yyyyMMdd').format(date) ==
        DateFormat('yyyyMMdd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isToday ? Colors.indigo.shade50 : Colors.grey.shade100,
          child: Text(
            DateFormat('MM/dd (E)', 'ja_JP').format(date),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.indigo : Colors.black87,
            ),
          ),
        ),
        if (shifts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '確定済みシフトはありません',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                horizontalMargin: 12,
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(
                  Colors.indigo.shade50.withOpacity(0.5),
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      '名前',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '時間',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '休憩',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '実働',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows:
                    shifts.map((rawShift) {
                      final s = Shift.autoAllocateBreak(rawShift);
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    s.userName[0],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s.userName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              '${s.startTime.format(context)}-${s.endTime.format(context)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              s.breakDurationMinutes > 0
                                  ? '${s.breakStartTime!.format(context)}-${s.breakEndTime!.format(context)}'
                                  : '-',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${s.workHours.toStringAsFixed(1)}h',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
