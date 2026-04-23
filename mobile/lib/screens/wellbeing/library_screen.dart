// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/mental_repository.dart';
import '../../config/supabase_config.dart';

/// Library Screen
/// ───────────────
/// Articles fetched from Supabase library_articles table.
/// Save to mental_saved_articles. Share via system share sheet.
/// Search by title/summary. Filter by category.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repo = MentalRepository();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = 'all';
  String _searchQuery = '';
  List<Map<String, dynamic>> _articles = [];
  List<String> _savedIds = [];
  bool _isLoading = true;
  String? _error;

  static const _categories = [
    _Cat(key: 'all',                label: 'All',               emoji: '✨'),
    _Cat(key: 'mental_health',      label: 'Mental Health',     emoji: '🧠'),
    _Cat(key: 'self_care',          label: 'Self Care',         emoji: '🌸'),
    _Cat(key: 'relationships',      label: 'Relationships',     emoji: '💬'),
    _Cat(key: 'nutrition',          label: 'Nutrition',         emoji: '🥗'),
    _Cat(key: 'fitness',            label: 'Fitness',           emoji: '🏃‍♀️'),
    _Cat(key: 'reproductive_health',label: 'Reproductive Health',emoji: '🌺'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _fetchArticles(),
        _repo.getSavedArticleIds(),
      ]);
      if (mounted) {
        setState(() {
          _articles = results[0] as List<Map<String, dynamic>>;
          _savedIds = results[1] as List<String>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load articles. Pull down to retry.';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchArticles() async {
    final response = await SupabaseConfig.client
        .from('library_articles')
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _toggleSave(Map<String, dynamic> article) async {
    final id = article['id'] as String;
    final isSaved = _savedIds.contains(id);
    setState(() {
      if (isSaved) {
        _savedIds.remove(id);
      } else {
        _savedIds.add(id);
      }
    });
    if (isSaved) {
      await _repo.unsaveArticle(id);
    } else {
      await _repo.saveArticle(id);
    }
  }

  void _share(Map<String, dynamic> article) {
    Share.share(
      '${article['emoji']} ${article['title']}\n\n'
      '${article['summary']}\n\n'
      'Shared from Femora',
      subject: article['title'] as String,
    );
  }

  void _openArticle(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ArticleDetailScreen(
          article: article,
          isSaved: _savedIds.contains(article['id']),
          onToggleSave: () => _toggleSave(article),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    return _articles.where((a) {
      final matchesCategory = _selectedCategory == 'all' ||
          a['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (a['title'] as String)
              .toLowerCase()
              .contains(_searchQuery) ||
          (a['summary'] as String)
              .toLowerCase()
              .contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildCategoryChips(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: FemoraColors.primary))
                  : _error != null
                      ? _buildError()
                      : _filtered.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: FemoraColors.primary,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 16, 16, 32),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) =>
                                    _buildArticleCard(_filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: FemoraColors.lightBackgroundTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: FemoraColors.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.libraryTitle,
              style: FemoraTextStyles.titleLarge.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Article count badge
          if (!_isLoading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: FemoraColors.lavenderWhisper,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filtered.length} articles',
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _SavedArticlesScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FemoraColors.lavenderWhisper,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bookmark_rounded,
                    color: FemoraColors.primary, size: 14),
                const SizedBox(width: 4),
                Text('Saved',
                    style: FemoraTextStyles.caption.copyWith(
                      color: FemoraColors.primary,
                      fontWeight: FontWeight.w700,
                    )),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // Search bar
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: FemoraColors.lightBackgroundTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: FemoraTextStyles.bodyMedium
                .copyWith(color: FemoraColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.librarySearchHint,
              hintStyle: FemoraTextStyles.bodyMedium
                  .copyWith(color: FemoraColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: FemoraColors.textSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                      child: const Icon(Icons.close_rounded,
                          color: FemoraColors.textSecondary,
                          size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          height: 1,
          color: FemoraColors.lavenderWhisper,
        ),
      ]),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((cat) {
            final selected = _selectedCategory == cat.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = cat.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? FemoraColors.primary
                        : FemoraColors.lightBackgroundTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Text(cat.emoji,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      cat.label,
                      style: FemoraTextStyles.caption.copyWith(
                        color: selected
                            ? Colors.white
                            : FemoraColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Article card ──────────────────────────────────────────────────────────

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final isSaved = _savedIds.contains(article['id'] as String);
    final cat = _categories.firstWhere(
      (c) => c.key == article['category'],
      orElse: () =>
          const _Cat(key: '', label: '', emoji: '📄'),
    );

    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: FemoraColors.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: FemoraColors.lavenderWhisper,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    article['emoji'] as String? ?? '📄',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: FemoraColors.lavenderWhisper,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat.label,
                        style: FemoraTextStyles.caption.copyWith(
                          color: FemoraColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${article['read_time']} read',
                      style: FemoraTextStyles.caption.copyWith(
                        color: FemoraColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Save icon
              GestureDetector(
                onTap: () => _toggleSave(article),
                child: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: isSaved
                      ? FemoraColors.primary
                      : FemoraColors.textSecondary,
                  size: 20,
                ),
              ),
            ]),

            const SizedBox(height: 12),

            Text(
              article['title'] as String,
              style: FemoraTextStyles.bodyLarge.copyWith(
                color: FemoraColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              article['summary'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            Row(children: [
              // Read more
              Text(
                'Read article',
                style: FemoraTextStyles.caption.copyWith(
                  color: FemoraColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  color: FemoraColors.primary, size: 14),

              const Spacer(),

              // Share button
              GestureDetector(
                onTap: () => _share(article),
                child: Row(children: [
                  const Icon(Icons.share_rounded,
                      color: FemoraColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Share',
                    style: FemoraTextStyles.caption.copyWith(
                      color: FemoraColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: FemoraTextStyles.bodyMedium.copyWith(
                color: FemoraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: FemoraColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Try Again',
                  style: FemoraTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: FemoraTextStyles.bodyLarge.copyWith(
              color: FemoraColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or category',
            style: FemoraTextStyles.bodyMedium.copyWith(
              color: FemoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Article Detail Screen ─────────────────────────────────────────────────────

class _ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const _ArticleDetailScreen({
    required this.article,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  State<_ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<_ArticleDetailScreen> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
  }

  void _toggleSave() {
    setState(() => _isSaved = !_isSaved);
    widget.onToggleSave();
  }

  void _share() {
    Share.share(
      '${widget.article['emoji']} ${widget.article['title']}\n\n'
      '${widget.article['summary']}\n\n'
      'Shared from Femora',
      subject: widget.article['title'] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: FemoraColors.lavenderWhisper,
                    width: 1,
                  ),
                ),
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: FemoraColors.lightBackgroundTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: FemoraColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
                const Spacer(),
                // Save icon
                GestureDetector(
                  onTap: _toggleSave,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _isSaved
                          ? FemoraColors.lavenderWhisper
                          : FemoraColors.lightBackgroundTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: _isSaved
                          ? FemoraColors.primary
                          : FemoraColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Share icon
                GestureDetector(
                  onTap: _share,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: FemoraColors.lightBackgroundTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: FemoraColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ]),
            ),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji + category + read time
                    Row(children: [
                      Text(
                        article['emoji'] as String? ?? '📄',
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: FemoraColors.lavenderWhisper,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              article['category']
                                      .toString()
                                      .replaceAll('_', ' ')
                                      .split(' ')
                                      .map((w) =>
                                          '${w[0].toUpperCase()}${w.substring(1)}')
                                      .join(' '),
                              style:
                                  FemoraTextStyles.caption.copyWith(
                                color: FemoraColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${article['read_time']} read  ·  ${article['author']}',
                            style: FemoraTextStyles.caption
                                .copyWith(
                              color: FemoraColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      article['title'] as String,
                      style:
                          FemoraTextStyles.headlineMedium.copyWith(
                        color: FemoraColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Summary (lead paragraph, slightly styled)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FemoraColors.lavenderWhisper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: FemoraColors.softLilac),
                      ),
                      child: Text(
                        article['summary'] as String,
                        style: FemoraTextStyles.bodyMedium.copyWith(
                          color: FemoraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Full content — render paragraphs
                    ...(article['content'] as String)
                        .split('\n\n')
                        .where((p) => p.trim().isNotEmpty)
                        .map((paragraph) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 16),
                              child: Text(
                                paragraph.trim(),
                                style: FemoraTextStyles.bodyMedium
                                    .copyWith(
                                  color: FemoraColors.textPrimary,
                                  height: 1.7,
                                ),
                              ),
                            )),

                    const SizedBox(height: 24),

                    // Footer
                    Center(
                      child: Text(
                        '— ${article['author']} —',
                        style: FemoraTextStyles.caption.copyWith(
                          color: FemoraColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved Articles Screen ─────────────────────────────────────────────────────

class _SavedArticlesScreen extends StatefulWidget {
  const _SavedArticlesScreen();

  @override
  State<_SavedArticlesScreen> createState() =>
      _SavedArticlesScreenState();
}

class _SavedArticlesScreenState extends State<_SavedArticlesScreen> {
  final _repo = MentalRepository();
  final _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _articles = [];
  List<String> _savedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Step 1: get saved article IDs
      final savedRows = await _supabase
          .from('mental_saved_articles')
          .select('article_id')
          .eq('user_id', userId);

      final ids = (savedRows as List)
          .map((r) => r['article_id'].toString())
          .where((id) => id.isNotEmpty)
          .toList();

      _savedIds = ids;

      debugPrint('Saved article IDs: $ids');

      if (ids.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Step 2: fetch matching articles
      final articles = await _supabase
          .from('library_articles')
          .select()
          .inFilter('id', ids);

      if (mounted) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(articles);
          _isLoading = false;
        });
        debugPrint('Fetched articles: ${_articles.length}');
      }
    } catch (e) {
      debugPrint('SavedArticles load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unsave(String articleId) async {
    await _repo.unsaveArticle(articleId);
    setState(() {
      _articles.removeWhere((a) => a['id'] == articleId);
      _savedIds.remove(articleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraColors.lightBackgroundTint,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: FemoraColors.lightBackgroundTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: FemoraColors.textPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Saved Articles',
                    style: FemoraTextStyles.titleLarge.copyWith(
                      color: FemoraColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    )),
                const Spacer(),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FemoraColors.lavenderWhisper,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_articles.length} saved',
                      style: FemoraTextStyles.caption.copyWith(
                        color: FemoraColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ]),
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 1,
                color: FemoraColors.lavenderWhisper,
              ),
            ]),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: FemoraColors.primary))
                : _articles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_outline_rounded,
                                  color: FemoraColors.primary
                                      .withValues(alpha: 0.4),
                                  size: 48),
                              const SizedBox(height: 16),
                              Text('No saved articles yet',
                                  style:
                                      FemoraTextStyles.bodyLarge
                                          .copyWith(
                                    color: FemoraColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 6),
                              Text(
                                'Tap the bookmark icon on any article to save it for later.',
                                textAlign: TextAlign.center,
                                style: FemoraTextStyles.bodyMedium
                                    .copyWith(
                                        color: FemoraColors
                                            .textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: FemoraColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _articles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final article = _articles[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _ArticleDetailScreen(
                                    article: article,
                                    isSaved: true,
                                    onToggleSave: () =>
                                        _unsave(article['id']),
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: FemoraColors.primary
                                          .withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 46, height: 46,
                                    decoration: BoxDecoration(
                                      color: FemoraColors
                                          .lavenderWhisper,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        article['emoji'] as String? ??
                                            '📄',
                                        style: const TextStyle(
                                            fontSize: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article['title'] as String,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: FemoraTextStyles
                                              .bodyLarge
                                              .copyWith(
                                            color: FemoraColors
                                                .textPrimary,
                                            fontWeight:
                                                FontWeight.w700,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${article['read_time']} read',
                                          style: FemoraTextStyles
                                              .caption
                                              .copyWith(
                                                  color: FemoraColors
                                                      .textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        _unsave(article['id']),
                                    child: const Icon(
                                      Icons.bookmark_rounded,
                                      color: FemoraColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

// ── Category model ────────────────────────────────────────────────────────────

class _Cat {
  final String key;
  final String label;
  final String emoji;

  const _Cat({
    required this.key,
    required this.label,
    required this.emoji,
  });
}
