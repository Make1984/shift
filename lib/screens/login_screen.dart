import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/shift_service.dart';
import '../models/user.dart';
import 'weekly_shift_screen.dart';
import 'personal_monthly_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole? _activeLoginRole;
  bool _obscurePassword = true;

  bool get _isLoginVisible => _activeLoginRole != null;

  void _switchRole(UserRole? role) {
    setState(() {
      _activeLoginRole = role;
      _idController.clear();
      _passwordController.clear();
      _obscurePassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftService = Provider.of<ShiftService>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar:
          _isLoginVisible
              ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _switchRole(null),
                  ),
                ],
              )
              : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade800, Colors.indigo.shade400],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(32),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 64,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'シフト管理アプリ',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoginVisible
                          ? '${_getRoleName(_activeLoginRole!)}ログイン'
                          : 'ご利用のモードを選択してください',
                    ),
                    const SizedBox(height: 24),
                    if (!_isLoginVisible) ...[
                      _buildRoleButton(
                        context,
                        'バイト（シフト提出）',
                        UserRole.staff,
                        onTap: () => _switchRole(UserRole.staff),
                      ),
                      _buildRoleButton(
                        context,
                        'リーダー（シフト調整）',
                        UserRole.leader,
                        onTap: () => _switchRole(UserRole.leader),
                      ),
                      _buildRoleButton(
                        context,
                        '店長（状況確認）',
                        UserRole.manager,
                        onTap: () => _switchRole(UserRole.manager),
                      ),
                      const Divider(height: 32),
                      _buildWeeklyShiftButton(context),
                      const SizedBox(height: 8),
                      _buildPersonalMonthlyButton(context),
                    ] else ...[
                      _buildLoginForm(context, shiftService, _activeLoginRole!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return 'バイト';
      case UserRole.leader:
        return 'リーダー';
      case UserRole.manager:
        return '店長';
    }
  }

  Widget _buildRoleButton(
    BuildContext context,
    String title,
    UserRole role, {
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role),
          child: Icon(_getRoleIcon(role), color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildWeeklyShiftButton(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.view_week, color: Colors.white, size: 20),
        ),
        title: const Text(
          '週間シフト表（全員の予定）',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        subtitle: const Text('ログインなしで今週の予定を確認できます'),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.indigo,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WeeklyShiftScreen()),
          );
        },
      ),
    );
  }

  Widget _buildPersonalMonthlyButton(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.calendar_month, color: Colors.white, size: 20),
        ),
        title: const Text(
          '個人の月間シフト',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        subtitle: const Text('自分の1ヶ月の予定を一覧で確認できます'),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.indigo,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalMonthlyScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    ShiftService service,
    UserRole role,
  ) {
    String demoId = '';
    String demoPw = '1234';

    if (role == UserRole.leader) {
      demoId = 'leader1';
    } else if (role == UserRole.manager) {
      demoId = 'manager1';
    } else {
      demoId = 'user1';
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Column(
            children: [
              const Text(
                '【デモ用：以下のID/PASSでログイン可能です】',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: $demoId / PASS: $demoPw',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '※空欄のままログインボタンを押すと自動入力されます',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _idController,
          decoration: InputDecoration(
            labelText: 'ログインID',
            hintText: '例: $demoId',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'パスワード',
            hintText: '例: $demoPw',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              String inputId = _idController.text.trim();
              String inputPw = _passwordController.text.trim();

              // 空欄の場合はデモ用を使用
              if (inputId.isEmpty) inputId = demoId;
              if (inputPw.isEmpty) inputPw = demoPw;

              final success = service.login(inputId, inputPw);
              if (success) {
                if (service.currentUser!.role != role) {
                  final currentRoleName = _getRoleName(
                    service.currentUser!.role,
                  );
                  final targetRoleName = _getRoleName(role);
                  service.setCurrentUser(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'このアカウントは$currentRoleName用です。$targetRoleNameモードではログインできません。',
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('IDまたはパスワードが正しくありません。大文字小文字にもご注意ください。'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ログイン'),
          ),
        ),
        if (role == UserRole.staff) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: const Text('アカウントをお持ちでない方はこちら（新規登録）'),
          ),
        ],
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return Colors.green;
      case UserRole.leader:
        return Colors.blue;
      case UserRole.manager:
        return Colors.orange;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return Icons.person;
      case UserRole.leader:
        return Icons.star;
      case UserRole.manager:
        return Icons.business;
    }
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<ShiftService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('新規アカウント登録')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'お名前',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: '連絡先（電話番号など「デモなので存在しない番号でOK」）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: '希望ログインID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isEmpty ||
                        _idController.text.isEmpty ||
                        _passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('必須項目を入力してください')),
                      );
                      return;
                    }
                    service.register(
                      _nameController.text,
                      _contactController.text,
                      _idController.text,
                      _passwordController.text,
                    );
                    Navigator.pop(context); // 登録後はログイン画面に戻る（または自動ログイン）
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('登録してログイン'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
