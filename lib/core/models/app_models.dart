// No Firebase imports needed — pure Dart models for Laravel MySQL backend
enum UserRole { admin, pa, user }

class PaAvailability {
  final String id;
  final String date;
  final bool isAvailable;
  final String? startTime;
  final String? endTime;

  PaAvailability({
    this.id = '',
    required this.date,
    required this.isAvailable,
    this.startTime,
    this.endTime,
  });

  factory PaAvailability.fromMap(Map<String, dynamic> map) {
    return PaAvailability(
      id: map['id']?.toString() ?? '',
      date: map['date'] ?? '',
      isAvailable: map['is_available'] == 1 || map['is_available'] == true,
      startTime: map['start_time'],
      endTime: map['end_time'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'is_available': isAvailable,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? state;
  final String? city;
  final String? area;
  final String? ward;
  final String? village;
  final String? profileImageUrl;
  final String? dob;
  final String? birthPlace;
  final String? education;
  final String? occupation;
  final String? spouse;
  final String? parents;
  final String? vision;
  final String? mission;
  final String? politicalJourney;
  final String? achievements;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.state,
    this.city,
    this.area,
    this.ward,
    this.village,
    this.profileImageUrl,
    this.dob,
    this.birthPlace,
    this.education,
    this.occupation,
    this.spouse,
    this.parents,
    this.vision,
    this.mission,
    this.politicalJourney,
    this.achievements,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'user'),
        orElse: () => UserRole.user,
      ),
      phone: map['phone'],
      state: map['state'],
      city: map['city'],
      area: map['area'],
      ward: map['ward'],
      village: map['village'],
      profileImageUrl: map['profileImageUrl'] ?? map['profile_image_url'],
      dob: map['dob'],
      birthPlace: map['birthPlace'] ?? map['birth_place'],
      education: map['education'],
      occupation: map['occupation'],
      spouse: map['spouse'],
      parents: map['parents'],
      vision: map['vision'],
      mission: map['mission'],
      politicalJourney: map['politicalJourney'] ?? map['political_journey'],
      achievements: map['achievements'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
      'state': state,
      'city': city,
      'area': area,
      'ward': ward,
      'village': village,
      'profileImageUrl': profileImageUrl,
      'dob': dob,
      'birth_place': birthPlace,
      'education': education,
      'occupation': occupation,
      'spouse': spouse,
      'parents': parents,
      'vision': vision,
      'mission': mission,
      'political_journey': politicalJourney,
      'achievements': achievements,
    };
  }
}

class PAProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String employeeId;
  final String education;
  final String designation;
  final String assignedTo;
  final String officeLocation;
  final String address;
  final String idProofType;
  final String idProofNumber;
  final String? profileImageUrl;
  final DateTime joiningDate;
  final DateTime createdAt;
  final String status; // active / inactive

  PAProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeId,
    required this.education,
    this.designation = 'Personal Assistant',
    this.assignedTo = 'Anup Dhotre (MP)',
    required this.officeLocation,
    required this.address,
    required this.idProofType,
    required this.idProofNumber,
    this.profileImageUrl,
    required this.joiningDate,
    required this.createdAt,
    this.status = 'active',
  });

  PAProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? employeeId,
    String? education,
    String? designation,
    String? assignedTo,
    String? officeLocation,
    String? address,
    String? idProofType,
    String? idProofNumber,
    String? profileImageUrl,
    DateTime? joiningDate,
    DateTime? createdAt,
    String? status,
  }) {
    return PAProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
      education: education ?? this.education,
      designation: designation ?? this.designation,
      assignedTo: assignedTo ?? this.assignedTo,
      officeLocation: officeLocation ?? this.officeLocation,
      address: address ?? this.address,
      idProofType: idProofType ?? this.idProofType,
      idProofNumber: idProofNumber ?? this.idProofNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joiningDate: joiningDate ?? this.joiningDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  factory PAProfile.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PAProfile(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      employeeId: map['employeeId'] ?? '',
      education: map['education'] ?? '',
      designation: map['designation'] ?? 'Personal Assistant',
      assignedTo: map['assignedTo'] ?? 'Anup Dhotre (MP)',
      officeLocation: map['officeLocation'] ?? '',
      address: map['address'] ?? '',
      idProofType: map['idProofType'] ?? '',
      idProofNumber: map['idProofNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      joiningDate: _parseDate(map['joiningDate']),
      createdAt: _parseDate(map['createdAt']),
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'employeeId': employeeId,
      'education': education,
      'designation': designation,
      'assignedTo': assignedTo,
      'officeLocation': officeLocation,
      'address': address,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'profileImageUrl': profileImageUrl,
      'joiningDate': joiningDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'role': 'pa',
    };
  }
}

class Appointment {
  final String id;
  final String userId;
  final String userName;
  final String issue;
  final DateTime date;
  final String time;
  final String status; // pending / approved / rejected / follow-up due / overdue / escalated
  final String? token;
  final String? phone;
  final String priority; // High / Medium / Low
  final bool isEscalated;
  final String? escalatedTo;
  final DateTime? followUpDate;
  final DateTime? reminderDate;
  final bool isSeniorCitizen;
  final bool isMediaContact;

  Appointment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.issue,
    required this.date,
    required this.time,
    required this.status,
    this.token,
    this.phone,
    this.priority = 'Medium',
    this.isEscalated = false,
    this.escalatedTo,
    this.followUpDate,
    this.reminderDate,
    this.isSeniorCitizen = false,
    this.isMediaContact = false,
  });

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? _parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Appointment(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      issue: map['issue'] ?? '',
      date: parsedDate,
      time: map['time'] ?? '',
      status: map['status'] ?? 'pending',
      token: map['token'],
      phone: map['phone'],
      priority: map['priority'] ?? 'Medium',
      isEscalated: map['is_escalated'] == 1 || map['is_escalated'] == true,
      escalatedTo: map['escalated_to'],
      followUpDate: _parseNullableDate(map['follow_up_date']),
      reminderDate: _parseNullableDate(map['reminder_date']),
      isSeniorCitizen: map['is_senior_citizen'] == 1 || map['is_senior_citizen'] == true,
      isMediaContact: map['is_media_contact'] == 1 || map['is_media_contact'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'issue': issue,
      'date': date.toIso8601String(),
      'time': time,
      'status': status,
      'token': token,
      'phone': phone,
      'priority': priority,
      'is_escalated': isEscalated,
      'escalated_to': escalatedTo,
      'follow_up_date': followUpDate?.toIso8601String(),
      'reminder_date': reminderDate?.toIso8601String(),
      'is_senior_citizen': isSeniorCitizen,
      'is_media_contact': isMediaContact,
    };
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String createdBy;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.createdBy,
  });

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: parsedDate,
      location: map['location'] ?? '',
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'createdBy': createdBy,
    };
  }
}

class Complaint {
  final String id;
  final String userId;
  final String userName;
  final String category;
  final String description;
  final String location;
  final String status; // pending / in progress / resolved / follow-up due / overdue / escalated
  final DateTime createdAt;
  final String? imageUrl;
  final String priority; // High / Medium / Low
  final bool isEscalated;
  final String? escalatedTo;
  final DateTime? followUpDate;
  final DateTime? reminderDate;
  final bool isSeniorCitizen;
  final bool isMediaContact;

  Complaint({
    required this.id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.priority = 'Medium',
    this.isEscalated = false,
    this.escalatedTo,
    this.followUpDate,
    this.reminderDate,
    this.isSeniorCitizen = false,
    this.isMediaContact = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'category': category,
      'description': description,
      'location': location,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'priority': priority,
      'is_escalated': isEscalated,
      'escalated_to': escalatedTo,
      'follow_up_date': followUpDate?.toIso8601String(),
      'reminder_date': reminderDate?.toIso8601String(),
      'is_senior_citizen': isSeniorCitizen,
      'is_media_contact': isMediaContact,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? _parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Complaint(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: parsedDate,
      imageUrl: map['imageUrl'],
      priority: map['priority'] ?? 'Medium',
      isEscalated: map['is_escalated'] == 1 || map['is_escalated'] == true,
      escalatedTo: map['escalated_to'],
      followUpDate: _parseNullableDate(map['follow_up_date']),
      reminderDate: _parseNullableDate(map['reminder_date']),
      isSeniorCitizen: map['is_senior_citizen'] == 1 || map['is_senior_citizen'] == true,
      isMediaContact: map['is_media_contact'] == 1 || map['is_media_contact'] == true,
    );
  }
}

class CitizenFeedback {
  final String id;
  final String userId;
  final String userName;
  final String projectCategory;
  final double rating;
  final String comment;
  final DateTime createdAt;

  CitizenFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.projectCategory,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'project_category': projectCategory,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CitizenFeedback.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['created_at'] != null) {
      parsedDate = DateTime.tryParse(map['created_at'] as String) ?? DateTime.now();
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return CitizenFeedback(
      id: id,
      userId: map['user_id']?.toString() ?? map['userId'] ?? '',
      userName: map['userName'] ?? '', // keeping for firestore compatibility if needed
      projectCategory: map['project_category']?.toString() ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: parsedDate,
    );
  }
}

class ScheduleItem {
  final String id;
  final String title;
  final String type; // Appointment, Program, Speech, Event
  final String time;
  final DateTime date;
  final String description;
  final String? organizerName;
  final String? organizerContact;
  final String? imageUrl;
  final String? location;
  final String? mapUrl;
  final String status; // pending / attended

  ScheduleItem({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.date,
    required this.description,
    this.organizerName,
    this.organizerContact,
    this.imageUrl,
    this.location,
    this.mapUrl,
    this.status = 'pending',
  });

  factory ScheduleItem.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ScheduleItem(
      id: id,
      title: map['title'] ?? '',
      type: map['type'] ?? 'Program',
      time: map['time'] ?? '',
      date: parsedDate,
      description: map['description'] ?? '',
      organizerName: map['organizerName'],
      organizerContact: map['organizerContact'],
      imageUrl: map['imageUrl'],
      location: map['location'],
      mapUrl: map['mapUrl'],
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'time': time,
      'date': date.toIso8601String(),
      'description': description,
      'organizerName': organizerName,
      'organizerContact': organizerContact,
      'imageUrl': imageUrl,
      'location': location,
      'mapUrl': mapUrl,
      'status': status,
    };
  }

  ScheduleItem copyWith({
    String? id,
    String? title,
    String? type,
    String? time,
    DateTime? date,
    String? description,
    String? organizerName,
    String? organizerContact,
    String? imageUrl,
    String? location,
    String? mapUrl,
    String? status,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      time: time ?? this.time,
      date: date ?? this.date,
      description: description ?? this.description,
      organizerName: organizerName ?? this.organizerName,
      organizerContact: organizerContact ?? this.organizerContact,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      mapUrl: mapUrl ?? this.mapUrl,
      status: status ?? this.status,
    );
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final String? budget;
  final String? timeline;
  final String? location;
  final String status;
  final String? beforeImageUrl;
  final String? afterImageUrl;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    this.budget,
    this.timeline,
    this.location,
    required this.status,
    this.beforeImageUrl,
    this.afterImageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'budget': budget,
      'timeline': timeline,
      'location': location,
      'status': status,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Project(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      budget: map['budget'],
      timeline: map['timeline'],
      location: map['location'],
      status: map['status'] ?? 'planned',
      beforeImageUrl: map['beforeImageUrl'],
      afterImageUrl: map['afterImageUrl'],
      createdAt: parsedDate,
    );
  }
}

class Rsvp {
  final int id;
  final int newsPostId;
  final int userId;
  final String status;
  final AppUser? user;
  final DateTime createdAt;

  Rsvp({
    required this.id,
    required this.newsPostId,
    required this.userId,
    required this.status,
    this.user,
    required this.createdAt,
  });

  factory Rsvp.fromMap(Map<String, dynamic> map) {
    return Rsvp(
      id: map['id'],
      newsPostId: map['news_post_id'],
      userId: map['user_id'],
      status: map['status'],
      user: map['user'] != null ? AppUser.fromMap(map['user'], map['user']['id'].toString()) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class NewsCategory {
  final String id;
  final String name;
  final String slug;

  NewsCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory NewsCategory.fromMap(Map<String, dynamic> map, String id) {
    return NewsCategory(
      id: id,
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
    };
  }
}

class NewsPost {
  final String id;
  final String title;
  final String description;
  final String? image;
  final List<String> images; // NEW
  final String mediaType; // NEW
  final String? videoUrl;
  final String? thumbnailUrl; // NEW
  final DateTime? publishedAt;
  final String status;
  final String createdBy;
  final String? categoryId; // NEW
  final NewsCategory? category; // NEW
  final DateTime? eventDate; // NEW
  final String? location; // NEW
  final int likesCount; // NEW
  final int commentsCount; // NEW
  final bool isLiked; // NEW
  final bool allowLikes; // PA toggle
  final bool allowComments; // PA toggle
  final bool allowShare; // PA toggle

  NewsPost({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.images = const [],
    this.mediaType = 'photo',
    this.videoUrl,
    this.thumbnailUrl,
    this.publishedAt,
    required this.status,
    required this.createdBy,
    this.categoryId,
    this.category,
    this.eventDate,
    this.location,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.allowLikes = true,
    this.allowComments = true,
    this.allowShare = true,
  });

  factory NewsPost.fromMap(Map<String, dynamic> map, String id) {
    DateTime? pubDate;
    if (map['published_at'] != null) {
      pubDate = DateTime.tryParse(map['published_at'].toString());
    } else if (map['publishedAt'] != null) {
      pubDate = DateTime.tryParse(map['publishedAt'].toString());
    }
    
    DateTime? evDate;
    if (map['event_date'] != null) {
      evDate = DateTime.tryParse(map['event_date'].toString());
    } else if (map['eventDate'] != null) {
      evDate = DateTime.tryParse(map['eventDate'].toString());
    }

    List<String> parsedImages = [];
    if (map['images'] != null && map['images'] is List) {
      parsedImages = (map['images'] as List)
          .map((img) => img['image_url'] as String)
          .toList();
    } else if (map['image'] != null) {
      parsedImages.add(map['image'] as String);
    }

    NewsCategory? parsedCategory;
    if (map['category'] != null) {
      parsedCategory = NewsCategory.fromMap(map['category'], map['category']['id']?.toString() ?? '');
    }

    return NewsPost(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      image: map['image'],
      images: parsedImages,
      mediaType: map['media_type'] ?? 'photo',
      videoUrl: map['video_url'] ?? map['videoUrl'],
      thumbnailUrl: map['thumbnail_url'] ?? map['thumbnailUrl'],
      publishedAt: pubDate ?? DateTime.now(),
      status: map['status'] ?? 'published',
      createdBy: map['created_by'] ?? map['createdBy'] ?? '',
      categoryId: map['category_id']?.toString() ?? map['categoryId']?.toString(),
      category: parsedCategory,
      eventDate: evDate,
      location: map['location'],
      likesCount: map['likes_count'] ?? map['likesCount'] ?? 0,
      commentsCount: map['comments_count'] ?? map['commentsCount'] ?? 0,
      isLiked: map['is_liked'] ?? map['isLiked'] ?? false,
      allowLikes: map['allow_likes'] != null ? (map['allow_likes'] == true || map['allow_likes'] == 1) : true,
      allowComments: map['allow_comments'] != null ? (map['allow_comments'] == true || map['allow_comments'] == 1) : true,
      allowShare: map['allow_share'] != null ? (map['allow_share'] == true || map['allow_share'] == 1) : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'images': images,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'published_at': publishedAt?.toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'category_id': categoryId,
      'event_date': eventDate?.toIso8601String(),
      'location': location,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'allow_likes': allowLikes,
      'allow_comments': allowComments,
      'allow_share': allowShare,
    };
  }
}

class Donation {
  final String id;
  final String? userId;
  final String? userEmail;
  final String donorName;
  final String phone;
  final double amount;
  final DateTime donationDate;
  final String purpose;
  final String paymentMode;
  final String transactionId;
  final String status;
  final DateTime createdAt;

  Donation({
    required this.id,
    this.userId,
    this.userEmail,
    required this.donorName,
    required this.phone,
    required this.amount,
    required this.donationDate,
    required this.purpose,
    required this.paymentMode,
    required this.transactionId,
    required this.status,
    required this.createdAt,
  });

  factory Donation.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Donation(
      id: id,
      userId: map['userId'],
      userEmail: map['userEmail'],
      donorName: map['donorName'] ?? '',
      phone: map['phone'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      donationDate: _parseDate(map['donationDate']),
      purpose: map['purpose'] ?? '',
      paymentMode: map['paymentMode'] ?? '',
      transactionId: map['transactionId'] ?? '',
      status: map['status'] ?? 'Completed',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'donorName': donorName,
      'phone': phone,
      'amount': amount,
      'donationDate': donationDate.toIso8601String(),
      'purpose': purpose,
      'paymentMode': paymentMode,
      'transactionId': transactionId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CitizenMessage {
  final String id;
  final String? userId;
  final String userName;
  final String userEmail;
  final String? phone;
  final String subject;
  final String body;
  final String priority;
  final String status;
  final bool isEscalated;
  final String? escalatedTo;
  final DateTime? followUpDate;
  final DateTime? reminderDate;
  final bool isSeniorCitizen;
  final bool isMediaContact;
  final DateTime createdAt;

  CitizenMessage({
    required this.id,
    this.userId,
    required this.userName,
    required this.userEmail,
    this.phone,
    required this.subject,
    required this.body,
    required this.priority,
    required this.status,
    required this.isEscalated,
    this.escalatedTo,
    this.followUpDate,
    this.reminderDate,
    required this.isSeniorCitizen,
    required this.isMediaContact,
    required this.createdAt,
  });

  factory CitizenMessage.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? _parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return CitizenMessage(
      id: id,
      userId: map['userId'],
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      phone: map['phone'],
      subject: map['subject'] ?? '',
      body: map['body'] ?? '',
      priority: map['priority'] ?? 'Medium',
      status: map['status'] ?? 'Pending',
      isEscalated: map['is_escalated'] == 1 || map['is_escalated'] == true,
      escalatedTo: map['escalated_to'],
      followUpDate: _parseNullableDate(map['follow_up_date']),
      reminderDate: _parseNullableDate(map['reminder_date']),
      isSeniorCitizen: map['is_senior_citizen'] == 1 || map['is_senior_citizen'] == true,
      isMediaContact: map['is_media_contact'] == 1 || map['is_media_contact'] == true,
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'phone': phone,
      'subject': subject,
      'body': body,
      'priority': priority,
      'status': status,
      'is_escalated': isEscalated,
      'escalated_to': escalatedTo,
      'follow_up_date': followUpDate?.toIso8601String(),
      'reminder_date': reminderDate?.toIso8601String(),
      'is_senior_citizen': isSeniorCitizen,
      'is_media_contact': isMediaContact,
    };
  }
}


class MeetingNote {
  final String id;
  final String? appointmentId;
  final String meetingTitle;
  final DateTime meetingDate;
  final String participants;
  final String discussionPoints;
  final String decisions;
  final String actionItems;
  final DateTime? followUpDate;
  final DateTime createdAt;

  MeetingNote({
    required this.id,
    this.appointmentId,
    required this.meetingTitle,
    required this.meetingDate,
    required this.participants,
    required this.discussionPoints,
    required this.decisions,
    required this.actionItems,
    this.followUpDate,
    required this.createdAt,
  });

  factory MeetingNote.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? _parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return MeetingNote(
      id: id,
      appointmentId: map['appointment_id']?.toString() ?? map['appointmentId']?.toString(),
      meetingTitle: map['meeting_title'] ?? map['meetingTitle'] ?? '',
      meetingDate: _parseDate(map['meeting_date'] ?? map['meetingDate']),
      participants: map['participants'] ?? '',
      discussionPoints: map['discussion_points'] ?? map['discussionPoints'] ?? '',
      decisions: map['decisions'] ?? '',
      actionItems: map['action_items'] ?? map['actionItems'] ?? '',
      followUpDate: _parseNullableDate(map['follow_up_date'] ?? map['followUpDate']),
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointment_id': appointmentId,
      'meeting_title': meetingTitle,
      'meeting_date': meetingDate.toIso8601String(),
      'participants': participants,
      'discussion_points': discussionPoints,
      'decisions': decisions,
      'action_items': actionItems,
      'follow_up_date': followUpDate?.toIso8601String(),
    };
  }
}

class SocialLinks {
  final String? facebookUrl;
  final String? instagramUrl;
  final String? xUrl;

  SocialLinks({
    this.facebookUrl,
    this.instagramUrl,
    this.xUrl,
  });

  factory SocialLinks.fromMap(Map<String, dynamic> map) {
    return SocialLinks(
      facebookUrl: map['facebook_url'] ?? map['facebookUrl'],
      instagramUrl: map['instagram_url'] ?? map['instagramUrl'],
      xUrl: map['x_url'] ?? map['xUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facebook_url': facebookUrl,
      'instagram_url': instagramUrl,
      'x_url': xUrl,
    };
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String? department;
  final String phone;
  final String? description;
  final bool status;

  EmergencyContact({
    required this.id,
    required this.name,
    this.department,
    required this.phone,
    this.description,
    required this.status,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      department: map['department'],
      phone: map['phone'] ?? '',
      description: map['description'],
      status: map['status'] == true || map['status'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'phone': phone,
      'description': description,
      'status': status,
    };
  }
}

class Department {
  final String id;
  final String name;
  final String? description;
  final bool status;

  Department({
    required this.id,
    required this.name,
    this.description,
    required this.status,
  });

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      status: map['status'] == 1 || map['status'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
    };
  }
}

class Official {
  final String id;
  final String departmentId;
  final String name;
  final String? designation;
  final String? phone;
  final String? email;
  final bool status;
  final Department? department;

  Official({
    required this.id,
    required this.departmentId,
    required this.name,
    this.designation,
    this.phone,
    this.email,
    required this.status,
    this.department,
  });

  factory Official.fromMap(Map<String, dynamic> map) {
    return Official(
      id: map['id']?.toString() ?? '',
      departmentId: map['department_id']?.toString() ?? '',
      name: map['name'] ?? '',
      designation: map['designation'],
      phone: map['phone'],
      email: map['email'],
      status: map['status'] == 1 || map['status'] == true,
      department: map['department'] != null
          ? Department.fromMap(map['department'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department_id': departmentId,
      'name': name,
      'designation': designation,
      'phone': phone,
      'email': email,
      'status': status,
    };
  }
}

class CustomCity {
  final int id;
  final String state;
  final String name;
  final String? nameMr;
  final String? nameHi;

  CustomCity({
    required this.id,
    required this.state,
    required this.name,
    this.nameMr,
    this.nameHi,
  });

  factory CustomCity.fromMap(Map<String, dynamic> map) {
    return CustomCity(
      id: map['id'] ?? 0,
      state: map['state'] ?? '',
      name: map['name'] ?? '',
      nameMr: map['name_mr'],
      nameHi: map['name_hi'],
    );
  }
}

class CustomVillage {
  final int id;
  final String city;
  final String name;
  final String? nameMr;
  final String? nameHi;

  CustomVillage({
    required this.id,
    required this.city,
    required this.name,
    this.nameMr,
    this.nameHi,
  });

  factory CustomVillage.fromMap(Map<String, dynamic> map) {
    return CustomVillage(
      id: map['id'] ?? 0,
      city: map['city'] ?? '',
      name: map['name'] ?? '',
      nameMr: map['name_mr'],
      nameHi: map['name_hi'],
    );
  }
}

