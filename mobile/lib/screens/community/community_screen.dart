// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/theme_provider.dart';
import '../../services/community_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _timeAgo(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  } catch (_) {
    return '';
  }
}

const _langOptions = [
  _LangFilter(code: 'all', label: 'All'),
  _LangFilter(code: 'en', label: 'English'),
  _LangFilter(code: 'si', label: 'සිංහල'),
  _LangFilter(code: 'ta', label: 'தமிழ்'),
];

class _LangFilter {
  final String code;
  final String label;
  const _LangFilter({required this.code, required this.label});
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen>
    with SingleTickerProviderStateMixin {
  final _repo = CommunityRepository();
  final _supabase = SupabaseConfig.client;
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _feedPosts = [];
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoadingFeed = true;
  bool _isLoadingMine = false;
  String? _currentUserId;
  String? _currentUserName;
  String _selectedLang = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(_onTabChange);
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadUserName();
    _loadFeed();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabCtrl.indexIsChanging) return;
    if (_tabCtrl.index == 1) _loadMyPosts();
  }

  Future<void> _loadUserName() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;
      final profile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() => _currentUserName = profile?['full_name'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _loadFeed() async {
    if (mounted) setState(() => _isLoadingFeed = true);
    final posts = await _repo.getPosts(language: _selectedLang);
    if (mounted) {
      setState(() {
        _feedPosts = posts;
        _isLoadingFeed = false;
      });
    }
  }

  Future<void> _loadMyPosts() async {
    if (mounted) setState(() => _isLoadingMine = true);
    final posts = await _repo.getMyPosts();
    if (mounted) {
      setState(() {
        _myPosts = posts;
        _isLoadingMine = false;
      });
    }
  }

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(
        userId: _currentUserId ?? '',
        userName: _currentUserName ?? 'You',
        isDark: _isDark,
        repo: _repo,
        onPosted: () {
          _loadFeed();
          if (_tabCtrl.index == 1) _loadMyPosts();
        },
      ),
    );
  }

  // ── Theme helpers ─────────────────────────────────────────────────────────

  bool get _isDark => context.watch<ThemeProvider>().isDark;

  Color get _bg =>
      _isDark ? FemoraColors.darkBackground : FemoraColors.lightBackgroundTint;

  Color get _card => _isDark ? FemoraColors.darkSurface : Colors.white;

  Color get _textPrimary =>
      _isDark ? FemoraColors.darkTextPrimary : FemoraColors.textPrimary;

  Color get _textSecondary =>
      _isDark ? FemoraColors.darkTextSecondary : FemoraColors.textSecondary;

  Color get _divider =>
      _isDark ? FemoraColors.darkBorder : FemoraColors.lavenderWhisper;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildLangFilter(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFeedTab(),
                _buildMyPostsTab(),
              ],
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        backgroundColor: FemoraColors.primary,
        elevation: 4,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Community',
          style: FemoraTextStyles.headlineLarge.copyWith(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildLangFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _langOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = _langOptions[i];
          final selected = _selectedLang == opt.code;
          return GestureDetector(
            onTap: () {
              if (_selectedLang == opt.code) return;
              setState(() => _selectedLang = opt.code);
              _loadFeed();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? FemoraColors.primary
                    : (_isDark
                        ? FemoraColors.darkSurfaceRaised
                        : FemoraColors.lavenderWhisper),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt.label,
                style: FemoraTextStyles.caption.copyWith(
                  color: selected ? Colors.white : _textSecondary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      decoration: BoxDecoration(
        color: _isDark
            ? FemoraColors.darkSurfaceRaised
            : FemoraColors.lavenderWhisper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: FemoraColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle:
            FemoraTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: FemoraTextStyles.bodyMedium,
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'My Posts'),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isLoadingFeed) {
      return const Center(
          child: CircularProgressIndicator(color: FemoraColors.primary));
    }
    if (_feedPosts.isEmpty) {
      return _empty(
        icon: Icons.groups_outlined,
        title: 'No posts yet',
        subtitle: 'Be the first to start a conversation.',
      );
    }
    return RefreshIndicator(
      color: FemoraColors.primary,
      onRefresh: _loadFeed,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _feedPosts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PostCard(
          post: _feedPosts[i],
          currentUserId: _currentUserId,
          isDark: _isDark,
          cardColor: _card,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          dividerColor: _divider,
          repo: _repo,
          onDeleted: _loadFeed,
          onRefresh: _loadFeed,
        ),
      ),
    );
  }

  Widget _buildMyPostsTab() {
    if (_isLoadingMine) {
      return const Center(
          child: CircularProgressIndicator(color: FemoraColors.primary));
    }
    if (_myPosts.isEmpty) {
      return _empty(
        icon: Icons.edit_outlined,
        title: 'No posts yet',
        subtitle: 'Tap the pen button to share something.',
      );
    }
    return RefreshIndicator(
      color: FemoraColors.primary,
      onRefresh: _loadMyPosts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _myPosts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PostCard(
          post: _myPosts[i],
          currentUserId: _currentUserId,
          isDark: _isDark,
          cardColor: _card,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          dividerColor: _divider,
          repo: _repo,
          onDeleted: _loadMyPosts,
          onRefresh: _loadMyPosts,
        ),
      ),
    );
  }

  Widget _empty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: FemoraColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: FemoraColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: FemoraTextStyles.titleLarge
                  .copyWith(color: _textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:
                  FemoraTextStyles.bodyMedium.copyWith(color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.repo,
    required this.onDeleted,
    required this.onRefresh,
  });

  final Map<String, dynamic> post;
  final String? currentUserId;
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final CommunityRepository repo;
  final VoidCallback onDeleted;
  final VoidCallback onRefresh;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked;
  late int _likeCount;
  late int _commentCount;
  bool _expanded = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likeCount = (widget.post['likes_count'] as num?)?.toInt() ?? 0;
    _commentCount = (widget.post['comments_count'] as num?)?.toInt() ?? 0;
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final liked =
        await widget.repo.isLikedByMe(widget.post['id'] as String);
    if (mounted) setState(() => _liked = liked);
  }

  Future<void> _toggleLike() async {
    if (_toggling) return;
    HapticFeedback.lightImpact();
    final wasLiked = _liked;
    setState(() {
      _toggling = true;
      _liked = !_liked;
      _likeCount = (_likeCount + (_liked ? 1 : -1)).clamp(0, 999999);
    });
    try {
      final nowLiked =
          await widget.repo.toggleLike(widget.post['id'] as String);
      if (mounted) setState(() => _liked = nowLiked);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount = (_likeCount + (wasLiked ? 1 : -1)).clamp(0, 999999);
        });
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Post',
            style: FemoraTextStyles.titleLarge.copyWith(
              color: widget.textPrimary,
              fontWeight: FontWeight.w700,
            )),
        content: Text(
          'This post will be permanently deleted.',
          style: FemoraTextStyles.bodyMedium
              .copyWith(color: widget.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: TextStyle(color: widget.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: FemoraColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.repo.deletePost(widget.post['id'] as String);
      widget.onDeleted();
    }
  }

  Future<void> _report() async {
    const reasons = [
      'Spam or misleading',
      'Harassment or bullying',
      'Inappropriate content',
      'Misinformation',
      'Other',
    ];
    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Report Post',
              style: FemoraTextStyles.titleLarge.copyWith(
                color: widget.textPrimary,
                fontWeight: FontWeight.w700,
              )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Why are you reporting this post?',
                  style: FemoraTextStyles.bodyMedium
                      .copyWith(color: widget.textSecondary)),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (v) =>
                        setDialogState(() => selectedReason = v),
                    title: Text(r,
                        style: FemoraTextStyles.bodyMedium
                            .copyWith(color: widget.textPrimary)),
                    activeColor: FemoraColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(color: widget.textSecondary)),
            ),
            TextButton(
              onPressed: selectedReason != null
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Report',
                  style: TextStyle(color: FemoraColors.error)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedReason != null && mounted) {
      try {
        await widget.repo.reportPost(
          postId: widget.post['id'] as String,
          reason: selectedReason!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Post reported. Thank you for keeping the community safe.'),
            backgroundColor: FemoraColors.success,
          ));
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Already reported this post.'),
            backgroundColor: FemoraColors.warning,
          ));
        }
      }
    }
  }

  Future<void> _showAuthorInfo() async {
    final post = widget.post;
    final isAnon = post['is_anonymous'] as bool? ?? false;
    if (isAnon) return;

    final userId = post['user_id'] as String?;
    final authorName = post['author_name'] as String? ?? 'Unknown';

    int postCount = 0;
    if (userId != null) {
      try {
        postCount = await widget.repo.getUserPostCount(userId);
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: widget.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: FemoraColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: FemoraTextStyles.headlineLarge.copyWith(
                    color: FemoraColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              authorName,
              style: FemoraTextStyles.titleLarge.copyWith(
                color: widget.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$postCount post${postCount == 1 ? '' : 's'} in the community',
              style: FemoraTextStyles.bodyMedium
                  .copyWith(color: widget.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _share() {
    final post = widget.post;
    final isAnon = post['is_anonymous'] as bool? ?? false;
    final author = isAnon
        ? (post['anonymous_alias'] as String? ?? 'Anonymous')
        : (post['author_name'] as String? ?? 'Someone');
    final content = post['content'] as String? ?? '';
    final category = post['category'] as String?;

    final text = StringBuffer();
    text.writeln('${category != null ? "[$category] " : ""}$content');
    text.writeln();
    text.writeln('— Shared from Femora Community');

    Share.share(text.toString(), subject: 'Post by $author on Femora');
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: widget.post,
        isDark: widget.isDark,
        currentUserId: widget.currentUserId,
        repo: widget.repo,
        onCommentAdded: () {
          if (mounted) setState(() => _commentCount++);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isAnon = post['is_anonymous'] as bool? ?? false;
    final authorName = isAnon
        ? (post['anonymous_alias'] as String? ?? 'Anonymous')
        : (post['author_name'] as String? ?? 'Unknown');
    final initials =
        isAnon ? '?' : (authorName.isNotEmpty ? authorName[0].toUpperCase() : '?');
    final category = post['category'] as String?;
    final content = post['content'] as String? ?? '';
    final imageUrl = post['image_url'] as String?;
    final isOwn = post['user_id'] == widget.currentUserId;
    final lang = post['language'] as String?;

    return Container(
      decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.isDark
              ? []
              : [
                  BoxShadow(
                    color: FemoraColors.primary.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name (tappable)
                  Expanded(
                    child: GestureDetector(
                      onTap: _showAuthorInfo,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isAnon
                                  ? (widget.isDark
                                      ? FemoraColors.darkLavender
                                      : FemoraColors.lavenderWhisper)
                                  : FemoraColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: FemoraTextStyles.bodyMedium.copyWith(
                                  color: FemoraColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  overflow: TextOverflow.ellipsis,
                                  style: FemoraTextStyles.bodyMedium.copyWith(
                                    color: widget.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Text(
                                      _timeAgo(post['created_at'] as String?),
                                      style: FemoraTextStyles.caption.copyWith(
                                          color: widget.textSecondary),
                                    ),
                                    if (lang != null && lang != 'en')
                                      _chip(lang.toUpperCase()),
                                    if (category != null) _chip(category),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // More menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded,
                        color: widget.textSecondary, size: 20),
                    color: widget.cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'delete') _delete();
                      if (value == 'report') _report();
                    },
                    itemBuilder: (_) => [
                      if (isOwn)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            const Icon(Icons.delete_outline_rounded,
                                color: FemoraColors.error, size: 18),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: FemoraTextStyles.bodyMedium
                                    .copyWith(color: FemoraColors.error)),
                          ]),
                        ),
                      if (!isOwn)
                        PopupMenuItem(
                          value: 'report',
                          child: Row(children: [
                            Icon(Icons.flag_outlined,
                                color: widget.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Text('Report',
                                style: FemoraTextStyles.bodyMedium
                                    .copyWith(color: widget.textPrimary)),
                          ]),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    maxLines: _expanded ? null : 4,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: FemoraTextStyles.bodyMedium.copyWith(
                      color: widget.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (content.length > 200)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _expanded ? 'Show less' : 'Read more',
                          style: FemoraTextStyles.caption.copyWith(
                            color: FemoraColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Image ─────────────────────────────────────────────────
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenImage(imageUrl: imageUrl),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  headers: const {
                    'Cache-Control': 'no-cache',
                  },
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 220,
                      color: widget.isDark
                          ? FemoraColors.darkSurfaceRaised
                          : FemoraColors.lavenderWhisper,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: FemoraColors.primary, strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, error, _) {
                    debugPrint('Image load error: $error');
                    return Container(
                      height: 80,
                      color: widget.isDark
                          ? FemoraColors.darkSurfaceRaised
                          : FemoraColors.lavenderWhisper,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: widget.textSecondary),
                      ),
                    );
                  },
                ),
              ),
            ),
            ] else
              const SizedBox(height: 10),

            // ── Actions ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(children: [
                // Like button
                GestureDetector(
                  onTap: _toggleLike,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      Icon(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        size: 26,
                        color: _liked
                            ? FemoraColors.error
                            : widget.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_likeCount',
                        style: FemoraTextStyles.bodyMedium.copyWith(
                          color: widget.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 4),
                // Comment button
                GestureDetector(
                  onTap: _openComments,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 26,
                        color: widget.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_commentCount',
                        style: FemoraTextStyles.bodyMedium.copyWith(
                          color: widget.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),
                const Spacer(),
                // Share button — inline, right side
                GestureDetector(
                  onTap: _share,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.share_outlined,
                      size: 24,
                      color: widget.textSecondary,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: FemoraColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: FemoraTextStyles.caption.copyWith(
          color: FemoraColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Comments Sheet ────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.post,
    required this.isDark,
    required this.currentUserId,
    required this.repo,
    required this.onCommentAdded,
  });

  final Map<String, dynamic> post;
  final bool isDark;
  final String? currentUserId;
  final CommunityRepository repo;
  final VoidCallback onCommentAdded;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  bool _isAnon = false;

  Color get _bg =>
      widget.isDark ? FemoraColors.darkSurface : Colors.white;
  Color get _textPrimary => widget.isDark
      ? FemoraColors.darkTextPrimary
      : FemoraColors.textPrimary;
  Color get _textSecondary => widget.isDark
      ? FemoraColors.darkTextSecondary
      : FemoraColors.textSecondary;
  Color get _inputBg => widget.isDark
      ? FemoraColors.darkSurfaceRaised
      : FemoraColors.lightBackgroundTint;
  Color get _divider =>
      widget.isDark ? FemoraColors.darkBorder : FemoraColors.lavenderWhisper;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final comments =
        await widget.repo.getComments(widget.post['id'] as String);
    if (mounted) {
      setState(() {
        _comments = comments;
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.repo.addComment(
        postId: widget.post['id'] as String,
        content: text,
        isAnonymous: _isAnon,
      );
      _ctrl.clear();
      _focusNode.unfocus();
      widget.onCommentAdded();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: FemoraColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.93,
          builder: (_, scrollCtrl) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Comments',
                        style: FemoraTextStyles.titleLarge.copyWith(
                          color: _textPrimary,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ),
                Divider(color: _divider, height: 1),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: FemoraColors.primary))
                      : _comments.isEmpty
                          ? Center(
                              child: Text(
                                'No comments yet. Be the first!',
                                style: FemoraTextStyles.bodyMedium
                                    .copyWith(color: _textSecondary),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: _comments.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final c = _comments[i];
                                final isAnon =
                                    c['is_anonymous'] as bool? ?? false;
                                final name = isAnon
                                    ? 'Anonymous'
                                    : (c['author_name'] as String? ??
                                        'Unknown');
                                final initials = isAnon
                                    ? '?'
                                    : (name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?');
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: FemoraColors.primary
                                            .withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(initials,
                                            style: FemoraTextStyles.caption
                                                .copyWith(
                                              color: FemoraColors.primary,
                                              fontWeight: FontWeight.w700,
                                            )),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Text(name,
                                                style: FemoraTextStyles
                                                    .caption
                                                    .copyWith(
                                                  color: _textPrimary,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                )),
                                            const SizedBox(width: 8),
                                            Text(
                                              _timeAgo(c['created_at']
                                                  as String?),
                                              style: FemoraTextStyles
                                                  .caption
                                                  .copyWith(
                                                      color: _textSecondary),
                                            ),
                                          ]),
                                          const SizedBox(height: 2),
                                          Text(
                                            c['content'] as String? ?? '',
                                            style: FemoraTextStyles
                                                .bodyMedium
                                                .copyWith(
                                                    color: _textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
                // Input area — always visible above keyboard
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border(top: BorderSide(color: _divider)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Text('Post anonymously',
                            style: FemoraTextStyles.caption
                                .copyWith(color: _textSecondary)),
                        const Spacer(),
                        Switch(
                          value: _isAnon,
                          onChanged: (v) => setState(() => _isAnon = v),
                          activeColor: FemoraColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focusNode,
                            textCapitalization:
                                TextCapitalization.sentences,
                            style: FemoraTextStyles.bodyMedium
                                .copyWith(color: _textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: FemoraTextStyles.bodyMedium
                                  .copyWith(color: _textSecondary),
                              filled: true,
                              fillColor: _inputBg,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: FemoraColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ── Create Post Sheet ─────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({
    required this.userId,
    required this.userName,
    required this.isDark,
    required this.repo,
    required this.onPosted,
  });

  final String userId;
  final String userName;
  final bool isDark;
  final CommunityRepository repo;
  final VoidCallback onPosted;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();
  bool _isAnon = false;
  bool _posting = false;
  bool _uploadingImage = false;
  String? _selectedCategory;
  File? _pickedImage;
  String? _uploadedImageUrl;
  String _selectedLang = 'en';

  static const _postLangs = [
    _LangFilter(code: 'en', label: 'English'),
    _LangFilter(code: 'si', label: 'සිංහල'),
    _LangFilter(code: 'ta', label: 'தமிழ்'),
  ];

  static const _categories = [
    'Mental Health',
    'Relationships',
    'Pregnancy',
    'Period',
    'General',
    'Safety',
  ];

  Color get _bg =>
      widget.isDark ? FemoraColors.darkSurface : Colors.white;
  Color get _textPrimary => widget.isDark
      ? FemoraColors.darkTextPrimary
      : FemoraColors.textPrimary;
  Color get _textSecondary => widget.isDark
      ? FemoraColors.darkTextSecondary
      : FemoraColors.textSecondary;
  Color get _inputBg => widget.isDark
      ? FemoraColors.darkSurfaceRaised
      : FemoraColors.lightBackgroundTint;
  Color get _divider =>
      widget.isDark ? FemoraColors.darkBorder : FemoraColors.lavenderWhisper;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    debugPrint('_pickImage: picked=${picked?.path}');
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _pickedImage = file;
      _uploadedImageUrl = null;
      _uploadingImage = true;
    });
    debugPrint('Starting image upload...');
    final url = await widget.repo.uploadImage(file);
    debugPrint('Image upload result: $url');
    if (mounted) {
      setState(() {
        _uploadedImageUrl = url;
        _uploadingImage = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _posting || _uploadingImage) return;
    setState(() => _posting = true);
    debugPrint('_post called. uploadedImageUrl: $_uploadedImageUrl');
    try {
      await widget.repo.createPost(
        content: text,
        isAnonymous: _isAnon,
        category: _selectedCategory,
        imageUrl: _uploadedImageUrl,
        language: _selectedLang,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onPosted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to post: $e'),
          backgroundColor: FemoraColors.error,
        ));
        setState(() => _posting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alias = widget.repo.generateAlias(widget.userId);
    final charCount = _ctrl.text.length;
    final canPost =
        charCount > 0 && charCount <= 500 && !_uploadingImage;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(children: [
                Text(
                  'New Post',
                  style: FemoraTextStyles.titleLarge.copyWith(
                      color: _textPrimary, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child:
                      Icon(Icons.close_rounded, color: _textSecondary),
                ),
              ]),
              const SizedBox(height: 16),
              // Text input
              TextField(
                controller: _ctrl,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                style:
                    FemoraTextStyles.bodyLarge.copyWith(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Share something with the community...',
                  hintStyle: FemoraTextStyles.bodyLarge
                      .copyWith(color: _textSecondary),
                  filled: true,
                  fillColor: _inputBg,
                  counterStyle: FemoraTextStyles.caption
                      .copyWith(color: _textSecondary),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Image picker
              if (_pickedImage != null) ...[
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _pickedImage!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_uploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  if (_uploadedImageUrl != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FemoraColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Uploaded',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ]),
                const SizedBox(height: 12),
              ] else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _divider),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              color: FemoraColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Add image',
                              style: FemoraTextStyles.bodyMedium.copyWith(
                                  color: FemoraColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ),
                ),
              const SizedBox(height: 16),
              // Language selector
              Text('Post language',
                  style: FemoraTextStyles.bodyMedium.copyWith(
                      color: _textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: _postLangs.map((lang) {
                  final selected = _selectedLang == lang.code;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLang = lang.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? FemoraColors.primary : _inputBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(lang.label,
                            style: FemoraTextStyles.caption.copyWith(
                              color: selected ? Colors.white : _textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Category chips
              Text('Category',
                  style: FemoraTextStyles.bodyMedium.copyWith(
                      color: _textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedCategory = selected ? null : cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? FemoraColors.primary
                            : (widget.isDark
                                ? FemoraColors.darkSurfaceRaised
                                : FemoraColors.lavenderWhisper),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: FemoraTextStyles.caption.copyWith(
                          color: selected
                              ? Colors.white
                              : FemoraColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Anonymous toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAnon
                              ? 'Posting as "$alias"'
                              : 'Posting as "${widget.userName}"',
                          style: FemoraTextStyles.bodyMedium.copyWith(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _isAnon
                              ? 'Your identity is hidden'
                              : 'Your name will be visible',
                          style: FemoraTextStyles.caption
                              .copyWith(color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnon,
                    onChanged: (v) => setState(() => _isAnon = v),
                    activeColor: FemoraColors.primary,
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              // Post button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canPost && !_posting ? _post : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemoraColors.primary,
                    disabledBackgroundColor:
                        FemoraColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _posting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _uploadingImage
                              ? 'Uploading image...'
                              : 'Post',
                          style: FemoraTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full Screen Image Viewer ──────────────────────────────────────────────────

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                        color: FemoraColors.primary),
                  );
                },
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
