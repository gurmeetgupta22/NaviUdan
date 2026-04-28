import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';

class JobProvider extends ChangeNotifier {
  List<JobModel>      _matchedJobs     = [];
  List<JobModel>      _savedJobs       = [];
  List<JobApplication> _myApplications = [];
  List<JobModel>      _recruiterJobs   = [];
  List<JobApplication> _recruiterApplications = [];
  List<CourseModel>   _courses         = [];
  List<WeeklyPlanDay> _weeklyPlan      = [];
  AIAnalysisResult?   _aiAnalysis;
  String? _coursesMessage;
  String? _weeklyPlanMessage;
  String? _weeklyPlanCourseTitle;
  String? _weeklyPlanCourseId;

  bool    _isLoading = false;
  String? _error;

  List<JobModel>       get matchedJobs    => _matchedJobs;
  List<JobModel>       get savedJobs      => _savedJobs;
  List<JobApplication> get myApplications => _myApplications;
  List<JobApplication> get recruiterApplications => _recruiterApplications;
  List<JobModel> get recruiterJobs => _recruiterJobs;
  List<CourseModel>    get courses        => _courses;
  List<WeeklyPlanDay>  get weeklyPlan     => _weeklyPlan;
  AIAnalysisResult?    get aiAnalysis     => _aiAnalysis;
  String?              get coursesMessage => _coursesMessage;
  String?              get weeklyPlanMessage => _weeklyPlanMessage;
  String? get weeklyPlanCourseTitle => _weeklyPlanCourseTitle;
  String? get weeklyPlanCourseId => _weeklyPlanCourseId;
  bool                 get isLoading      => _isLoading;
  String?              get error          => _error;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  Future<void> loadMatchedJobs(String uid) async {
    _setLoading(true);
    try {
      final data = await ApiService.getMatchedJobs(uid);
      _matchedJobs = (data['matched_jobs'] as List<dynamic>? ?? [])
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) { _error = e.toString(); }
    finally { _setLoading(false); }
  }

  Future<void> loadSavedJobs(String uid) async {
    _setLoading(true);
    try {
      final data = await ApiService.getSavedJobs(uid);
      _savedJobs = (data['saved_jobs'] as List<dynamic>? ?? [])
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) { _error = e.toString(); }
    finally { _setLoading(false); }
  }

  Future<void> loadMyApplications(String uid) async {
    _setLoading(true);
    try {
      final data = await ApiService.getMyApplications(uid);
      _myApplications = (data['applications'] as List<dynamic>? ?? [])
          .map((a) => JobApplication.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (e) { _error = e.toString(); }
    finally { _setLoading(false); }
  }

  Future<bool> applyForJob(String jobId, String uid) async {
    try {
      await ApiService.applyForJob(jobId, uid);
      await loadMyApplications(uid);
      await loadSavedJobs(uid);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> submitJobApplication({
    required String jobId,
    required String uid,
    required String applicationText,
    List<String> attachments = const [],
  }) async {
    try {
      await ApiService.applyForJob(
        jobId,
        uid,
        applicationText: applicationText,
        attachments: attachments,
      );
      await loadMyApplications(uid);
      await loadSavedJobs(uid);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  bool hasAppliedToJob(String jobId) =>
      _myApplications.any((a) => a.jobId == jobId);

  Future<String?> generateAiApplicationDraft(String jobId, String uid) async {
    try {
      final data = await ApiService.generateAiApplicationDraft(jobId, uid);
      return data['application_text']?.toString();
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<bool> saveJob(String uid, String jobId) async {
    try {
      await ApiService.saveJob(uid, jobId);
      await loadSavedJobs(uid);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> postJob(Map<String, dynamic> jobData,
      {String? recruiterUid}) async {
    _setLoading(true);
    try {
      await ApiService.postJob(jobData);
      if (recruiterUid != null) {
        await loadRecruiterPostedJobs(recruiterUid);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRecruiterPostedJobs(String recruiterUid) async {
    try {
      final data = await ApiService.getRecruiterPostedJobs(recruiterUid);
      _recruiterJobs = (data['jobs'] as List<dynamic>? ?? [])
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadRecruiterApplications(String recruiterUid,
      {bool showLoading = true}) async {
    if (showLoading) _setLoading(true);
    try {
      final data = await ApiService.getRecruiterApplications(recruiterUid);
      _recruiterApplications = (data['applications'] as List<dynamic>? ?? [])
          .map((a) => JobApplication.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (showLoading) _setLoading(false);
    }
  }

  Future<void> refreshRecruiterDashboard(String recruiterUid) async {
    await loadRecruiterPostedJobs(recruiterUid);
    await loadRecruiterApplications(recruiterUid, showLoading: false);
  }

  Future<void> loadCourses(String uid) async {
    _setLoading(true);
    try {
      final data = await ApiService.getRecommendedCourses(uid);
      _coursesMessage = data['message'] as String?;
      _courses = (data['courses'] as List<dynamic>? ?? [])
          .map((c) => CourseModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) { _error = e.toString(); }
    finally { _setLoading(false); }
  }

  Future<void> loadWeeklyPlan(
    String uid, {
    String? courseId,
    String? courseTitle,
    String? courseUrl,
  }) async {
    _setLoading(true);
    try {
      final data = await ApiService.getWeeklyPlan(
        uid,
        courseId: courseId,
        courseTitle: courseTitle,
        courseUrl: courseUrl,
      );
      _weeklyPlanMessage = data['message'] as String?;
      _weeklyPlanCourseTitle = data['course_title'] as String?;
      final cid = data['course_id'];
      _weeklyPlanCourseId = cid == null ? null : cid.toString();
      _weeklyPlan = (data['weekly_plan'] as List<dynamic>? ?? [])
          .map((d) => WeeklyPlanDay.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (e) { _error = e.toString(); }
    finally { _setLoading(false); }
  }

  Future<void> runAiAnalysis(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final result = await ApiService.analyzeCareer(data);
      _aiAnalysis = AIAnalysisResult.fromJson(result);
    } catch (e) { _error = e.toString(); }
    finally { _setLoading(false); }
  }

  void clearError() { _error = null; notifyListeners(); }
}
