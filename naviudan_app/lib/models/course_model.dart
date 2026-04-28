class CourseModel {
  final String? id;
  final String title;
  final String platform;
  final String url;
  final String language;
  final List<String> tags;
  final bool isFree;
  final String? duration;
  final String? description;

  const CourseModel({
    this.id,
    required this.title,
    required this.platform,
    required this.url,
    this.language = 'English',
    this.tags = const [],
    this.isFree = true,
    this.duration,
    this.description,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id:          json['id'],
      title:       json['title'] ?? '',
      platform:    json['platform'] ?? '',
      url:         json['url'] ?? '',
      language:    json['language'] ?? 'English',
      tags:        List<String>.from(json['tags'] ?? []),
      isFree:      json['is_free'] ?? true,
      duration:    json['duration'],
      description: json['description'],
    );
  }
}

class WeeklyPlanDay {
  final String day;
  final String topic;
  final String goal;
  final String resource;

  const WeeklyPlanDay({
    required this.day,
    required this.topic,
    required this.goal,
    required this.resource,
  });

  factory WeeklyPlanDay.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanDay(
      day:      json['day'] ?? '',
      topic:    json['topic'] ?? '',
      goal:     json['goal'] ?? '',
      resource: json['resource'] ?? '',
    );
  }
}

class AIAnalysisResult {
  final List<String> skillGaps;
  final List<String> suggestedSkills;
  final String careerDirection;
  final List<String> learningRoadmap;
  final List<String> recommendedCourses;
  final List<WeeklyPlanDay> weeklyPlan;

  const AIAnalysisResult({
    required this.skillGaps,
    required this.suggestedSkills,
    required this.careerDirection,
    required this.learningRoadmap,
    required this.recommendedCourses,
    required this.weeklyPlan,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      skillGaps:          List<String>.from(json['skill_gaps'] ?? []),
      suggestedSkills:    List<String>.from(json['suggested_skills'] ?? []),
      careerDirection:    json['career_direction'] ?? '',
      learningRoadmap:    List<String>.from(json['learning_roadmap'] ?? []),
      recommendedCourses: List<String>.from(json['recommended_courses'] ?? []),
      weeklyPlan: (json['weekly_plan'] as List<dynamic>? ?? [])
          .map((e) => WeeklyPlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
