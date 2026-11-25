import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../services/app_services.dart';
import '../../services/app_preferences.dart';
import '../../data/visit_store.dart';
import '../../models/experience.dart';
import '../../widgets/catalog_gate.dart';

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
    builder: (context, snapshot) {
      final isEn = AppPreferences.instance.language == 'en';
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HeritageSeal(size: 88),
                  const SizedBox(height: 24),
                  Text(
                    isEn ? 'Vietnam Museum Guide' : 'Cẩm nang bảo tàng',
                    style: AppTextStyles.pageTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEn
                        ? 'Opening the gates of heritage…'
                        : 'Đang mở cánh cửa di sản…',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        );
      }
      return ListenableBuilder(
        listenable: AppServices.auth,
        builder: (context, _) {
          final user = AppServices.auth.user;
          if (user == null) return const AuthScreen();
          if (user.role == UserRole.visitor) {
            return CatalogGate(key: ValueKey(user.email));
          }
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEn
                        ? 'This role must use the web operations portal.'
                        : 'Vai trò này sử dụng cổng nghiệp vụ web.',
                  ),
                  TextButton(
                    onPressed: AppServices.auth.logout,
                    child: Text(
                      isEn ? 'Back to sign in' : 'Quay lại đăng nhập',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
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

  Widget _buildLanguageToggle() {
    final prefs = AppPreferences.instance;
    final isVi = prefs.language == 'vi';
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangButton('VI', isVi, () => prefs.setLanguage('vi')),
          _buildLangButton('EN', !isVi, () => prefs.setLanguage('en')),
        ],
      ),
    );
  }

  Widget _buildLangButton(String text, bool active, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.deepBurgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTextStyles.sansFamily,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? AppColors.antiqueIvory : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppPreferences.instance,
    builder: (context, _) {
      final isEn = AppPreferences.instance.language == 'en';
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 528,
            child: MuseumPage(
              eyebrow: isEn
                  ? 'SMGS · Vietnam Museum Guide'
                  : 'SMGS · Cẩm nang bảo tàng Việt',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageToggle(),
                  const SizedBox(width: 8),
                  const HeritageSeal(size: 34),
                ],
              ),
              title: _mode == 'register'
                  ? (isEn ? 'Create Account' : 'Tạo tài khoản')
                  : _mode == 'recover'
                  ? (isEn ? 'Reset Password' : 'Khôi phục mật khẩu')
                  : (isEn ? 'Sign In' : 'Đăng nhập'),
              subtitle: _mode == 'register'
                  ? (isEn
                      ? 'Save favorite artifacts and tour journeys'
                      : 'Lưu hiện vật yêu thích và hành trình tham quan')
                  : _mode == 'recover'
                  ? (isEn
                      ? 'Enter your email to reset password'
                      : 'Nhập email để đặt lại mật khẩu')
                  : (isEn
                      ? 'Discover museums and stories behind each artifact'
                      : 'Khám phá bảo tàng và những câu chuyện sau mỗi hiện vật'),
              children: [
                if (_mode == 'login') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VisitorRadius.xl),
                    child: const MuseumPhoto(
                      museumId: 'museum_national',
                      imageUrl: 'assets/images/national-museum-web.jpg',
                      height: 160,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
                if (_recovered) ...[
                  Panel(
                    child: Notice(
                      isEn
                          ? 'Password reset instructions have been sent to your email. Please check your inbox and return to sign in.'
                          : 'Yêu cầu khôi phục đã được gửi. Bạn vui lòng kiểm tra hòm thư và quay lại đăng nhập.',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: isEn ? 'Back to sign in' : 'Về đăng nhập',
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
                            decoration: InputDecoration(
                              labelText: isEn ? 'Your Name' : 'Tên của bạn',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? (isEn
                                    ? 'Please enter your name.'
                                    : 'Vui lòng nhập tên.')
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
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'user@domain.com',
                          ),
                          validator: (v) =>
                              v == null ||
                                  !RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(v.trim())
                              ? (isEn
                                  ? 'Enter a valid email address.'
                                  : 'Nhập địa chỉ email hợp lệ.')
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
                              labelText: isEn ? 'Password' : 'Mật khẩu',
                              helperText: _mode == 'register'
                                  ? (isEn
                                      ? 'At least 6 characters, with letters and numbers.'
                                      : 'Ít nhất 6 ký tự, có chữ thường và số.')
                                  : null,
                              suffixIcon: IconButton(
                                tooltip: _hidden
                                    ? (isEn ? 'Show password' : 'Hiện mật khẩu')
                                    : (isEn ? 'Hide password' : 'Ẩn mật khẩu'),
                                onPressed: () =>
                                    setState(() => _hidden = !_hidden),
                                icon: Icon(
                                  _hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return isEn
                                    ? 'Please enter your password.'
                                    : 'Vui lòng nhập mật khẩu.';
                              }
                              if (_mode == 'register' &&
                                  (v.length < 6 ||
                                      !RegExp('[a-z]').hasMatch(v) ||
                                      !RegExp('[0-9]').hasMatch(v))) {
                                return isEn
                                    ? 'Password must be at least 6 characters, with letters and numbers.'
                                    : 'Mật khẩu cần ít nhất 6 ký tự, có chữ thường và số.';
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
                            decoration: InputDecoration(
                              labelText: isEn
                                  ? 'Confirm password'
                                  : 'Nhập lại mật khẩu',
                            ),
                            validator: (v) => v != _password.text
                                ? (isEn
                                    ? 'Passwords do not match.'
                                    : 'Hai mật khẩu chưa khớp.')
                                : null,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Semantics(liveRegion: true, child: Notice(_error!)),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: _busy
                              ? (isEn ? 'Processing…' : 'Đang xử lý…')
                              : _mode == 'register'
                              ? (isEn ? 'Create Account' : 'Đăng ký tài khoản')
                              : _mode == 'recover'
                              ? (isEn
                                  ? 'Send Reset Link'
                                  : 'Gửi yêu cầu khôi phục')
                              : (isEn ? 'Sign In' : 'Đăng nhập'),
                          onPressed: _busy ? null : _submit,
                        ),
                        if (_mode == 'login') ...[
                          const SizedBox(height: 12),
                          Text(
                            isEn
                                ? 'For museum visitors'
                                : 'Dành cho khách tham quan bảo tàng',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _busy ? null : () => _switch('recover'),
                            child: Text(
                              isEn ? 'Forgot password?' : 'Quên mật khẩu?',
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : () => _switch('register'),
                            child: Text(
                              isEn
                                  ? 'Create new account'
                                  : 'Tạo tài khoản mới',
                            ),
                          ),
                        ] else
                          TextButton(
                            onPressed: _busy ? null : () => _switch('login'),
                            child: Text(
                              isEn ? 'Back to sign in' : 'Về đăng nhập',
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
