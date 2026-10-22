import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../services/app_services.dart';
import '../../data/visit_store.dart';
import '../../models/experience.dart';
import '../../navigation/main_navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _ready = Future<void>.delayed(
    const Duration(milliseconds: 250),
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
              if (user.role == UserRole.visitor) {
                return MainNavigation(key: ValueKey(user.email));
              }
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Vai trò này sử dụng cổng nghiệp vụ web.'),
                      TextButton(
                        onPressed: AppServices.auth.logout,
                        child: const Text('Quay lại đăng nhập'),
                      ),
                    ],
                  ),
                ),
              );
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
  String _mode = Uri.base.queryParameters['mode'] == 'register'
      ? 'register'
      : 'login';
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
        if (_mode == 'register') {
          await AppServices.auth.register(
            _name.text.trim(),
            _email.text.trim(),
            _password.text,
          );
        } else {
          await AppServices.auth.login(_email.text.trim(), _password.text);
        }
        VisitStore.instance.reset();
      }
    } catch (e) {
      if (mounted) {
        final msg = e is FormatException
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        setState(() => _error = msg);
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
          ? 'Nhập email để gửi yêu cầu đặt lại mật khẩu.'
          : 'Bắt đầu chuyến đi bằng một điều tò mò.',
      children: [
        if (_mode == 'login') ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
          'Đăng nhập để đồng bộ thông tin và bản đồ di sản từ máy chủ SMGS.',
        ),
        const SizedBox(height: 20),
        if (_recovered) ...[
          const Panel(
            child: Notice(
              'Yêu cầu khôi phục đã được gửi. Bạn vui lòng kiểm tra hòm thư và quay lại đăng nhập.',
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
                    maxLength: 200,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Tên của bạn'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập tên.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@domain.com',
                  ),
                  validator: (v) =>
                      v == null ||
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(v.trim())
                      ? 'Nhập địa chỉ email hợp lệ.'
                      : null,
                ),
                if (_mode != 'recover') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    autofillHints: [
                      _mode == 'register'
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    obscureText: _hidden,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      helperText: _mode == 'register'
                          ? 'Ít nhất 6 ký tự, có chữ thường và số.'
                          : null,
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
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Vui lòng nhập mật khẩu.';
                      }
                      if (_mode == 'register' &&
                          (v.length < 6 ||
                              !RegExp('[a-z]').hasMatch(v) ||
                              !RegExp('[0-9]').hasMatch(v))) {
                        return 'Mật khẩu cần ít nhất 6 ký tự, có chữ thường và số.';
                      }
                      return null;
                    },
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
                      ? 'Đăng ký tài khoản'
                      : _mode == 'recover'
                      ? 'Gửi yêu cầu khôi phục'
                      : 'Đăng nhập',
                  onPressed: _busy ? null : _submit,
                ),
                if (_mode == 'login') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Nhân viên bảo tàng, nhân viên hệ thống và quản trị viên dùng cổng web.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
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
