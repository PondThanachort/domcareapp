import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'admin/admin_shell.dart';
import 'app_shell.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;

  Future<void> _login() async {
    if (_loading) return;
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final user = await AuthScope.of(
        context,
      ).login(_username.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => user.role == 'admin'
              ? AdminShell(onToggleTheme: widget.onToggleTheme)
              : AppShell(onToggleTheme: widget.onToggleTheme),
        ),
      );
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF151517) : Colors.white;
    final secondary = dark ? const Color(0xFF9B9BA1) : const Color(0xFF77777D);

    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.36).clamp(
      240.0,
      340.0,
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Stack(
              children: [
                SizedBox(
                  height: heroHeight + topInset + 32,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/login_dormitory.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.3, 0),
                    excludeFromSemantics: true,
                    color: dark ? Colors.black.withValues(alpha: 0.3) : null,
                    colorBlendMode: dark ? BlendMode.darken : null,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: heroHeight + topInset,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24 + topInset, 24, 24),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: dark ? Colors.white : Colors.black,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  CupertinoIcons.hammer_fill,
                                  color: dark ? Colors.black : Colors.white,
                                  size: 24,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: widget.onToggleTheme,
                                style: IconButton.styleFrom(
                                  backgroundColor: surface,
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: Icon(
                                  dark
                                      ? CupertinoIcons.sun_max_fill
                                      : CupertinoIcons.moon_fill,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        minHeight:
                            (constraints.maxHeight - heroHeight - topInset)
                                .clamp(0.0, double.infinity),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        30,
                        24,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ยินดีต้อนรับกลับ',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'เข้าสู่ระบบเพื่อแจ้งและติดตามสถานะการซ่อมบำรุง',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 34),
                          _LoginField(
                            controller: _username,
                            hint: 'ชื่อผู้ใช้',
                            icon: CupertinoIcons.person,
                          ),
                          const SizedBox(height: 14),
                          _LoginField(
                            controller: _password,
                            hint: 'รหัสผ่าน',
                            icon: CupertinoIcons.lock,
                            obscureText: _hidePassword,
                            trailing: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                size: 21,
                                color: secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _loading ? null : _login,
                              style: FilledButton.styleFrom(
                                backgroundColor: dark
                                    ? Colors.white
                                    : Colors.black,
                                foregroundColor: dark
                                    ? Colors.black
                                    : Colors.white,
                                disabledBackgroundColor: dark
                                    ? Colors.white54
                                    : Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _loading
                                    ? SizedBox(
                                        key: const ValueKey('loading'),
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: dark
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'เข้าสู่ระบบ',
                                        key: ValueKey('text'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              'DormCare • Resident',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.trailing,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Widget? trailing;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: hint == 'รหัสผ่าน'
          ? TextInputAction.done
          : TextInputAction.next,
      onSubmitted: (_) {
        if (hint == 'รหัสผ่าน') {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: dark ? const Color(0xFF77777D) : const Color(0xFF9A9AA0),
        ),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: trailing,
        filled: true,
        fillColor: dark ? const Color(0xFF151517) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF27272A) : const Color(0xFFE9E9EC),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF27272A) : const Color(0xFFE9E9EC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: dark ? Colors.white : Colors.black,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
