import 'package:domcareapp/services/auth_service.dart';

// Only injected by widget tests; production always calls the HTTP API.
class TestAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> authorizedRequest(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async => path.startsWith('/api/requests')
      ? {'requests': <dynamic>[], 'counts': <String, dynamic>{}}
      : {'users': <dynamic>[]};

  @override
  Future<AuthResult> login(String username, String password) async =>
      AuthResult(
        'test-token',
        AuthUser(
          id: 1,
          username: username,
          displayName: username == 'admin' ? 'ผู้ดูแลระบบ' : 'สมชาย ใจดี',
          role: username == 'admin' ? 'admin' : 'resident',
          room: username == 'admin' ? null : '305',
        ),
      );
}
