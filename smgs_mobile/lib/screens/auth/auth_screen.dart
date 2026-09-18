import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../services/app_services.dart';
import '../../data/visit_store.dart';
import '../../models/experience.dart';
import '../../navigation/main_navigation.dart';
import '../management/management_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _ready = Future<void>.delayed(
    const Duration(milliseconds: 350),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) =>
        snapshot.connectionState != ConnectionState.done
        ? Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HeritageSeal(size: 88),
                    const SizedBox(height: 24),
                    Text(
                      'Cẩm nang bảo tàng',
                      style: AppTextStyles.pageTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đang mở cánh cửa di sản…',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          )
        : ListenableBuilder(
            listenable: AppServices.auth,
            builder: (context, _) {
              final user = AppServices.auth.user;
              if (user == null) return const AuthScreen();
              return switch (user.role) {
                UserRole.curator => const ManagementHomeScreen(
                  role: UserRole.curator,
                ),
                UserRole.administrator => const ManagementHomeScreen(
                  role: UserRole.administrator,
                ),
                UserRole.visitor => MainNavigation(
                  key: ValueKey(user.isGuest ? 'guest' : user.email),
                ),
              };
            },
          ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController(),
      _confirm = TextEditingController();
  String _mode = 'login';
  String? _error;
  bool _busy = false, _hidden = true, _recovered = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _switch(String mode) => setState(() {
    _mode = mode;
    _error = null;
    _recovered = false;
    _form.currentState?.reset();
  });
  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_mode == 'recover') {
        await AppServices.auth.recover(_email.text.trim());
        if (mounted) setState(() => _recovered = true);
      } else {
        VisitStore.instance.reset();
        if (_mode == 'register') {
          await AppServices.auth.register(
            _name.text.trim(),
            _email.text.trim(),
            _password.text,
          );
        } else {
          await AppServices.auth.login(_email.text.trim(), _password.text);
        }
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa thể thực hiện. Bạn vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: MuseumPage(
      eyebrow: 'SMGS · Cẩm nang bảo tàng Việt',
      title: _mode == 'register'
          ? 'Một sổ tay\ncủa riêng bạn.'
          : _mode == 'recover'
          ? 'Tìm lại lối vào.'
          : 'Hẹn bạn\nở miền ký ức.',
      subtitle: _mode == 'register'
          ? 'Lưu những câu chuyện bạn muốn giữ lại.'
          : _mode == 'recover'
          ? 'Nhập email của tài khoản trải nghiệm.'
          : 'Bắt đầu chuyến đi bằng một điều tò mò.',
      children: [
        if (_mode == 'login') ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const MuseumPhoto(museumId: 'museum_national', height: 170),
          ),
          const SizedBox(height: 22),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
            ),
        ],
        const Notice(
          'Bản trải nghiệm trên web. Hãy dùng thông tin mẫu; tài khoản chỉ tồn tại trong phiên này.',
        ),
        const SizedBox(height: 20),
        if (_recovered) ...[
          const Panel(
            child: Notice(
              'Đã hoàn tất bước khôi phục mô phỏng. Không có thư nào được gửi. Bạn có thể quay lại và dùng tài khoản mẫu.',
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Về đăng nhập',
            onPressed: () => _switch('login'),
          ),
        ] else
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_mode == 'register') ...[
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Tên của bạn'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập tên.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'khach@smgs.vn',
                  ),
                  validator: (v) =>
                      v == null ||
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v.trim())
                      ? 'Nhập địa chỉ email hợp lệ.'
                      : null,
                ),
                if (_mode != 'recover') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _hidden,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                        onPressed: () => setState(() => _hidden = !_hidden),
                        icon: Icon(
                          _hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Vui lòng nhập mật khẩu.'
                        : null,
                  ),
                ],
                if (_mode == 'register') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _hidden,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Hai mật khẩu chưa khớp.' : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Semantics(liveRegion: true, child: Notice(_error!)),
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _busy
                      ? 'Đang xử lý…'
                      : _mode == 'register'
                      ? 'Tạo tài khoản trải nghiệm'
                      : _mode == 'recover'
                      ? 'Khôi phục mô phỏng'
                      : 'Đăng nhập',
                  onPressed: _busy ? null : _submit,
                ),
                if (_mode == 'login') ...[
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Tiếp tục với vai trò khách',
                    icon: Icons.person_outline,
                    onPressed: _busy
                        ? null
                        : () {
                            VisitStore.instance.reset();
                            AppServices.auth.guest();
                          },
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            _email.text = 'khach@smgs.vn';
                            _password.text = 'smgs123';
                          },
                    child: const Text('Điền tài khoản mẫu'),
                  ),
                  const SizedBox(height: 8),
                  _RoleAccountPanel(
                    onSelected: (email) {
                      _email.text = email;
                      _password.text = 'smgs123';
                    },
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy ? null : () => _switch('recover'),
                    child: const Text('Quên mật khẩu?'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _switch('register'),
                    child: const Text('Tạo tài khoản mới'),
                  ),
                ] else
                  TextButton(
                    onPressed: _busy ? null : () => _switch('login'),
                    child: const Text('Về đăng nhập'),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RoleAccountPanel extends StatelessWidget {
  const _RoleAccountPanel({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Xem thử giao diện theo vai trò'),
        const SizedBox(height: 8),
        Text('Mật khẩu chung: smgs123', style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        _RoleAccount(
          icon: Icons.badge_outlined,
          label: 'Nhân viên / Kiểm duyệt viên',
          email: 'curator@smgs.vn',
          onTap: onSelected,
        ),
        _RoleAccount(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Quản trị viên',
          email: 'admin@smgs.vn',
          onTap: onSelected,
        ),
      ],
    ),
  );
}

class _RoleAccount extends StatelessWidget {
  const _RoleAccount({
    required this.icon,
    required this.label,
    required this.email,
    required this.onTap,
  });

  final IconData icon;
  final String label, email;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      alignment: Alignment.centerLeft,
    ),
    onPressed: () => onTap(email),
    child: Row(
      children: [
        Icon(icon, color: AppColors.deepBurgundy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              Text(email, style: AppTextStyles.caption),
            ],
          ),
        ),
        const Icon(Icons.login, size: 20),
      ],
    ),
  );
}
