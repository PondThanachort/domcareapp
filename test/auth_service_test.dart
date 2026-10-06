import 'dart:convert';
import 'package:domcareapp/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'Login sends username/password and trusts API role; logout clears JWT',
    () async {
      final service = AuthService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/login');
          expect(jsonDecode(request.body), {
            'username': 'someone',
            'password': 'secret',
          });
          return http.Response(
            jsonEncode({
              'token': 'signed-token',
              'user': {
                'id': 42,
                'username': 'someone',
                'display_name': 'Admin',
                'room': null,
                'role': 'admin',
              },
            }),
            200,
          );
        }),
      );
      final session = AuthSession(service);
      expect((await session.login(' someone ', 'secret')).role, 'admin');
      expect(session.token, 'signed-token');
      session.logout();
      expect(session.token, isNull);
      expect(session.user, isNull);
      session.dispose();
      service.dispose();
    },
  );
  for (final code in [401, 500]) {
    test('HTTP $code fails without creating session', () async {
      final service = AuthService(
        client: MockClient((_) async => http.Response('{}', code)),
      );
      final session = AuthSession(service);
      await expectLater(
        session.login('admin', 'wrong'),
        throwsA(isA<AuthException>()),
      );
      expect(session.token, isNull);
      session.dispose();
      service.dispose();
    });
  }
  test('Network failure is reported clearly', () async {
    final service = AuthService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      service.login('admin', 'secret'),
      throwsA(isA<AuthException>()),
    );
    service.dispose();
  });
}
