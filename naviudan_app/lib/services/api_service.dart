import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;

class ApiService {
  /// Android emulator → host loopback. Web / desktop / iOS simulator → localhost.
  /// For a physical phone, use your PC's LAN IP (e.g. http://192.168.1.x:8000).
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 'http://localhost:8000';
      default:
        return 'http://localhost:8000';
    }
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── User Profile ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createProfile(
      Map<String, dynamic> profileData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
      body: jsonEncode(profileData),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getProfile(String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/profile/$uid'),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateProfile(
      String uid, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/profile/$uid'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  // ─── Jobs ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMatchedJobs(String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/jobs/match/$uid'),
      headers: _headers,
    );
    return _handle(res);
  }

  /// Jobs posted by recruiter (dashboard).
  static Future<Map<String, dynamic>> getRecruiterPostedJobs(
      String recruiterUid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/jobs/mine/$recruiterUid'),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getAllJobs({
    String? state, String? district,
  }) async {
    var url = '$baseUrl/jobs/list';
    final params = <String>[];
    if (state != null) params.add('state=$state');
    if (district != null) params.add('district=$district');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _handle(res);
  }

  static Future<Map<String, dynamic>> postJob(
      Map<String, dynamic> jobData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/jobs/post'),
      headers: _headers,
      body: jsonEncode(jobData),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> applyForJob(
      String jobId, String applicantUid,
      {String? applicationText, List<String>? attachments}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/jobs/apply'),
      headers: _headers,
      body: jsonEncode({
        'job_id': jobId,
        'applicant_uid': applicantUid,
        'application_text': applicationText,
        'attachments': attachments ?? const [],
      }),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> generateAiApplicationDraft(
      String jobId, String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/jobs/ai-application/$jobId/$uid'),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> saveJob(
      String uid, String jobId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/jobs/save/$uid/$jobId'),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getSavedJobs(String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/jobs/saved/$uid'),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getMyApplications(String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/jobs/my-applications/$uid'),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getRecruiterApplications(
      String recruiterUid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/jobs/applications/$recruiterUid'),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(
      String appId, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/jobs/applications/$appId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return _handle(res);
  }

  // ─── Courses ──────────────────────────────────────────────────────────────

  /// Job finder only: backend requires `client=job_finder` for AI free-course picks.
  static Future<Map<String, dynamic>> getRecommendedCourses(String uid) async {
    final headers = Map<String, String>.from(_headers);
    headers['X-NaviUdan-Client'] = 'job_finder';
    final res = await http.get(
      Uri.parse('$baseUrl/courses/recommend/$uid?client=job_finder'),
      headers: headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getAllCourses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/courses/all'),
      headers: _headers,
    );
    return _handle(res);
  }

  // ─── AI ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> analyzeCareer(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/analyze'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> chatWithBot(
      String uid, String message, String language) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: _headers,
      body: jsonEncode({'uid': uid, 'message': message, 'language': language}),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getWeeklyPlan(
    String uid, {
    String? courseId,
    String? courseTitle,
    String? courseUrl,
  }) async {
    final params = <String>[];
    if (courseId != null && courseId.isNotEmpty) {
      params.add('course_id=${Uri.encodeQueryComponent(courseId)}');
    }
    if (courseTitle != null && courseTitle.isNotEmpty) {
      params.add('course_title=${Uri.encodeQueryComponent(courseTitle)}');
    }
    if (courseUrl != null && courseUrl.isNotEmpty) {
      params.add('course_url=${Uri.encodeQueryComponent(courseUrl)}');
    }
    var url = '$baseUrl/ai/weekly-plan/$uid';
    if (params.isNotEmpty) {
      url = '$url?${params.join('&')}';
    }
    final res = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getTrendingFields(String state) async {
    final res = await http.get(
      Uri.parse('$baseUrl/ai/trending/$state'),
      headers: _headers,
    );
    return _handle(res);
  }

  // ─── Response handler ─────────────────────────────────────────────────────

  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    throw ApiException(
      message: body['detail']?.toString() ?? 'Unknown error',
      statusCode: res.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
