import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/shift_service.dart';
import '../models/shift.dart';
import 'weekly_shift_screen.dart';

class LeaderScreen extends StatefulWidget {
  const LeaderScreen({super.key});

  @override
  State<LeaderScreen> createState() => _LeaderScreenState();
}

class _LeaderScreenState extends State<LeaderScreen> {
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
    final allShifts = shiftService.shifts;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト調整・管理'),
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
          if (!canPop)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => shiftService.setCurrentUser(null),
            ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const Material(
              color: Colors.indigo,
              child: TabBar(
                tabs: [Tab(text: '調整が必要なシフト'), Tab(text: '確定済みシフト')],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGroupedShiftList(
                    context,
                    shiftService,
                    allShifts
                        .where(
                          (s) =>
                              s.status != ShiftStatus.confirmed &&
                              s.status != ShiftStatus.canceled,
                        )
                        .toList(),
                  ),
                  _buildGroupedShiftList(
                    context,
                    shiftService,
                    allShifts
                        .where((s) => s.status == ShiftStatus.confirmed)
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _selectedShiftIds.isEmpty
              ? null
              : _buildBulkActionBar(context, shiftService),
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

  Widget _buildGroupedShiftList(
    BuildContext context,
    ShiftService service,
    List<Shift> shifts,
  ) {
    if (shifts.isEmpty) {
      return const Center(child: Text('表示するシフトはありません'));
    }

    final Map<String, List<Shift>> groupedShifts = {};
    for (var shift in shifts) {
      if (!groupedShifts.containsKey(shift.userName)) {
        groupedShifts[shift.userName] = [];
      }
      groupedShifts[shift.userName]!.add(shift);
    }

    final userNames = groupedShifts.keys.toList();

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
            children:
                userShifts.map((shift) {
                  final isSelected = _selectedShiftIds.contains(shift.id);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(shift.id),
                    ),
                    title: Text(
                      '${DateFormat('MM/dd(E)', 'ja_JP').format(shift.date)} ${shift.startTime.format(context)} - ${shift.endTime.format(context)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ステータス: ${_getStatusText(shift.status)}'),
                        if (shift.breakDurationMinutes > 0)
                          Text(
                            '休憩: ${shift.breakStartTime?.format(context)} - ${shift.breakEndTime?.format(context)} (${shift.breakDurationMinutes}分)',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          )
                        else
                          const Text(
                            '休憩なし',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.restaurant,
                            size: 20,
                            color: Colors.orange,
                          ),
                          onPressed:
                              () =>
                                  _showBreakEditDialog(context, service, shift),
                          tooltip: '休憩時間を編集',
                        ),
                        _buildActionButtons(context, service, shift),
                      ],
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showBreakEditDialog(
    BuildContext context,
    ShiftService service,
    Shift shift,
  ) {
    final currentShift =
        shift.breakStartTime != null ? shift : Shift.autoAllocateBreak(shift);

    TimeOfDay? start = currentShift.breakStartTime;
    TimeOfDay? end = currentShift.breakEndTime;
    int duration = currentShift.breakDurationMinutes;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('休憩時間の編集'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('開始時間'),
                        trailing: Text(start?.format(context) ?? '--:--'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: start ?? shift.startTime,
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
                            initialTime: end ?? shift.endTime,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '休憩時間: ${duration > 0 ? "$duration分" : "なし"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: duration > 0 ? Colors.blue : Colors.red,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final recommended = Shift.autoAllocateBreak(shift);
                          setState(() {
                            start = recommended.breakStartTime;
                            end = recommended.breakEndTime;
                            duration = recommended.breakDurationMinutes;
                          });
                        },
                        child: const Text('自動計算に戻す'),
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
                        service.updateShiftBreak(
                          shift.id,
                          duration,
                          start,
                          end,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ShiftService service,
    Shift shift,
  ) {
    if (shift.status == ShiftStatus.confirmed) {
      return IconButton(
        icon: const Icon(Icons.undo, color: Colors.grey),
        onPressed:
            () => service.updateShiftStatus(shift.id, ShiftStatus.adjusting),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shift.status == ShiftStatus.submitted)
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.blue),
            onPressed:
                () =>
                    service.updateShiftStatus(shift.id, ShiftStatus.adjusting),
            tooltip: '調整中にする',
          ),
        if (shift.status != ShiftStatus.canceled)
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed:
                () =>
                    service.updateShiftStatus(shift.id, ShiftStatus.confirmed),
            tooltip: '確定',
          ),
        if (shift.status != ShiftStatus.canceled)
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
                            service.updateShiftStatus(
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
}
