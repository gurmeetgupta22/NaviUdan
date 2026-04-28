class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String preferredLanguage;
  final String role; // job_finder | recruiter
  final String? state;
  final String? district;
  final String? ageGroup;
  final String? educationStatus;
  final String? classOrStream;
  final List<String> skills;
  final List<String> interests;
  final String? workExperience;
  final String? organization;
  final List<String> requiredSkills;
  final List<String> savedJobs;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    this.preferredLanguage = 'English',
    required this.role,
    this.state,
    this.district,
    this.ageGroup,
    this.educationStatus,
    this.classOrStream,
    this.skills = const [],
    this.interests = const [],
    this.workExperience,
    this.organization,
    this.requiredSkills = const [],
    this.savedJobs = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid:               json['uid'] ?? '',
      name:              json['name'] ?? '',
      phone:             json['phone'] ?? '',
      email:             json['email'],
      preferredLanguage: json['preferred_language'] ?? 'English',
      role:              json['role'] ?? 'job_finder',
      state:             json['state'],
      district:          json['district'],
      ageGroup:          json['age_group'],
      educationStatus:   json['education_status'],
      classOrStream:     json['class_or_stream'],
      skills:            List<String>.from(json['skills'] ?? []),
      interests:         List<String>.from(json['interests'] ?? []),
      workExperience:    json['work_experience'],
      organization:      json['organization'],
      requiredSkills:    List<String>.from(json['required_skills'] ?? []),
      savedJobs:         List<String>.from(json['saved_jobs'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid':               uid,
    'name':              name,
    'phone':             phone,
    'email':             email,
    'preferred_language': preferredLanguage,
    'role':              role,
    'state':             state,
    'district':          district,
    'age_group':         ageGroup,
    'education_status':  educationStatus,
    'class_or_stream':   classOrStream,
    'skills':            skills,
    'interests':         interests,
    'work_experience':   workExperience,
    'organization':      organization,
    'required_skills':   requiredSkills,
    'saved_jobs':        savedJobs,
  };

  UserModel copyWith({
    String? name, String? email, String? preferredLanguage,
    String? state, String? district, String? ageGroup,
    String? educationStatus, String? classOrStream,
    List<String>? skills, List<String>? interests,
    String? workExperience, String? organization,
    List<String>? requiredSkills, List<String>? savedJobs,
  }) {
    return UserModel(
      uid:               uid,
      name:              name              ?? this.name,
      phone:             phone,
      email:             email             ?? this.email,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      role:              role,
      state:             state             ?? this.state,
      district:          district          ?? this.district,
      ageGroup:          ageGroup          ?? this.ageGroup,
      educationStatus:   educationStatus   ?? this.educationStatus,
      classOrStream:     classOrStream     ?? this.classOrStream,
      skills:            skills            ?? this.skills,
      interests:         interests         ?? this.interests,
      workExperience:    workExperience    ?? this.workExperience,
      organization:      organization      ?? this.organization,
      requiredSkills:    requiredSkills    ?? this.requiredSkills,
      savedJobs:         savedJobs         ?? this.savedJobs,
    );
  }
}
