import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.room,
    this.isDeleted = false,
  });
  final int id;
  final String username, displayName, role;
  final String? room;
  final bool isDeleted;
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    if (!['admin', 'resident'].contains(json['role'])) {
      throw const AuthException('บัญชีนี้ไม่มีสิทธิ์เข้าใช้งาน');
    }
    return AuthUser(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
      room: json['room'] as String?,
      isDeleted: json['deleted_at'] != null,
    );
  }
}

class AuthResult {
  const AuthResult(this.token, this.user);
  final String token;
  final AuthUser user;
}

class AuthService {
  AuthService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? defaultBaseUrl;
  final http.Client _client;
  final String baseUrl;
  static String get defaultBaseUrl =>
      const String.fromEnvironment('API_BASE_URL').isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:3000'
            : 'http://127.0.0.1:3000');

  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 401) {
        throw const AuthException('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
      }
      if (response.statusCode != 200) {
        throw const AuthException('ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      if (token.isEmpty) throw const FormatException();
      return AuthResult(
        token,
        AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException('เชื่อมต่อหมดเวลา กรุณาลองใหม่');
    } on http.ClientException {
      throw const AuthException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจว่า Backend เปิดอยู่',
      );
    } catch (_) {
      throw const AuthException('ข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }
  }

  Future<Map<String, dynamic>> authorizedRequest(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (body != null) request.body = jsonEncode(body);
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(const Duration(seconds: 12));
      if (response.statusCode == 401) {
        throw const AuthException(
          'การเข้าสู่ระบบหมดอายุ กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          data['message'] as String? ?? 'ไม่สามารถดำเนินการได้',
        );
      }
      return data;
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException('เชื่อมต่อหมดเวลา กรุณาลองใหม่');
    } on http.ClientException {
      throw const AuthException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาลองใหม่');
    } catch (_) {
      throw const AuthException('ไม่สามารถอ่านข้อมูลจากเซิร์ฟเวอร์ได้');
    }
  }

  void dispose() => _client.close();
}

/// Session is kept in memory only; restarting the app requires login again.
class AuthSession extends ChangeNotifier {
  AuthSession(this.service);
  final AuthService service;
  AuthResult? _result;
  AuthUser? get user => _result?.user;
  String? get token => _result?.token;
  int requestsRevision = 0;
  void requestsChanged() {
    requestsRevision++;
    notifyListeners();
  }

  Future<AuthUser> login(String username, String password) async {
    _result = null;
    final result = await service.login(username, password);
    _result = result;
    notifyListeners();
    return result.user;
  }

  void logout() {
    _result = null;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthSession> {
  const AuthScope({
    super.key,
    required AuthSession session,
    required super.child,
  }) : super(notifier: session);
  static AuthSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
  static AuthUser? userOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier?.user;
}
