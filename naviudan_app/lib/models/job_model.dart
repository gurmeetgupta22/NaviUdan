class JobModel {
  final String? id;
  final String recruiterUid;
  final String title;
  final String description;
  final List<String> skillsRequired;
  final String? salary;
  final String jobType; // full_time | part_time | internship | contract
  final String location;
  final String? state;
  final String? district;
  final bool isActive;
  final String? expiresAt;
  final int? listingDays;

  const JobModel({
    this.id,
    required this.recruiterUid,
    required this.title,
    required this.description,
    required this.skillsRequired,
    this.salary,
    this.jobType = 'full_time',
    required this.location,
    this.state,
    this.district,
    this.isActive = true,
    this.expiresAt,
    this.listingDays,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id:             json['id'],
      recruiterUid:   json['recruiter_uid'] ?? '',
      title:          json['title'] ?? '',
      description:    json['description'] ?? '',
      skillsRequired: List<String>.from(json['skills_required'] ?? []),
      salary:         json['salary'],
      jobType:        json['job_type'] ?? 'full_time',
      location:       json['location'] ?? '',
      state:          json['state'],
      district:       json['district'],
      isActive:       json['is_active'] ?? true,
      expiresAt:      json['expires_at']?.toString(),
      listingDays:    json['listing_days'] is int
          ? json['listing_days'] as int
          : int.tryParse('${json['listing_days'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'recruiter_uid':   recruiterUid,
    'title':           title,
    'description':     description,
    'skills_required': skillsRequired,
    'salary':          salary,
    'job_type':        jobType,
    'location':        location,
    'state':           state,
    'district':        district,
    'is_active':       isActive,
  };

  String get jobTypLabel {
    switch (jobType) {
      case 'part_time':   return 'Part Time';
      case 'internship':  return 'Internship';
      case 'contract':    return 'Contract';
      default:            return 'Full Time';
    }
  }
}

class JobApplication {
  final String? id;
  final String jobId;
  final String applicantUid;
  final String? applicationText;
  final List<String> attachments;
  final String status; // pending | accepted | rejected

  const JobApplication({
    this.id,
    required this.jobId,
    required this.applicantUid,
    this.applicationText,
    this.attachments = const [],
    this.status = 'pending',
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id:           json['id'],
      jobId:        json['job_id'] ?? '',
      applicantUid: json['applicant_uid'] ?? '',
      applicationText: json['application_text']?.toString(),
      attachments: List<String>.from(json['attachments'] ?? const []),
      status:       json['status'] ?? 'pending',
    );
  }
}
