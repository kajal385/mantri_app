import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://mla.bizz-manager.com/api/',

      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final data = response.data;
          if (data is Map<String, dynamic> &&
              data.containsKey('success') &&
              data.containsKey('data')) {
            response.data = data['data'];
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          String message = 'An unexpected error occurred';
          if (e.response != null) {
            final statusCode = e.response?.statusCode;
            dynamic rawData = e.response?.data;

            // Try to extract message from the JSON response
            try {
              Map<String, dynamic>? data;
              if (rawData is Map<String, dynamic>) {
                data = rawData;
              }
              if (data != null && data['message'] != null) {
                message = data['message'].toString();
              } else if (data != null && data['error'] != null) {
                message = data['error'].toString();
              } else {
                switch (statusCode) {
                  case 400:
                    message = 'Bad request. Please check your input.';
                    break;
                  case 401:
                    message = 'Session expired. Please log in again.';
                    break;
                  case 403:
                    message = 'Access denied.';
                    break;
                  case 404:
                    message = 'Resource not found (HTTP $statusCode).';
                    break;
                  case 422:
                    message = 'Validation failed. Please check your input.';
                    break;
                  case 500:
                    message = 'Server error. Please try again later.';
                    break;
                  default:
                    message = 'HTTP Error $statusCode';
                }
              }
            } catch (_) {
              message = 'HTTP Error $statusCode';
            }
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            message = 'Connection timed out. Please check your internet.';
          } else {
            message = 'Network error. Please check your internet connection.';
          }

          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              message: message,
              error: message,
            ),
          );
        },
      ),
    );
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      final token = response.data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String role, {
    String? phone,
    String? state,
    String? city,
    String? area,
    String? ward,
    String? village,
    String? dob,
    String? firebaseId,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'password': password,
        'role': role,
        'phone': phone,
        'state': state,
        'city': city,
        'area': area,
        'ward': ward,
        'village': village,
        'dob': dob,
        'firebase_id': firebaseId,
      };

      // Only add email if it's actually provided
      if (email != null && email.trim().isNotEmpty) {
        data['email'] = email.trim();
      }

      final response = await _dio.post('/register', data: data);
      final token = response.data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin creates a PA without replacing the admin auth token.
  Future<void> registerPa({
    required String name,
    required String email,
    required String password,
    required PAProfile paProfile,
  }) async {
    try {
      await _dio.post(
        '/register-pa',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': paProfile.phone,
          'employeeId': paProfile.employeeId,
          'education': paProfile.education,
          'designation': paProfile.designation,
          'assignedTo': paProfile.assignedTo,
          'officeLocation': paProfile.officeLocation,
          'address': paProfile.address,
          'idProofType': paProfile.idProofType,
          'idProofNumber': paProfile.idProofNumber,
          'joiningDate': paProfile.joiningDate.toIso8601String(),
          'status': paProfile.status,
          'profileImageUrl': paProfile.profileImageUrl,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AppUser?> getMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('auth_token')) return null;

      final response = await _dio.get('/me');
      return AppUser.fromMap(response.data, response.data['id'].toString());
    } catch (e) {
      return null;
    }
  }

  // ── News Categories ────────────────────────────────────────────────────────

  Future<List<NewsCategory>> getNewsCategories() async {
    try {
      final response = await _dio.get('/news-categories');
      final List data = response.data;
      return data
          .map((json) => NewsCategory.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── News ───────────────────────────────────────────────────────────────────

  Future<List<NewsPost>> getNews({String? categoryId, int? page}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null && categoryId != 'all') {
        queryParams['category_id'] = categoryId;
      }
      if (page != null) {
        queryParams['page'] = page;
      }

      final response = await _dio.get('/news', queryParameters: queryParams);

      List data = [];
      if (page != null) {
        // Laravel paginator response
        data = response.data['data'] ?? [];
      } else {
        data = response.data;
      }

      return data
          .map((json) => NewsPost.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<NewsPost>> getNewsList() async {
    return await getNews();
  }

  Future<void> addNews({
    required String title,
    required String description,
    String? mediaType,
    String? imageUrl,
    List<String>? images,
    String? videoUrl,
    String? thumbnailUrl,
    String? status,
    String? categoryId,
    DateTime? eventDate,
    String? location,
    bool allowLikes = true,
    bool allowComments = true,
    bool allowShare = true,
  }) async {
    try {
      await _dio.post(
        '/news',
        data: {
          'title': title,
          'description': description,
          'media_type': mediaType ?? 'photo',
          'image': imageUrl,
          'images': images,
          'video_url': videoUrl,
          'thumbnail_url': thumbnailUrl,
          'status': status ?? 'published',
          'category_id': categoryId,
          'event_date': eventDate?.toIso8601String(),
          'location': location,
          'allow_likes': allowLikes,
          'allow_comments': allowComments,
          'allow_share': allowShare,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteNews(String id) async {
    try {
      await _dio.delete('/news/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload a file (image or video) to the server. Returns the public URL.
  Future<String> uploadFile(File file, String folder) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'folder': folder,
      });
      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      // Backend returns { url: '...' } or just the URL string
      if (response.data is Map) {
        return response.data['url'] as String;
      }
      return response.data as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload a video file to the server via dedicated /upload-video endpoint.
  Future<String> uploadVideo(File file, String folder) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: DioMediaType('video', ext),
        ),
        'folder': folder,
      });
      final response = await _dio.post(
        '/upload-video',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      if (response.data is Map) {
        return response.data['url'] as String;
      }
      return response.data as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> likeNews(String postId) async {
    try {
      await _dio.post('/news/$postId/like');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unlikeNews(String postId) async {
    try {
      await _dio.delete('/news/$postId/like');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _dio.get('/news/$postId/comments');
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> addComment(String postId, String text) async {
    try {
      await _dio.post('/news/$postId/comments', data: {'comment': text});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateNewsPost(
    String id, {
    String? title,
    String? description,
    String? mediaType,
    String? imageUrl,
    List<String>? images,
    String? videoUrl,
    String? thumbnailUrl,
    String? status,
    String? categoryId,
    DateTime? eventDate,
    String? location,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (mediaType != null) data['media_type'] = mediaType;
      if (imageUrl != null) data['image'] = imageUrl;
      if (images != null) data['images'] = images;
      if (videoUrl != null) data['video_url'] = videoUrl;
      if (thumbnailUrl != null) data['thumbnail_url'] = thumbnailUrl;
      if (status != null) data['status'] = status;
      if (categoryId != null) data['category_id'] = categoryId;
      if (eventDate != null) data['event_date'] = eventDate.toIso8601String();
      if (location != null) data['location'] = location;

      await _dio.put('/news/$id', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<List<Event>> getEvents() async {
    try {
      final response = await _dio.get('/events');
      final List data = response.data;
      return data
          .map((json) => Event.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      await _dio.post(
        '/events',
        data: {
          'title': event.title,
          'description': event.description,
          'location': event.location,
          'date': event.date.toIso8601String(),
          'createdBy': event.createdBy,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _dio.delete('/events/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Appointments ───────────────────────────────────────────────────────────

  Future<List<Appointment>> getAppointments({String? status}) async {
    try {
      final response = await _dio.get(
        '/appointments',
        queryParameters: status != null ? {'status': status} : null,
      );
      final List data = response.data;
      return data
          .map((json) => Appointment.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Appointment>> getUserAppointments() async {
    try {
      final response = await _dio.get('/my-appointments');
      final List data = response.data;
      return data
          .map((json) => Appointment.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Appointment>> getCitizenAppointments(String userId) async {
    try {
      final response = await _dio.get(
        '/citizen-appointments',
        queryParameters: {'userId': userId},
      );
      final List data = response.data;
      return data
          .map((json) => Appointment.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── PA Availability ───────────────────────────────────────────────────────

  Future<List<PaAvailability>> getPaAvailabilities() async {
    try {
      final response = await _dio.get('/pa-availabilities');
      final List data = response.data;
      return data.map((json) => PaAvailability.fromMap(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updatePaAvailability(PaAvailability availability) async {
    try {
      await _dio.post('/pa-availabilities', data: availability.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePaAvailability(String id) async {
    try {
      await _dio.delete('/pa-availabilities/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNextAvailableSlots() async {
    try {
      final response = await _dio.get('/appointment-slots');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'date': null, 'slots': []};
    }
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      await _dio.post(
        '/appointments',
        data: {
          'userId': appointment.userId,
          'userName': appointment.userName,
          'issue': appointment.issue,
          'date': appointment.date.toIso8601String(),
          'time': appointment.time,
          'phone': appointment.phone,
        },
      );
    } on DioException catch (e) {
      // Surface server-side error messages (e.g. 409 slot already booked)
      final serverMsg = e.response?.data?['message'];
      if (serverMsg != null) {
        throw Exception(serverMsg);
      }
      throw _handleError(e);
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _dio.put(
        '/appointments/${appointment.id}',
        data: {
          'userId': appointment.userId,
          'userName': appointment.userName,
          'issue': appointment.issue,
          'date': appointment.date.toIso8601String(),
          'time': appointment.time,
          'phone': appointment.phone,
        },
      );
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'];
      if (serverMsg != null) {
        throw Exception(serverMsg);
      }
      throw _handleError(e);
    }
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    try {
      await _dio.patch('/appointments/$id/status', data: {'status': status});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await _dio.delete('/appointments/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Appointment Issues ─────────────────────────────────────────────────────

  Future<List<String>> getAppointmentIssues() async {
    try {
      final response = await _dio.get('/appointment-issues');
      final List data = response.data;
      return data.map((item) => item['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addAppointmentIssue(String name) async {
    try {
      await _dio.post('/appointment-issues', data: {'name': name});
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Complaints ─────────────────────────────────────────────────────────────

  Future<List<Complaint>> getComplaints({String? userId}) async {
    try {
      final response = await _dio.get(
        '/complaints',
        queryParameters: userId != null ? {'userId': userId} : null,
      );
      final List data = response.data;
      return data
          .map((json) => Complaint.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addComplaint(Complaint complaint) async {
    try {
      await _dio.post(
        '/complaints',
        data: {
          'userId': complaint.userId,
          'userName': complaint.userName,
          'category': complaint.category,
          'description': complaint.description,
          'location': complaint.location,
          'imageUrl': complaint.imageUrl,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    try {
      await _dio.patch('/complaints/$id/status', data: {'status': status});
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

  Future<List<CitizenFeedback>> getFeedbacks() async {
    try {
      final response = await _dio.get('/feedback');
      final List data = response.data;
      return data
          .map((json) => CitizenFeedback.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addFeedback(CitizenFeedback feedback) async {
    try {
      await _dio.post(
        '/feedback',
        data: {
          'user_id': feedback.userId,
          'project_category': feedback.projectCategory,
          'rating': feedback.rating,
          'comment': feedback.comment,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteFeedback(String id) async {
    try {
      await _dio.delete('/feedback/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Feedback Project Categories ────────────────────────────────────────────

  Future<List<String>> getFeedbackProjectCategories() async {
    try {
      final response = await _dio.get('/feedback-project-categories');
      final List data = response.data;
      return data.map((item) => item['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addFeedbackProjectCategory(String name) async {
    try {
      await _dio.post('/feedback-project-categories', data: {'name': name});
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Projects ───────────────────────────────────────────────────────────────

  Future<List<Project>> getProjects({String? status}) async {
    try {
      final response = await _dio.get(
        '/projects',
        queryParameters: status != null ? {'status': status} : null,
      );
      final List data = response.data;
      return data
          .map((json) => Project.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addProject(Project project) async {
    try {
      await _dio.post(
        '/projects',
        data: {
          'title': project.title,
          'description': project.description,
          'budget': project.budget,
          'timeline': project.timeline,
          'location': project.location,
          'status': project.status,
          'beforeImageUrl': project.beforeImageUrl,
          'afterImageUrl': project.afterImageUrl,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _dio.delete('/projects/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── PA Profiles ────────────────────────────────────────────────────────────

  Future<List<PAProfile>> getPAProfiles() async {
    try {
      final response = await _dio.get('/pa-profiles');
      final List data = response.data;
      return data.map((json) {
        final id = (json['firebase_id'] ?? json['id']).toString();
        return PAProfile.fromMap(Map<String, dynamic>.from(json), id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<PAProfile?> getPAProfile(String uid) async {
    try {
      final response = await _dio.get('/pa-profiles/$uid');
      final json = response.data as Map<String, dynamic>;
      final id = (json['firebase_id'] ?? json['id']).toString();
      return PAProfile.fromMap(json, id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updatePAStatus(String uid, String status) async {
    try {
      await _dio.patch('/pa-profiles/$uid/status', data: {'status': status});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updatePAProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _dio.put('/pa-profiles/$uid', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePAProfile(String uid) async {
    try {
      await _dio.delete('/pa-profiles/$uid');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Schedules ──────────────────────────────────────────────────────────────

  Future<List<ScheduleItem>> getSchedules({
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (start != null) params['start'] = start.toIso8601String();
      if (end != null) params['end'] = end.toIso8601String();
      final response = await _dio.get('/schedules', queryParameters: params);
      final List data = response.data;
      return data
          .map((json) => ScheduleItem.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    try {
      await _dio.post('/schedules', data: item.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateScheduleStatus(String id, String status) async {
    try {
      await _dio.patch('/schedules/$id/status', data: {'status': status});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteScheduleItem(String id) async {
    try {
      await _dio.delete('/schedules/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── MP Profile ─────────────────────────────────────────────────────────────

  Future<AppUser?> getMpProfile() async {
    try {
      final response = await _dio.get('/mp-profile');
      return AppUser.fromMap(response.data, response.data['id'].toString());
    } catch (e) {
      return null;
    }
  }

  Future<AppUser> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/user/profile', data: data);
      return AppUser.fromMap(response.data, response.data['id'].toString());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Slider Images ──────────────────────────────────────────────────────────

  Future<List<String>> getSliderImages() async {
    try {
      final response = await _dio.get('/slider-images');
      final List data = response.data;
      return data.map((item) => item['url'].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addSliderImage(String url) async {
    try {
      await _dio.post('/slider-images', data: {'url': url});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteSliderImage(String url) async {
    try {
      await _dio.delete('/slider-images', queryParameters: {'url': url});
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<List<CitizenMessage>> getMessages({
    String? userId,
    String? status,
    String? priority,
  }) async {
    try {
      final response = await _dio.get(
        '/messages',
        queryParameters: {
          if (userId != null) 'userId': userId,
          if (status != null) 'status': status,
          if (priority != null) 'priority': priority,
        },
      );
      final List data = response.data;
      return data
          .map((json) => CitizenMessage.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addMessage(CitizenMessage msg) async {
    try {
      await _dio.post('/messages', data: msg.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateMessageStatus(String id, String status) async {
    try {
      await _dio.patch('/messages/$id/status', data: {'status': status});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateMessagePriority(String id, String priority) async {
    try {
      await _dio.patch('/messages/$id/priority', data: {'priority': priority});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateMessageFollowUp(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.patch('/messages/$id/follow-up', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Meeting Notes ──────────────────────────────────────────────────────────

  Future<List<MeetingNote>> getMeetingNotes({String? search}) async {
    try {
      final response = await _dio.get(
        '/meeting-notes',
        queryParameters: search != null ? {'search': search} : null,
      );
      final List data = response.data;
      return data
          .map((json) => MeetingNote.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addMeetingNote(MeetingNote note) async {
    try {
      await _dio.post('/meeting-notes', data: note.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MeetingNote>> getMeetingNotesForAppointment(
    String appointmentId,
  ) async {
    try {
      final response = await _dio.get(
        '/meeting-notes/appointment/$appointmentId',
      );
      final List data = response.data;
      return data
          .map((json) => MeetingNote.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Donations ──────────────────────────────────────────────────────────────

  Future<List<Donation>> getDonations({
    String? search,
    String? purpose,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/donations',
        queryParameters: {
          if (search != null) 'search': search,
          if (purpose != null) 'purpose': purpose,
          if (status != null) 'status': status,
        },
      );
      final List data = response.data;
      return data
          .map((json) => Donation.fromMap(json, json['id'].toString()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addDonation(Donation donation) async {
    try {
      await _dio.post('/donations', data: donation.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDonationSummary() async {
    try {
      final response = await _dio.get('/donations/summary');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'totalAmount': 0.0, 'donationCount': 0, 'recentDonations': []};
    }
  }

  // ── Existing Priority & Follow-up overrides ──────────────────────────────────

  Future<void> updateAppointmentPriority(String id, String priority) async {
    try {
      await _dio.patch(
        '/appointments/$id/priority',
        data: {'priority': priority},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateAppointmentFollowUp(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.patch('/appointments/$id/follow-up', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateComplaintPriority(String id, String priority) async {
    try {
      await _dio.patch(
        '/complaints/$id/priority',
        data: {'priority': priority},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateComplaintFollowUp(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.patch('/complaints/$id/follow-up', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Social Links ───────────────────────────────────────────────────────────

  Future<SocialLinks?> getSocialLinks() async {
    try {
      final response = await _dio.get('/social-links');
      if (response.data == null ||
          (response.data is String && response.data.isEmpty)) {
        return null;
      }
      return SocialLinks.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateSocialLinks(SocialLinks links) async {
    try {
      await _dio.put('/social-links', data: links.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Emergency Contacts ─────────────────────────────────────────────────────

  Future<List<EmergencyContact>> getEmergencyContacts({
    bool allContacts = false,
  }) async {
    try {
      final path =
          allContacts ? '/emergency-contacts/all' : '/emergency-contacts';
      final response = await _dio.get(path);
      final List<dynamic> data = response.data;
      return data.map((e) => EmergencyContact.fromMap(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<EmergencyContact> createEmergencyContact(
    EmergencyContact contact,
  ) async {
    try {
      final response = await _dio.post(
        '/emergency-contacts',
        data: contact.toMap(),
      );
      return EmergencyContact.fromMap(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<EmergencyContact> updateEmergencyContact(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/emergency-contacts/$id', data: data);
      return EmergencyContact.fromMap(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteEmergencyContact(String id) async {
    try {
      await _dio.delete('/emergency-contacts/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Departments ────────────────────────────────────────────────────────────

  Future<List<Department>> getDepartments({bool? status}) async {
    try {
      final response = await _dio.get(
        '/departments',
        queryParameters: {if (status != null) 'status': status ? 1 : 0},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => Department.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Department> createDepartment(Department department) async {
    try {
      final response = await _dio.post(
        '/departments',
        data: department.toMap(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return Department.fromMap(data);
      throw Exception('Unexpected response format from createDepartment');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Department> updateDepartment(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/departments/$id', data: data);
      final responseData = response.data;
      if (responseData is Map<String, dynamic>)
        return Department.fromMap(responseData);
      throw Exception('Unexpected response format from updateDepartment');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDepartment(String id) async {
    try {
      await _dio.delete('/departments/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── Officials ──────────────────────────────────────────────────────────────

  Future<List<Official>> getOfficials({
    String? departmentId,
    bool? status,
  }) async {
    try {
      final response = await _dio.get(
        '/officials',
        queryParameters: {
          if (departmentId != null) 'department_id': departmentId,
          if (status != null) 'status': status ? 1 : 0,
        },
      );
      final data = response.data;
      // Interceptor unwraps the 'data' key — data should be a List
      if (data is List) {
        return data
            .map((e) => Official.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Official> createOfficial(Official official) async {
    try {
      final response = await _dio.post('/officials', data: official.toMap());
      final data = response.data;
      // Interceptor already unwraps the 'data' key — it should be a Map
      if (data is Map<String, dynamic>) {
        return Official.fromMap(data);
      }
      throw Exception('Unexpected response format from createOfficial');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Official> updateOfficial(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/officials/$id', data: data);
      final responseData = response.data;
      // Interceptor already unwraps the 'data' key — it should be a Map
      if (responseData is Map<String, dynamic>) {
        return Official.fromMap(responseData);
      }
      throw Exception('Unexpected response format from updateOfficial');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteOfficial(String id) async {
    try {
      await _dio.delete('/officials/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, List<dynamic>>> getCustomLocations() async {
    try {
      final response = await _dio.get('/custom-locations');
      final data = response.data;
      final List rawCities = data['cities'] ?? [];
      final List rawVillages = data['villages'] ?? [];

      final cities = rawCities.map((json) => CustomCity.fromMap(json)).toList();
      final villages =
          rawVillages.map((json) => CustomVillage.fromMap(json)).toList();

      return {'cities': cities, 'villages': villages};
    } catch (e) {
      return {'cities': [], 'villages': []};
    }
  }

  Future<void> addCustomCity(
    String state,
    String name, {
    String? nameMr,
    String? nameHi,
  }) async {
    try {
      await _dio.post(
        '/custom-cities',
        data: {
          'state': state,
          'name': name,
          'name_mr': nameMr,
          'name_hi': nameHi,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addCustomVillage(
    String city,
    String name, {
    String? nameMr,
    String? nameHi,
  }) async {
    try {
      await _dio.post(
        '/custom-villages',
        data: {
          'city': city,
          'name': name,
          'name_mr': nameMr,
          'name_hi': nameHi,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  // ── RSVPs ──────────────────────────────────────────────────────────────────

  Future<void> submitRsvp(String newsPostId, String status) async {
    try {
      await _dio.post('/news/$newsPostId/rsvp', data: {'status': status});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Rsvp>> getRsvps(String newsPostId) async {
    try {
      final response = await _dio.get('/news/$newsPostId/rsvps');
      final List data = response.data;
      return data.map((json) => Rsvp.fromMap(json)).toList();
    } catch (e) {
      return [];
    }
  }
}

String _handleError(Object e) {
  if (e is DioException) {
    if (e.error is String) return e.error as String;
    return e.message ?? 'Network error';
  } else if (e is Exception) {
    return e.toString().replaceAll('Exception: ', '');
  }
  return 'An unexpected error occurred. Please try again.';
}
