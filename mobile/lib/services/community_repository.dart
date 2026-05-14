// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// CommunityRepository
/// ────────────────────
/// All Supabase reads/writes for Community module.
class CommunityRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Alias ─────────────────────────────────────────────────────────────────

  String generateAlias(String userId) {
    const adjectives = [
      'Brave', 'Quiet', 'Gentle', 'Warm', 'Bright',
      'Calm', 'Kind', 'Bold', 'Soft', 'Clear',
      'Wise', 'Pure', 'Tender', 'Serene', 'Lively',
    ];
    const nouns = [
      'Lotus', 'Moon', 'River', 'Star', 'Garden',
      'Breeze', 'Pearl', 'Dawn', 'Rose', 'Light',
      'Fern', 'Cloud', 'Ember', 'Sage', 'Lily',
    ];
    final hash = userId.hashCode.abs();
    return '${adjectives[hash % adjectives.length]} '
        '${nouns[(hash ~/ 10) % nouns.length]}';
  }

  // ── Image Upload ──────────────────────────────────────────────────────────

  /// Uploads image to Supabase Storage.
  /// Returns the public URL or null on failure.
  Future<String?> uploadImage(File imageFile) async {
    try {
      final userId = _userId;
      debugPrint('uploadImage called. userId: $userId, file: ${imageFile.path}');
      if (userId == null) return null;

      final ext = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      debugPrint('Uploading to path: $fileName');

      await _supabase.storage.from('community-images').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      debugPrint('Upload complete. Getting public URL...');

      final url = _supabase.storage
          .from('community-images')
          .getPublicUrl(fileName);

      // Strip query params that can cause display issues
      final cleanUrl = url.contains('?') ? url.split('?')[0] : url;
      debugPrint('Uploaded image URL: $cleanUrl');
      return cleanUrl;
    } catch (e) {
      debugPrint('uploadImage ERROR: $e');
      return null;
    }
  }

  // ── Posts ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPosts({
    int limit = 20,
    int offset = 0,
    String? language,
  }) async {
    try {
      var filter = _supabase
          .from('community_posts')
          .select(
            'id, content, image_url, is_anonymous, anonymous_alias, '
            'likes_count, comments_count, created_at, user_id, category, language',
          );

      if (language != null && language != 'all') {
        filter = filter.eq('language', language);
      }

      final response = await filter
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final posts = List<Map<String, dynamic>>.from(response);

      // Collect non-anonymous user IDs and fetch their names
      final userIds = posts
          .where((p) => !(p['is_anonymous'] as bool? ?? false))
          .map((p) => p['user_id'] as String)
          .toSet()
          .toList();

      Map<String, String> nameMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profiles = await _supabase
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', userIds);
          for (final p in (profiles as List)) {
            nameMap[p['id'] as String] = p['full_name'] as String? ?? '';
          }
        } catch (_) {}
      }

      return posts.map((post) {
        final isAnon = post['is_anonymous'] as bool? ?? false;
        return {
          ...post,
          'author_name': isAnon ? null : nameMap[post['user_id']],
        };
      }).toList();
    } catch (e) {
      debugPrint('CommunityRepository.getPosts error: $e');
      return [];
    }
  }

  Future<void> createPost({
    required String content,
    required bool isAnonymous,
    String? category,
    String? imageUrl,
    String language = 'en',
  }) async {
    try {
      final userId = _userId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('community_posts').insert({
        'user_id': userId,
        'content': content.trim(),
        'is_anonymous': isAnonymous,
        'anonymous_alias': isAnonymous ? generateAlias(userId) : null,
        'category': category,
        'image_url': imageUrl,
        'likes_count': 0,
        'comments_count': 0,
        'language': language,
      });
    } catch (e) {
      debugPrint('CommunityRepository.createPost error: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final userId = _userId;
      if (userId == null) throw Exception('User not authenticated');
      await _supabase
          .from('community_posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('CommunityRepository.deletePost error: $e');
      rethrow;
    }
  }

  // ── Likes ─────────────────────────────────────────────────────────────────

  Future<bool> toggleLike(String postId) async {
    try {
      final userId = _userId;
      if (userId == null) throw Exception('User not authenticated');

      final existing = await _supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        await _supabase.rpc('decrement_likes',
            params: {'post_id': postId});
        return false;
      } else {
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
        await _supabase.rpc('increment_likes',
            params: {'post_id': postId});
        return true;
      }
    } catch (e) {
      debugPrint('CommunityRepository.toggleLike error: $e');
      rethrow;
    }
  }

  Future<bool> isLikedByMe(String postId) async {
    try {
      final userId = _userId;
      if (userId == null) return false;
      final result = await _supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('id, content, is_anonymous, created_at, user_id')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final comments = List<Map<String, dynamic>>.from(response);

      final userIds = comments
          .where((c) => !(c['is_anonymous'] as bool? ?? false))
          .map((c) => c['user_id'] as String)
          .toSet()
          .toList();

      Map<String, String> nameMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profiles = await _supabase
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', userIds);
          for (final p in (profiles as List)) {
            nameMap[p['id'] as String] = p['full_name'] as String? ?? '';
          }
        } catch (_) {}
      }

      return comments.map((c) {
        final isAnon = c['is_anonymous'] as bool? ?? false;
        return {
          ...c,
          'author_name': isAnon ? null : nameMap[c['user_id']],
        };
      }).toList();
    } catch (e) {
      debugPrint('CommunityRepository.getComments error: $e');
      return [];
    }
  }

  Future<void> addComment({
    required String postId,
    required String content,
    required bool isAnonymous,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) throw Exception('User not authenticated');
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content.trim(),
        'is_anonymous': isAnonymous,
      });
      await _supabase.rpc('increment_comments',
          params: {'post_id': postId});
    } catch (e) {
      debugPrint('CommunityRepository.addComment error: $e');
      rethrow;
    }
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) throw Exception('User not authenticated');
      await _supabase.from('post_reports').insert({
        'post_id': postId,
        'reporter_id': userId,
        'reason': reason,
      });
    } catch (e) {
      debugPrint('CommunityRepository.reportPost error: $e');
      rethrow;
    }
  }

  // ── User stats ───────────────────────────────────────────────────────────

  Future<int> getUserPostCount(String userId) async {
    try {
      final result = await _supabase
          .from('community_posts')
          .select('id')
          .eq('user_id', userId);
      return (result as List).length;
    } catch (e) {
      debugPrint('getUserPostCount error: $e');
      return 0;
    }
  }

  // ── My posts ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyPosts() async {
    try {
      final userId = _userId;
      if (userId == null) return [];
      final response = await _supabase
          .from('community_posts')
          .select(
            'id, content, image_url, is_anonymous, anonymous_alias, '
            'likes_count, comments_count, created_at, user_id, '
            'category, language, profiles(full_name)',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response).map((post) {
        final isAnon = post['is_anonymous'] as bool? ?? false;
        final profileName =
            (post['profiles'] as Map<String, dynamic>?)?['full_name']
                as String?;
        return {
          ...post,
          'author_name': isAnon ? null : profileName,
        };
      }).toList();
    } catch (e) {
      debugPrint('CommunityRepository.getMyPosts error: $e');
      return [];
    }
  }
}
