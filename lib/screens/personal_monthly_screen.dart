import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/shift_service.dart';
import '../models/shift.dart';
import '../models/user.dart';

class PersonalMonthlyScreen extends StatefulWidget {
  const PersonalMonthlyScreen({super.key});

  @override
  State<PersonalMonthlyScreen> createState() => _PersonalMonthlyScreenState();
}

class _PersonalMonthlyScreenState extends State<PersonalMonthlyScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(ShiftService service) {
    setState(() => _errorMessage = null);
    final success = service.login(
      _loginIdController.text,
      _passwordController.text,
    );
    if (!success) {
      setState(() => _errorMessage = 'ログインIDまたはパスワードが正しくありません');
    }
  }

  void _moveMonth(int months) {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + months,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftService = Provider.of<ShiftService>(context);
    final user = shiftService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人の月間シフト'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => shiftService.setCurrentUser(null),
              tooltip: 'ログアウト',
            ),
        ],
      ),
      body:
          user == null
              ? _buildLoginForm(context, shiftService)
              : _buildMonthlyTable(context, shiftService, user),
    );
  }

  Widget _buildLoginForm(BuildContext context, ShiftService service) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person, size: 64, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'ログイン',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '個人の月間シフトを確認するには\nログインしてください',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _loginIdController,
                decoration: const InputDecoration(
                  labelText: 'ログインID',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  hintText: '例: user1',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  hintText: '例: 1234',
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _handleLogin(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('ログイン', style: TextStyle(fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTable(
    BuildContext context,
    ShiftService service,
    User user,
  ) {
    final myShifts =
        service
            .getShiftsForUser(user.id)
            .where(
              (s) =>
                  s.date.year == _displayMonth.year &&
                  s.date.month == _displayMonth.month &&
                  s.status != ShiftStatus.canceled,
            )
            .toList();

    // 日付順にソート
    myShifts.sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: [
        _buildMonthNavigator(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Row(
                    children: [
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
                            Text(
                              '${_displayMonth.year}年${_displayMonth.month}月のシフト状況',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (myShifts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(child: Text('この月のシフトはありません')),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.indigo.shade50,
                        ),
                        columns: const [
                          DataColumn(label: Text('日付')),
                          DataColumn(label: Text('時間')),
                          DataColumn(label: Text('休憩')),
                          DataColumn(label: Text('実働')),
                          DataColumn(label: Text('状況')),
                        ],
                        rows:
                            myShifts.map((shift) {
                              final s = Shift.autoAllocateBreak(shift);
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      DateFormat(
                                        'MM/dd(E)',
                                        'ja_JP',
                                      ).format(s.date),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${s.startTime.format(context)}-${s.endTime.format(context)}',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      s.breakDurationMinutes > 0
                                          ? '${s.breakDurationMinutes}分'
                                          : '-',
                                    ),
                                  ),
                                  DataCell(
                                    Text('${s.workHours.toStringAsFixed(1)}h'),
                                  ),
                                  DataCell(_buildStatusBadge(s.status)),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.indigo.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => _moveMonth(-1),
            tooltip: '前月',
          ),
          Text(
            DateFormat('yyyy年 MM月').format(_displayMonth),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => _moveMonth(1),
            tooltip: '次月',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ShiftStatus status) {
    String text = '';
    Color color = Colors.grey;
    switch (status) {
      case ShiftStatus.submitted:
        text = '提出中';
        color = Colors.orange;
        break;
      case ShiftStatus.adjusting:
        text = '調整中';
        color = Colors.blue;
        break;
      case ShiftStatus.confirmed:
        text = '確定';
        color = Colors.green;
        break;
      case ShiftStatus.canceled:
        text = '取り消し';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
