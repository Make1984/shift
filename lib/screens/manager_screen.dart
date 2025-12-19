import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/shift_service.dart';
import '../models/shift.dart';
import 'leader_screen.dart';
import 'weekly_shift_screen.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final Set<String> _selectedShiftIds = {};

  void _toggleSelection(String shiftId) {
    setState(() {
      if (_selectedShiftIds.contains(shiftId)) {
        _selectedShiftIds.remove(shiftId);
      } else {
        _selectedShiftIds.add(shiftId);
      }
    });
  }

  void _toggleUserSelection(List<Shift> userShifts) {
    final allSelected = userShifts.every(
      (s) => _selectedShiftIds.contains(s.id),
    );
    setState(() {
      if (allSelected) {
        for (var s in userShifts) {
          _selectedShiftIds.remove(s.id);
        }
      } else {
        for (var s in userShifts) {
          _selectedShiftIds.add(s.id);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedShiftIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftService = Provider.of<ShiftService>(context);
    final today = DateTime.now();
    final allShifts = shiftService.shifts;
    final todayShifts =
        shiftService
            .getShiftsForDate(today)
            .where((s) => s.status == ShiftStatus.confirmed)
            .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('店長用：管理・状況確認'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            if (_selectedShiftIds.isNotEmpty)
              TextButton(
                onPressed: _clearSelection,
                child: Text(
                  '選択解除 (${_selectedShiftIds.length})',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.view_week),
              tooltip: '週間シフト表',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeeklyShiftScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              tooltip: 'シフト調整画面へ',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaderScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => shiftService.setCurrentUser(null),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '本日の状況'),
              Tab(text: '本日の詳細'),
              Tab(text: 'スタッフ別月間'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
          ),
        ),
        body: TabBarView(
          children: [
            _buildTodayView(context, shiftService, todayShifts),
            _buildTodayDetailedView(context, todayShifts),
            _buildStaffMonthlyView(
              context,
              shiftService,
              allShifts.where((s) => s.status != ShiftStatus.canceled).toList(),
            ),
          ],
        ),
        bottomNavigationBar:
            _selectedShiftIds.isEmpty
                ? null
                : _buildBulkActionBar(context, shiftService),
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context, ShiftService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                service.bulkUpdateShiftStatus(
                  _selectedShiftIds.toList(),
                  ShiftStatus.confirmed,
                );
                _clearSelection();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('一括確定しました')));
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('一括確定'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showBulkBreakEditDialog(context, service);
              },
              icon: const Icon(Icons.restaurant),
              label: const Text('一括休憩'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('一括取り消し'),
                        content: Text(
                          '選択した ${_selectedShiftIds.length} 件のシフトを取り消しますか？',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () {
                              service.bulkUpdateShiftStatus(
                                _selectedShiftIds.toList(),
                                ShiftStatus.canceled,
                              );
                              _clearSelection();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('一括取り消ししました')),
                              );
                            },
                            child: const Text(
                              '取り消す',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
              icon: const Icon(Icons.cancel),
              label: const Text('一括取消'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkBreakEditDialog(BuildContext context, ShiftService service) {
    TimeOfDay? start = const TimeOfDay(hour: 12, minute: 0);
    TimeOfDay? end = const TimeOfDay(hour: 13, minute: 0);
    int duration = 60;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('一括休憩設定'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('選択した ${_selectedShiftIds.length} 件に適用します'),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('開始時間'),
                        trailing: Text(start?.format(context) ?? '--:--'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: start!,
                          );
                          if (picked != null) {
                            setState(() {
                              start = picked;
                              if (end != null) {
                                duration =
                                    (end!.hour * 60 + end!.minute) -
                                    (start!.hour * 60 + start!.minute);
                              }
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('終了時間'),
                        trailing: Text(end?.format(context) ?? '--:--'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: end!,
                          );
                          if (picked != null) {
                            setState(() {
                              end = picked;
                              if (start != null) {
                                duration =
                                    (end!.hour * 60 + end!.minute) -
                                    (start!.hour * 60 + start!.minute);
                              }
                            });
                          }
                        },
                      ),
                      const Divider(),
                      Text(
                        '休憩時間: ${duration > 0 ? "$duration分" : "なし"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        service.bulkUpdateShiftBreak(
                          _selectedShiftIds.toList(),
                          duration,
                          start,
                          end,
                        );
                        _clearSelection();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('一括設定しました')),
                        );
                      },
                      child: const Text('適用'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildTodayView(
    BuildContext context,
    ShiftService shiftService,
    List<Shift> todayShifts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(todayShifts),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '本日の出勤者一覧',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child:
              todayShifts.isEmpty
                  ? const Center(child: Text('本日の確定済みシフトはありません'))
                  : ListView.builder(
                    itemCount: todayShifts.length,
                    itemBuilder: (context, index) {
                      final shift = todayShifts[index];
                      return _buildStaffTile(context, shift);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildTodayDetailedView(BuildContext context, List<Shift> shifts) {
    if (shifts.isEmpty) {
      return const Center(child: Text('本日の確定済みシフトはありません'));
    }

    return ListView.builder(
      itemCount: shifts.length,
      itemBuilder: (context, index) {
        final rawShift = shifts[index];
        final shift = Shift.autoAllocateBreak(rawShift);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      shift.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '実働 ${shift.workHours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '勤務時間: ${shift.startTime.format(context)} - ${shift.endTime.format(context)}',
                    ),
                  ],
                ),
                if (shift.breakDurationMinutes > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '休憩時間: ${shift.breakStartTime!.format(context)} - ${shift.breakEndTime!.format(context)} (${shift.breakDurationMinutes}分)',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.restaurant, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('休憩なし', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffMonthlyView(
    BuildContext context,
    ShiftService service,
    List<Shift> shifts,
  ) {
    final Map<String, List<Shift>> groupedShifts = {};
    for (var shift in shifts) {
      if (!groupedShifts.containsKey(shift.userName)) {
        groupedShifts[shift.userName] = [];
      }
      groupedShifts[shift.userName]!.add(shift);
    }

    final userNames = groupedShifts.keys.toList();

    if (userNames.isEmpty) {
      return const Center(child: Text('提出されたシフトはありません'));
    }

    return ListView.builder(
      itemCount: userNames.length,
      itemBuilder: (context, index) {
        final userName = userNames[index];
        final userShifts = groupedShifts[userName]!;
        final allSelected = userShifts.every(
          (s) => _selectedShiftIds.contains(s.id),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: Checkbox(
              value: allSelected,
              onChanged: (_) => _toggleUserSelection(userShifts),
            ),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${userShifts.length}件のシフト'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed:
                  () => _showResetConfirmation(
                    context,
                    service,
                    userName,
                    userShifts[0].userId,
                  ),
              tooltip: 'このスタッフのデータを初期化',
            ),
            children:
                userShifts.map((shift) {
                  final isSelected = _selectedShiftIds.contains(shift.id);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(shift.id),
                    ),
                    title: Text(
                      '${DateFormat('MM/dd(E)', 'ja_JP').format(shift.date)} ${shift.startTime.format(context)} - ${shift.endTime.format(context)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text('ステータス: ${_getStatusText(shift.status)}'),
                    trailing: Icon(
                      Icons.circle,
                      color: _getStatusColor(shift.status),
                      size: 10,
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(List<Shift> shifts) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('日付', DateFormat('MM/dd').format(DateTime.now())),
            _buildStatItem('出勤人数', '${shifts.length}名'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.orange.shade900)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showResetConfirmation(
    BuildContext context,
    ShiftService service,
    String userName,
    String userId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('データの初期化'),
            content: Text('$userName さんのシフトデータを初期状態に戻しますか？\n（全てのシフトが削除されます）'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  service.resetUserShifts(userId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('データを初期化しました')));
                },
                child: const Text('リセット', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }

  Widget _buildStaffTile(BuildContext context, Shift shift) {
    final shiftService = Provider.of<ShiftService>(context, listen: false);
    final user = shiftService.users.firstWhere((u) => u.id == shift.userId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          shift.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${shift.startTime.format(context)} - ${shift.endTime.format(context)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.contact} に発信します（デモ）')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed:
                  () => _showResetConfirmation(
                    context,
                    shiftService,
                    shift.userName,
                    shift.userId,
                  ),
              tooltip: '初期化',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('シフトの取り消し'),
                        content: const Text('このシフトを取り消しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () {
                              shiftService.updateShiftStatus(
                                shift.id,
                                ShiftStatus.canceled,
                              );
                              Navigator.pop(context);
                            },
                            child: const Text(
                              '取り消す',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
              tooltip: '取り消し',
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.submitted:
        return '提出中';
      case ShiftStatus.adjusting:
        return '調整中';
      case ShiftStatus.confirmed:
        return '確定';
      case ShiftStatus.canceled:
        return '取り消し';
    }
  }

  Color _getStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.submitted:
        return Colors.orange;
      case ShiftStatus.adjusting:
        return Colors.blue;
      case ShiftStatus.confirmed:
        return Colors.green;
      case ShiftStatus.canceled:
        return Colors.red;
    }
  }
}
