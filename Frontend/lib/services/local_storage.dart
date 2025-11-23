import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_item.dart';
import '../models/product_item.dart';
import '../models/user_profile.dart';

class LocalStorageService {
  static const String _videosKey = 'videos';
  static const String _productsKey = 'products';
  static const String _userProfileKey = 'user_profile';
  static const String _vyraPointsKey = 'vyra_points';
  static const String _themeKey = 'theme_accent';

  // Videos
  Future<List<VideoItem>> getVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final videosJson = prefs.getStringList(_videosKey) ?? [];
    return videosJson
        .map((json) => VideoItem.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveVideos(List<VideoItem> videos) async {
    final prefs = await SharedPreferences.getInstance();
    final videosJson = videos.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_videosKey, videosJson);
  }

  Future<void> addVideo(VideoItem video) async {
    final videos = await getVideos();
    videos.add(video);
    await saveVideos(videos);
  }

  Future<void> updateVideo(VideoItem video) async {
    final videos = await getVideos();
    final index = videos.indexWhere((v) => v.id == video.id);
    if (index != -1) {
      videos[index] = video;
      await saveVideos(videos);
    }
  }

  // Products
  Future<List<ProductItem>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getStringList(_productsKey) ?? [];
    return productsJson
        .map((json) => ProductItem.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveProducts(List<ProductItem> products) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_productsKey, productsJson);
  }

  Future<void> addProduct(ProductItem product) async {
    final products = await getProducts();
    products.add(product);
    await saveProducts(products);
  }

  // User Profile
  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    if (profileJson == null) return null;
    return UserProfile.fromJson(jsonDecode(profileJson));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profile.toJson()));
  }

  // VyRa Points
  Future<int> getVyraPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_vyraPointsKey) ?? 0;
  }

  Future<void> addVyraPoints(int points) async {
    final current = await getVyraPoints();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vyraPointsKey, current + points);
  }

  Future<void> setVyraPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vyraPointsKey, points);
  }

  // Theme
  Future<String?> getThemeAccent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  Future<void> setThemeAccent(String accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, accent);
  }
}

