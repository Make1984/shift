import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/shift_service.dart';
import '../models/shift.dart';
import 'weekly_shift_screen.dart';
import '../models/user.dart';

import 'monthly_shift_submission_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
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

  void _toggleAllSelection(List<Shift> shifts) {
    final allSelected = shifts.every((s) => _selectedShiftIds.contains(s.id));
    setState(() {
      if (allSelected) {
        _selectedShiftIds.clear();
      } else {
        for (var s in shifts) {
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
    final user = shiftService.currentUser!;
    final myShifts =
        shiftService
            .getShiftsForUser(user.id)
            .where((s) => s.status != ShiftStatus.canceled)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('希望シフト提出'),
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
            icon: const Icon(Icons.logout),
            onPressed: () => shiftService.setCurrentUser(null),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(user, myShifts),
          Expanded(
            child:
                myShifts.isEmpty
                    ? const Center(child: Text('提出済みのシフトはありません'))
                    : ListView.builder(
                      itemCount: myShifts.length,
                      itemBuilder: (context, index) {
                        final shift = myShifts[index];
                        return _buildShiftCard(context, shift, shiftService);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          _selectedShiftIds.isEmpty
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const MonthlyShiftSubmissionScreen(),
                    ),
                  );
                },
                label: const Text('1ヶ月分まとめて提出'),
                icon: const Icon(Icons.calendar_month),
              )
              : null,
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
          children: [
            Expanded(
              child: ElevatedButton.icon(
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
                icon: const Icon(Icons.delete),
                label: const Text('選択したシフトを取り消す'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User user, List<Shift> shifts) {
    final allSelected =
        shifts.isNotEmpty &&
        shifts.every((s) => _selectedShiftIds.contains(s.id));

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.indigo.shade50,
      child: Row(
        children: [
          if (shifts.isNotEmpty)
            Checkbox(
              value: allSelected,
              onChanged: (_) => _toggleAllSelection(shifts),
            ),
          const SizedBox(width: 8),
          CircleAvatar(child: Text(user.name[0])),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text('バイトスタッフ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(
    BuildContext context,
    Shift shift,
    ShiftService shiftService,
  ) {
    final isSelected = _selectedShiftIds.contains(shift.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(shift.id),
            ),
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(shift.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  DateFormat('MM/dd').format(shift.date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(shift.status),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          '${shift.startTime.format(context)} - ${shift.endTime.format(context)}',
        ),
        subtitle: Text('ステータス: ${_getStatusText(shift.status)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shift.status == ShiftStatus.submitted)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed:
                    () => _showDeleteConfirmation(context, shiftService, shift),
              ),
            Icon(Icons.circle, color: _getStatusColor(shift.status), size: 12),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ShiftService service,
    Shift shift,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('シフトの取り消し'),
            content: Text(
              '${DateFormat('MM/dd').format(shift.date)} のシフトを取り消しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  service.updateShiftStatus(shift.id, ShiftStatus.canceled);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('シフトを取り消しました')));
                },
                child: const Text('取り消す', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
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
