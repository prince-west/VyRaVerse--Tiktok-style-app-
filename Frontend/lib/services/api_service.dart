import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import '../config/app_config.dart';
import '../models/video_item.dart';
import '../models/user_profile.dart';
import '../models/product_item.dart';
import '../models/club.dart';
import '../models/challenge.dart';
import '../models/sound.dart';
import '../models/profile_skin.dart';
import '../models/live_room.dart';
import '../models/status_item.dart';
import '../models/video_item.dart' show VideoAnalytics;

/// API Service with proper error handling, logging, timeouts, and retry logic
class ApiService {
  static const String _tokenKey = 'auth_token';
  static final String _baseUrl = AppConfig.baseUrl;
  static final Duration _timeout = Duration(seconds: AppConfig.requestTimeoutSeconds);

  // Get auth token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      _logError('_getToken', e);
      return null;
    }
  }

  // Save auth token
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      _logError('_saveToken', e);
    }
  }

  // Get headers with auth
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  // Error logging
  void _logError(String method, dynamic error, {String? url, int? statusCode}) {
    if (kDebugMode) {
      debugPrint('ApiService.$method Error: $error');
      if (url != null) debugPrint('URL: $url');
      if (statusCode != null) debugPrint('Status Code: $statusCode');
    }
    // In production, send to error tracking service (e.g., Sentry, Firebase Crashlytics)
  }

  // Parse error message from response
  String _parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
        // Check for field errors
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors.add('${key}: ${value.join(", ")}');
          } else if (value is String) {
            errors.add('${key}: $value');
          }
        });
        if (errors.isNotEmpty) {
          return errors.join('\n');
        }
      }
    } catch (e) {
      // If parsing fails, return generic message
    }
    return 'An error occurred. Please try again.';
  }

  // Retry logic for failed requests
  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = AppConfig.maxRetries,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        // Wait before retrying
        await Future.delayed(Duration(seconds: AppConfig.retryDelaySeconds * attempts));
      }
    }
    throw Exception('Request failed after $maxRetries attempts');
  }

  // Make HTTP request with timeout and error handling
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    String? methodName,
  }) async {
    try {
      final response = await request().timeout(_timeout);
      return response;
    } on TimeoutException {
      _logError(methodName ?? 'request', 'Request timeout');
      throw ApiException('Request timed out. Please check your internet connection.');
    } on http.ClientException catch (e) {
      _logError(methodName ?? 'request', e);
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('failed to fetch') || errorMsg.contains('connection refused')) {
        throw ApiException('Cannot connect to server. Please make sure the backend is running on http://localhost:8000');
      }
      throw ApiException('Network error. Please check your internet connection.');
    } catch (e) {
      _logError(methodName ?? 'request', e);
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  // Authentication
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    return await _retryRequest(() async {
      final headers = await _getHeaders(includeAuth: false);
      final response = await _makeRequest(
        () => http.post(
          Uri.parse('$_baseUrl/auth/signup/'),
          headers: headers,
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'password2': password2,
          }),
        ),
        methodName: 'signUp',
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          await _saveToken(token);
        }
        return data;
      } else {
        final errorMessage = _parseErrorMessage(response);
        _logError('signUp', errorMessage, url: '$_baseUrl/auth/signup/', statusCode: response.statusCode);
        throw ApiException(errorMessage);
      }
    });
  }

  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  }) async {
    return await _retryRequest(() async {
      final headers = await _getHeaders(includeAuth: false);
      final response = await _makeRequest(
        () => http.post(
          Uri.parse('$_baseUrl/auth/signin/'),
          headers: headers,
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        ),
        methodName: 'signIn',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          await _saveToken(token);
        }
        return data;
      } else {
        final errorMessage = _parseErrorMessage(response);
        _logError('signIn', errorMessage, url: '$_baseUrl/auth/signin/', statusCode: response.statusCode);
        throw ApiException(errorMessage);
      }
    });
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      _logError('signOut', e);
    }
  }

  // Profile
  Future<UserProfile> getProfile() async {
    return await _retryRequest(() async {
      final headers = await _getHeaders();
      final response = await _makeRequest(
        () => http.get(
          Uri.parse('$_baseUrl/profiles/me/'),
          headers: headers,
        ),
        methodName: 'getProfile',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      } else {
        final errorMessage = _parseErrorMessage(response);
        _logError('getProfile', errorMessage, url: '$_baseUrl/profiles/me/', statusCode: response.statusCode);
        throw ApiException(errorMessage);
      }
    });
  }

  Future<UserProfile?> getProfileByUsername(String username) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/profiles/?username=$username'),
            headers: headers,
          ),
          methodName: 'getProfileByUsername',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Handle paginated response (from DRF pagination)
          if (data is Map<String, dynamic>) {
            if (data.containsKey('results') && data['results'] is List) {
              final results = data['results'] as List;
              if (results.isNotEmpty) {
                return UserProfile.fromJson(results[0] as Map<String, dynamic>);
              }
            }
            // If it's a single profile object (from retrieve method)
            if (data.containsKey('id') || data.containsKey('username')) {
              return UserProfile.fromJson(data as Map<String, dynamic>);
            }
          }
          
          // Handle direct list response (non-paginated)
          if (data is List && data.isNotEmpty) {
            return UserProfile.fromJson(data[0] as Map<String, dynamic>);
          }
          
          return null;
        } else {
          _logError('getProfileByUsername', 'Not found', url: '$_baseUrl/profiles/?username=$username', statusCode: response.statusCode);
          return null;
        }
      });
    } catch (e) {
      _logError('getProfileByUsername', e);
      return null;
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/profiles/?search=$query'),
            headers: headers,
          ),
          methodName: 'searchUsers',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Handle paginated response (from DRF pagination)
          if (data is Map<String, dynamic> && data.containsKey('results')) {
            final results = data['results'];
            if (results is List) {
              return results.map((json) => UserProfile.fromJson(json as Map<String, dynamic>)).toList();
            }
          }
          
          // Handle direct list response (non-paginated)
          if (data is List) {
            return data.map((json) => UserProfile.fromJson(json as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('searchUsers', e);
      return [];
    }
  }

  Future<List<UserProfile>> getSuggestedUsers() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/profiles/suggested/'),
            headers: headers,
          ),
          methodName: 'getSuggestedUsers',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((json) => UserProfile.fromJson(json as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getSuggestedUsers', e);
      return [];
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates, {File? profileImage}) async {
    try {
      final profile = await getProfile();
      return await _retryRequest(() async {
        // Check if we need to upload a file - if so, use MultipartRequest
        if (profileImage != null) {
          // Check if file exists (for mobile) or if it's a web file
          bool fileExists = false;
          if (kIsWeb) {
            // On web, we can't check file existence, but we can try to use it
            fileExists = true;
          } else {
            fileExists = await profileImage.exists();
          }
          
          if (fileExists) {
            final request = http.MultipartRequest(
              'PATCH',
              Uri.parse('$_baseUrl/profiles/${profile.id}/'),
            );

            final headers = await _getHeaders();
            // Copy headers but remove Content-Type to let multipart set it
            request.headers.addAll(headers);
            request.headers.remove('Content-Type');
            
            // Add all text fields
            updates.forEach((key, value) {
              if (value != null && value is! File) {
                request.fields[key] = value.toString();
              }
            });

            // Add profile image file
            if (kIsWeb) {
              // Web: read file as bytes
              try {
                final bytes = await profileImage.readAsBytes();
                request.files.add(http.MultipartFile.fromBytes(
                  'profile_image',
                  bytes,
                  filename: profileImage.path.split('/').last,
                ));
              } catch (e) {
                debugPrint('Error reading image file on web: $e');
                throw ApiException('Failed to read image file');
              }
            } else {
              // Mobile: use file path
              request.files.add(await http.MultipartFile.fromPath(
                'profile_image',
                profileImage.path,
              ));
            }

            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);

            if (response.statusCode == 200) {
              return true;
            } else {
              final errorMessage = _parseErrorMessage(response);
              _logError('updateProfile', errorMessage, statusCode: response.statusCode);
              throw ApiException(errorMessage);
            }
          }
        }
        
        // No file upload or file doesn't exist - use regular PATCH with JSON
        if (updates.isNotEmpty) {
          final headers = await _getHeaders();
          final response = await _makeRequest(
            () => http.patch(
              Uri.parse('$_baseUrl/profiles/${profile.id}/'),
              headers: headers,
              body: jsonEncode(updates),
            ),
            methodName: 'updateProfile',
          );

          if (response.statusCode == 200) {
            return true;
          } else {
            final errorMessage = _parseErrorMessage(response);
            _logError('updateProfile', errorMessage, statusCode: response.statusCode);
            throw ApiException(errorMessage);
          }
        }
        
        return true; // No updates to make
      });
    } catch (e) {
      _logError('updateProfile', e);
      return false;
    }
  }

  Future<bool> followUser(String userId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/profiles/$userId/follow/'),
            headers: headers,
          ),
          methodName: 'followUser',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('followUser', e);
      return false;
    }
  }

  Future<bool> unfollowUser(String userId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.delete(
            Uri.parse('$_baseUrl/profiles/$userId/unfollow/'),
            headers: headers,
          ),
          methodName: 'unfollowUser',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('unfollowUser', e);
      return false;
    }
  }

  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/profiles/$userId/followers/'),
            headers: headers,
          ),
          methodName: 'getFollowers',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;
          return data.map((json) => UserProfile.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          return [];
        }
      });
    } catch (e) {
      _logError('getFollowers', e);
      return [];
    }
  }

  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/profiles/$userId/following/'),
            headers: headers,
          ),
          methodName: 'getFollowing',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;
          return data.map((json) => UserProfile.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          return [];
        }
      });
    } catch (e) {
      _logError('getFollowing', e);
      return [];
    }
  }

  // Videos
  Future<List<VideoItem>> getVideos({String? username, String? privacy}) async {
    try {
      return await _retryRequest(() async {
        String url = '$_baseUrl/videos/';
        final params = <String>[];
        if (username != null) params.add('username=$username');
        if (privacy != null) params.add('privacy=$privacy');
        if (params.isNotEmpty) url += '?${params.join('&')}';

        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse(url),
            headers: headers,
          ),
          methodName: 'getVideos',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((v) => VideoItem.fromJson(v as Map<String, dynamic>)).toList();
          } else if (data is Map<String, dynamic> && data['results'] != null) {
            return (data['results'] as List)
                .map((v) => VideoItem.fromJson(v as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getVideos', e);
      return [];
    }
  }

  // Search videos
  Future<List<VideoItem>> searchVideos(String query) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/videos/?search=$query'),
            headers: headers,
          ),
          methodName: 'searchVideos',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((v) => VideoItem.fromJson(v as Map<String, dynamic>)).toList();
          } else if (data is Map<String, dynamic> && data['results'] != null) {
            return (data['results'] as List)
                .map((v) => VideoItem.fromJson(v as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('searchVideos', e);
      return [];
    }
  }

  Future<VideoItem?> uploadVideo({
    required String description,
    required String videoPath,
    String? privacy,
    List<String>? hashtags,
    List<int>? videoBytes,
    String? fileName,
    Function(int sent, int total)? onUploadProgress,
  }) async {
    try {
      return await _retryRequest(() async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/videos/'),
        );

        request.headers.addAll(await _getHeaders());
        request.fields['description'] = description;
        if (privacy != null) request.fields['privacy'] = privacy;
        if (hashtags != null) {
          request.fields['hashtags'] = hashtags.join(',');
        }

        int totalBytes = 0;
        
        // Handle web uploads (bytes) vs mobile uploads (file path)
        if (videoBytes != null && fileName != null) {
          // Web upload - use bytes
          totalBytes = videoBytes.length;
          request.files.add(http.MultipartFile.fromBytes(
            'video_file',
            videoBytes,
            filename: fileName,
          ));
        } else {
          // Mobile upload - use file path
          final file = File(videoPath);
          if (await file.exists()) {
            totalBytes = await file.length();
          }
          request.files.add(await http.MultipartFile.fromPath(
            'video_file',
            videoPath,
          ));
        }

        // Calculate total size for progress tracking
        final contentLength = request.contentLength;
        final totalSize = contentLength > 0 ? contentLength : totalBytes;
        
        // Create a progress-tracking stream transformer
        int bytesSent = 0;
        final requestStream = request.finalize();
        
        // Transform the stream to track bytes sent
        final progressStream = requestStream.transform<List<int>>(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (data, sink) {
              bytesSent += data.length;
              if (onUploadProgress != null && totalSize > 0) {
                onUploadProgress(bytesSent, totalSize);
              }
              sink.add(data);
            },
            handleDone: (sink) => sink.close(),
            handleError: (error, stackTrace, sink) => sink.addError(error, stackTrace),
          ),
        );

        // Create a new StreamedRequest with progress tracking
        final progressRequest = http.StreamedRequest(request.method, request.url);
        progressRequest.headers.addAll(request.headers);
        if (contentLength != null) {
          progressRequest.contentLength = contentLength;
        }
        progressRequest.followRedirects = request.followRedirects;
        progressRequest.maxRedirects = request.maxRedirects;
        
        // Pipe the progress stream to the request sink
        progressStream.listen(
          (data) {
            progressRequest.sink.add(data);
          },
          onDone: () {
            progressRequest.sink.close();
          },
          onError: (error) {
            progressRequest.sink.addError(error);
          },
          cancelOnError: true,
        );

        final streamedResponse = await progressRequest.send().timeout(_timeout);
        final responseBody = await http.Response.fromStream(streamedResponse);

        if (streamedResponse.statusCode == 201) {
          final data = jsonDecode(responseBody.body) as Map<String, dynamic>;
          return VideoItem.fromJson(data);
        } else {
          final errorMessage = _parseErrorMessage(responseBody);
          _logError('uploadVideo', errorMessage, statusCode: streamedResponse.statusCode);
          throw ApiException(errorMessage);
        }
      });
    } catch (e) {
      _logError('uploadVideo', e);
      return null;
    }
  }

  Future<bool> likeVideo(String videoId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/videos/$videoId/like/'),
            headers: headers,
          ),
          methodName: 'likeVideo',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('likeVideo', e);
      return false;
    }
  }

  Future<bool> buzzVideo(String videoId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/videos/$videoId/buzz/'),
            headers: headers,
          ),
          methodName: 'buzzVideo',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('buzzVideo', e);
      return false;
    }
  }

  Future<bool> shareVideo(String videoId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/videos/$videoId/share/'),
            headers: headers,
          ),
          methodName: 'shareVideo',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('shareVideo', e);
      return false;
    }
  }

  Future<bool> saveVideo(String videoId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/videos/$videoId/save/'),
            headers: headers,
          ),
          methodName: 'saveVideo',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('saveVideo', e);
      return false;
    }
  }

  Future<bool> reportVideo(String videoId, String reason) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/videos/$videoId/report/'),
            headers: headers,
            body: jsonEncode({'reason': reason}),
          ),
          methodName: 'reportVideo',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('reportVideo', e);
      return false;
    }
  }

  // Comments
  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/videos/$videoId/comments/'),
            headers: headers,
          ),
          methodName: 'getComments',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getComments', e);
      return [];
    }
  }

  Future<bool> addComment(String videoId, String text) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/videos/$videoId/add_comment/'),
            headers: headers,
            body: jsonEncode({'text': text}),
          ),
          methodName: 'addComment',
        );

        return response.statusCode == 201;
      });
    } catch (e) {
      _logError('addComment', e);
      return false;
    }
  }

  // Products
  Future<List<ProductItem>> getProducts({String? seller, bool? isPromoted}) async {
    try {
      return await _retryRequest(() async {
        String url = '$_baseUrl/products/';
        final params = <String>[];
        if (seller != null) params.add('seller=$seller');
        if (isPromoted == true) params.add('is_promoted=true');
        if (params.isNotEmpty) url += '?${params.join('&')}';

        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse(url),
            headers: headers,
          ),
          methodName: 'getProducts',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((p) => ProductItem.fromJson(p as Map<String, dynamic>)).toList();
          } else if (data is Map<String, dynamic> && data['results'] != null) {
            return (data['results'] as List)
                .map((p) => ProductItem.fromJson(p as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getProducts', e);
      return [];
    }
  }

  // Create Product
  Future<ProductItem?> createProduct({
    required String name,
    required String description,
    required double price,
    File? imageFile,
    String? imageUrl,
    String? videoUrl,
  }) async {
    try {
      return await _retryRequest(() async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/products/'),
        );

        request.headers.addAll(await _getHeaders());
        request.fields['name'] = name;
        request.fields['description'] = description;
        request.fields['price'] = price.toString();
        if (imageUrl != null) request.fields['image_url'] = imageUrl;
        if (videoUrl != null) request.fields['video_url'] = videoUrl;

        // Add image file if provided
        if (imageFile != null && await imageFile.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image_file',
            imageFile.path,
          ));
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return ProductItem.fromJson(data as Map<String, dynamic>);
        } else {
          _logError('createProduct', 'Failed to create product', statusCode: response.statusCode);
          return null;
        }
      });
    } catch (e) {
      _logError('createProduct', e);
      return null;
    }
  }

  // Update Product
  Future<ProductItem?> updateProduct(String productId, {
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? videoUrl,
  }) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final body = <String, dynamic>{};
        if (name != null) body['name'] = name;
        if (description != null) body['description'] = description;
        if (price != null) body['price'] = price;
        if (imageUrl != null) body['image_url'] = imageUrl;
        if (videoUrl != null) body['video_url'] = videoUrl;

        final response = await _makeRequest(
          () => http.patch(
            Uri.parse('$_baseUrl/products/$productId/'),
            headers: headers,
            body: jsonEncode(body),
          ),
          methodName: 'updateProduct',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return ProductItem.fromJson(data as Map<String, dynamic>);
        }
        return null;
      });
    } catch (e) {
      _logError('updateProduct', e);
      return null;
    }
  }

  // Delete Product
  Future<bool> deleteProduct(String productId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.delete(
            Uri.parse('$_baseUrl/products/$productId/'),
            headers: headers,
          ),
          methodName: 'deleteProduct',
        );

        return response.statusCode == 204 || response.statusCode == 200;
      });
    } catch (e) {
      _logError('deleteProduct', e);
      return false;
    }
  }

  // Battles
  Future<List<Map<String, dynamic>>> getBattles() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/battles/'),
            headers: headers,
          ),
          methodName: 'getBattles',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          } else if (data is Map<String, dynamic> && data['results'] != null) {
            return List<Map<String, dynamic>>.from(data['results']);
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getBattles', e);
      return [];
    }
  }

  Future<bool> voteBattle(String battleId, String votedFor) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/battles/$battleId/vote/'),
            headers: headers,
            body: jsonEncode({'voted_for': votedFor}),
          ),
          methodName: 'voteBattle',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('voteBattle', e);
      return false;
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/notifications/'),
            headers: headers,
          ),
          methodName: 'getNotifications',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          } else if (data is Map<String, dynamic> && data['results'] != null) {
            return List<Map<String, dynamic>>.from(data['results']);
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getNotifications', e);
      return [];
    }
  }

  Future<bool> markNotificationRead(String notificationId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/notifications/$notificationId/mark_read/'),
            headers: headers,
          ),
          methodName: 'markNotificationRead',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('markNotificationRead', e);
      return false;
    }
  }

  // VyRa Points
  Future<List<Map<String, dynamic>>> getVyraPointsTransactions() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/vyra-points/'),
            headers: headers,
          ),
          methodName: 'getVyraPointsTransactions',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getVyraPointsTransactions', e);
      return [];
    }
  }

  Future<int> getVyraPoints() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/vyra-points/total/'),
            headers: headers,
          ),
          methodName: 'getVyraPoints',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['totalPoints'] as int? ?? 0;
        }
        return 0;
      });
    } catch (e) {
      _logError('getVyraPoints', e);
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/vyra-points/leaderboard/'),
            headers: headers,
          ),
          methodName: 'getLeaderboard',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getLeaderboard', e);
      return [];
    }
  }

  // ========== NEW FEATURE METHODS ==========

  // Video Boost
  Future<Map<String, dynamic>> boostVideo(String videoId, String boostType) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/videos/$videoId/boost/'),
            headers: headers,
            body: jsonEncode({'boost_type': boostType}),
          ),
          methodName: 'boostVideo',
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        throw ApiException('Failed to boost video');
      });
    } catch (e) {
      _logError('boostVideo', e);
      rethrow;
    }
  }

  // Nearby Videos (Universe Map)
  Future<List<VideoItem>> getNearbyVideos(double lat, double lng, {double radius = 10.0}) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/videos/nearby/?lat=$lat&lng=$lng&radius=$radius'),
            headers: headers,
          ),
          methodName: 'getNearbyVideos',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((v) => VideoItem.fromJson(v as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getNearbyVideos', e);
      return [];
    }
  }

  // Recommended Videos
  Future<List<VideoItem>> getRecommendedVideos() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/videos/recommended/'),
            headers: headers,
          ),
          methodName: 'getRecommendedVideos',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((v) => VideoItem.fromJson(v as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getRecommendedVideos', e);
      return [];
    }
  }

  // Clubs
  Future<List<Club>> getClubs({String? category}) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final url = category != null 
            ? '$_baseUrl/clubs/?category=$category'
            : '$_baseUrl/clubs/';
        final response = await _makeRequest(
          () => http.get(Uri.parse(url), headers: headers),
          methodName: 'getClubs',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((c) => Club.fromJson(c as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getClubs', e);
      return [];
    }
  }

  Future<Club> createClub(String name, String description, String category) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/clubs/'),
            headers: headers,
            body: jsonEncode({'name': name, 'description': description, 'category': category}),
          ),
          methodName: 'createClub',
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          return Club.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        } else {
          final errorMessage = _parseErrorMessage(response);
          _logError('createClub', errorMessage, statusCode: response.statusCode);
          throw ApiException(errorMessage);
        }
      });
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      _logError('createClub', e);
      rethrow;
    }
  }

  Future<bool> joinClub(String clubId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/clubs/$clubId/join/'),
            headers: headers,
          ),
          methodName: 'joinClub',
        );
        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('joinClub', e);
      return false;
    }
  }

  Future<List<VideoItem>> getClubFeed(String clubId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/clubs/$clubId/feed/'),
            headers: headers,
          ),
          methodName: 'getClubFeed',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((v) => VideoItem.fromJson(v as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getClubFeed', e);
      return [];
    }
  }

  // Challenges
  Future<List<Challenge>> getChallenges() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(Uri.parse('$_baseUrl/challenges/'), headers: headers),
          methodName: 'getChallenges',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((c) => Challenge.fromJson(c as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getChallenges', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> claimChallenge(String challengeId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/challenges/$challengeId/claim/'),
            headers: headers,
          ),
          methodName: 'claimChallenge',
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        throw ApiException('Failed to claim challenge');
      });
    } catch (e) {
      _logError('claimChallenge', e);
      rethrow;
    }
  }

  // Sounds
  Future<List<Sound>> getSounds({String? search}) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final url = search != null 
            ? '$_baseUrl/sounds/?search=$search'
            : '$_baseUrl/sounds/';
        final response = await _makeRequest(
          () => http.get(Uri.parse(url), headers: headers),
          methodName: 'getSounds',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((s) => Sound.fromJson(s as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getSounds', e);
      return [];
    }
  }

  // Profile Skins
  Future<List<ProfileSkin>> getProfileSkins() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(Uri.parse('$_baseUrl/profile-skins/'), headers: headers),
          methodName: 'getProfileSkins',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((s) => ProfileSkin.fromJson(s as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getProfileSkins', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> purchaseSkin(String skinId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/profile-skins/$skinId/purchase/'),
            headers: headers,
          ),
          methodName: 'purchaseSkin',
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        throw ApiException('Failed to purchase skin');
      });
    } catch (e) {
      _logError('purchaseSkin', e);
      rethrow;
    }
  }

  Future<bool> activateSkin(String skinId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/profile-skins/$skinId/activate/'),
            headers: headers,
          ),
          methodName: 'activateSkin',
        );
        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('activateSkin', e);
      return false;
    }
  }

  // Blocking
  Future<bool> blockUser(String userId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/blocks/'),
            headers: headers,
            body: jsonEncode({'blocked': userId}),
          ),
          methodName: 'blockUser',
        );
        return response.statusCode == 201 || response.statusCode == 200;
      });
    } catch (e) {
      _logError('blockUser', e);
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/blocks/unblock/'),
            headers: headers,
            body: jsonEncode({'blocked_id': userId}),
          ),
          methodName: 'unblockUser',
        );
        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('unblockUser', e);
      return false;
    }
  }

  // Video Analytics
  Future<List<VideoAnalytics>> getMyAnalytics() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/video-analytics/my_analytics/'),
            headers: headers,
          ),
          methodName: 'getMyAnalytics',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((a) => VideoAnalytics.fromJson(a as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getMyAnalytics', e);
      return [];
    }
  }

  // Status/Stories
  Future<List<StatusItem>> getStatuses({String? userId}) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final url = userId != null 
            ? '$_baseUrl/statuses/?user=$userId'
            : '$_baseUrl/statuses/';
        final response = await _makeRequest(
          () => http.get(Uri.parse(url), headers: headers),
          methodName: 'getStatuses',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((s) => StatusItem.fromJson(s as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getStatuses', e);
      return [];
    }
  }

  Future<bool> viewStatus(String statusId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/statuses/$statusId/view/'),
            headers: headers,
          ),
          methodName: 'viewStatus',
        );
        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('viewStatus', e);
      return false;
    }
  }

  // Products - Purchase
  Future<Map<String, dynamic>> purchaseProduct(String productId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/products/$productId/purchase/'),
            headers: headers,
          ),
          methodName: 'purchaseProduct',
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        throw ApiException('Failed to purchase product: ${response.statusCode}');
      });
    } catch (e) {
      _logError('purchaseProduct', e);
      rethrow;
    }
  }

  // Product Boost
  Future<Map<String, dynamic>> boostProduct(String productId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/products/$productId/boost/'),
            headers: headers,
          ),
          methodName: 'boostProduct',
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        throw ApiException('Failed to boost product');
      });
    } catch (e) {
      _logError('boostProduct', e);
      rethrow;
    }
  }

  // Live Rooms
  Future<List<LiveRoom>> getLiveRooms() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(Uri.parse('$_baseUrl/live-rooms/'), headers: headers),
          methodName: 'getLiveRooms',
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return (data as List).map((r) => LiveRoom.fromJson(r as Map<String, dynamic>)).toList();
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getLiveRooms', e);
      return [];
    }
  }

  Future<LiveRoom> createLiveRoom(String title, String description) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/live-rooms/'),
            headers: headers,
            body: jsonEncode({'title': title, 'description': description}),
          ),
          methodName: 'createLiveRoom',
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          return LiveRoom.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        }
        throw ApiException('Failed to create live room');
      });
    } catch (e) {
      _logError('createLiveRoom', e);
      rethrow;
    }
  }

  Future<bool> startLiveRoom(String roomId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/live-rooms/$roomId/start/'),
            headers: headers,
          ),
          methodName: 'startLiveRoom',
        );
        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('startLiveRoom', e);
      return false;
    }
  }

  // Get current user ID helper
  String? getCurrentUserId() {
    // This would need to be implemented based on how you store current user
    // For now, return null - can be enhanced later
    return null;
  }

  // Chats
  Future<List<Map<String, dynamic>>> getChats() async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/chats/'),
            headers: headers,
          ),
          methodName: 'getChats',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          } else if (data is Map<String, dynamic> && data['results'] != null) {
            return List<Map<String, dynamic>>.from(data['results']);
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getChats', e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrCreateChat(String userId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/chats/get_or_create/'),
            headers: headers,
            body: jsonEncode({'user_id': userId}),
          ),
          methodName: 'getOrCreateChat',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        return null;
      });
    } catch (e) {
      _logError('getOrCreateChat', e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.get(
            Uri.parse('$_baseUrl/chats/$chatId/messages/'),
            headers: headers,
          ),
          methodName: 'getChatMessages',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
        return [];
      });
    } catch (e) {
      _logError('getChatMessages', e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendMessage(String chatId, String message) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/chats/$chatId/send_message/'),
            headers: headers,
            body: jsonEncode({'message': message}),
          ),
          methodName: 'sendMessage',
        );

        if (response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        return null;
      });
    } catch (e) {
      _logError('sendMessage', e);
      return null;
    }
  }

  Future<bool> markChatAsRead(String chatId) async {
    try {
      return await _retryRequest(() async {
        final headers = await _getHeaders();
        final response = await _makeRequest(
          () => http.post(
            Uri.parse('$_baseUrl/chats/$chatId/mark_read/'),
            headers: headers,
          ),
          methodName: 'markChatAsRead',
        );

        return response.statusCode == 200;
      });
    } catch (e) {
      _logError('markChatAsRead', e);
      return false;
    }
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}
