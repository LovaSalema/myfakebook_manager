import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../providers/song_provider.dart';
import '../providers/extraction_song_provider.dart';
import '../providers/repertoire_provider.dart';
import '../providers/theme_provider.dart';
import '../../data/models/song.dart';
import '../../data/models/repertoire.dart';
import '../../data/services/test_data_service.dart';
import '../../data/services/database_helper.dart';
import 'song_detail_screen.dart';
import 'extracted_song_detail_screen.dart';
import 'add_song_screen.dart';
import 'add_repertoire_screen.dart';
import 'repertoire_detail_screen.dart';
import 'settings_screen.dart';
import 'extract_song_screen.dart';

/// Professional HomeScreen for Chord Charts application
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  String _selectedFilter = 'Tous';
  final List<String> _keyFilters = [
    'Tous',
    'Favoris',
    'C',
    'G',
    'D',
    'A',
    'E',
    'F',
  ];
  int _currentView = 0; // 0 = songs, 1 = repertoires

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final maxExtent = _scrollController.position.maxScrollExtent;

    // Show FAB when near top, hide when scrolling down
    if (offset > 100 && _showFab) {
      setState(() => _showFab = false);
    } else if (offset <= 100 && !_showFab) {
      setState(() => _showFab = true);
    }
  }

  void _showSongsView() {
    setState(() {
      _currentView = 0;
    });
  }

  void _showRepertoiresView() {
    setState(() {
      _currentView = 1;
    });
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SongProvider>(context, listen: false).loadSongs();
      Provider.of<ExtractionSongProvider>(context, listen: false).loadSongs();
      Provider.of<RepertoireProvider>(context, listen: false).loadRepertoires();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer2<SongProvider, ExtractionSongProvider>(
      builder: (context, songProvider, extractionSongProvider, child) {
        return Scaffold(
          backgroundColor: isDark
              ? Color(AppColors.backgroundDark)
              : Color(AppColors.backgroundLight),
          appBar: _buildAppBar(context, isDark),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Statistics Section
                _buildStatsSection(),

                // Content based on selected view
                _buildContentView(),
              ],
            ),
          ),
          floatingActionButton: _showFab ? _buildFloatingActionButton() : null,
        );
      },
    );
  }

  /// Build professional AppBar with integrated search
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? Color(AppColors.backgroundDark)
          : Color(AppColors.backgroundLight),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      title: Row(
        children: [
          Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Chord Charts',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _showFilterOptions,
        ),
        IconButton(
          icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.primary),
          onPressed: _showSortOptions,
        ),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _showSettings,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: _buildSearchBar(context),
        ),
      ),
    );
  }

  /// Build integrated search bar
  Widget _buildSearchBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.0.w,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(width: 16.w),
          Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une chanson...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  size: 20.sp,
                ),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Build statistics section
  Widget _buildStatsSection() {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final extractionSongProvider = Provider.of<ExtractionSongProvider>(
      context,
      listen: false,
    );
    final repertoireProvider = Provider.of<RepertoireProvider>(
      context,
      listen: false,
    );

    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, int>>(
        future: _getCombinedStats(songProvider, extractionSongProvider),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {'songCount': 0, 'favoriteCount': 0};

          return Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                _StatCard(
                  title: 'Chansons',
                  value: stats['songCount']?.toString() ?? '0',
                  icon: Icons.music_note,
                  color: Color(AppColors.primary),
                  onTap: _showSongsView,
                  isActive: _currentView == 0,
                ),
                SizedBox(width: 12.w),
                _StatCard(
                  title: 'Répertoires',
                  value: repertoireProvider.repertoireCount.toString(),
                  icon: Icons.library_music,
                  color: Colors.blue,
                  onTap: _showRepertoiresView,
                  isActive: _currentView == 1,
                ),
              ],
            ),
          ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms);
        },
      ),
    );
  }

  /// Build content based on selected view
  Widget _buildContentView() {
    if (_currentView == 0) {
      return _buildSongsTab();
    } else {
      return _buildRepertoiresTab();
    }
  }

  /// Build songs tab content
  Widget _buildSongsTab() {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final extractionSongProvider = Provider.of<ExtractionSongProvider>(
      context,
      listen: false,
    );
    final combinedSongs = [
      ...songProvider.songs,
      ...extractionSongProvider.songs,
    ];
    final filteredSongs = _getFilteredSongs(combinedSongs);

    if (songProvider.isLoading || extractionSongProvider.isLoading) {
      return _buildLoadingState();
    }

    if (filteredSongs.isEmpty &&
        !songProvider.isLoading &&
        !extractionSongProvider.isLoading) {
      return _buildEmptyState();
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = filteredSongs[index];
        return _SongCard(
          song: song,
          onTap: () => _navigateToSongDetail(song),
          onLongPress: () => _showSongContextMenu(song),
        ).animate().fadeIn(delay: (100 * index).ms);
      }, childCount: filteredSongs.length),
    );
  }

  /// Build repertoires tab content
  Widget _buildRepertoiresTab() {
    return Consumer<RepertoireProvider>(
      builder: (context, repertoireProvider, child) {
        final repertoires = repertoireProvider.repertoires;

        if (repertoireProvider.isLoading) {
          return _buildRepertoiresLoadingState();
        }

        if (repertoires.isEmpty && !repertoireProvider.isLoading) {
          return _buildRepertoiresEmptyState();
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final repertoire = repertoires[index];
            return _RepertoireCard(
              repertoire: repertoire,
              onTap: () => _showRepertoireSongs(repertoire),
              onLongPress: () => _showRepertoireContextMenu(repertoire),
            ).animate().fadeIn(delay: (100 * index).ms);
          }, childCount: repertoires.length),
        );
      },
    );
  }

  /// Build repertoires loading state
  Widget _buildRepertoiresLoadingState() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        final isDark = themeProvider.isDarkMode;

        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade500 : Colors.grey.shade100,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Color(AppColors.surfaceDark) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 120.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: 3),
    );
  }

  /// Build repertoires empty state
  Widget _buildRepertoiresEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 80.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 24.h),
            Text(
              'Aucun répertoire',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Créez votre premier répertoire',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            // FilledButton(
            //   onPressed: _createNewRepertoire,
            //   child: const Text('Créer un répertoire'),
            // ),
          ],
        ),
      ),
    );
  }

  /// Build filter chips section
  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 40.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _keyFilters.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final filter = _keyFilters[index];
              final isSelected = _selectedFilter == filter;
              final isFavorite = filter == 'Favoris';

              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFavorite)
                      Icon(
                        Icons.favorite,
                        size: 16.sp,
                        color: isSelected ? Colors.white : Colors.red,
                      ),
                    if (isFavorite) SizedBox(width: 4.w),
                    Text(filter),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? filter : 'Tous';
                  });
                  _applyFilters();
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              );
            },
          ),
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  /// Build songs list
  Widget _buildSongsList() {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        final filteredSongs = _getFilteredSongs(songProvider.songs);

        if (songProvider.isLoading) {
          return _buildLoadingState();
        }

        if (filteredSongs.isEmpty && !songProvider.isLoading) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final song = filteredSongs[index];
            return _SongCard(
              song: song,
              onTap: () => _navigateToSongDetail(song),
              onLongPress: () => _showSongContextMenu(song),
            ).animate().fadeIn(delay: (100 * index).ms);
          }, childCount: filteredSongs.length),
        );
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final extractionSongProvider = Provider.of<ExtractionSongProvider>(
      context,
      listen: false,
    );

    if ((songProvider.songs.isNotEmpty ||
            extractionSongProvider.songs.isNotEmpty) ||
        songProvider.isLoading ||
        extractionSongProvider.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 80.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 24.h),
            Text(
              'Aucune chanson',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Créez votre première grille d\'accords',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            // FilledButton(
            //   onPressed: _createNewSong,
            //   child: const Text('Commencer'),
            // ),
          ],
        ),
      ),
    );
  }

  /// Build loading state with shimmer
  Widget _buildLoadingState() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        final isDark = themeProvider.isDarkMode;

        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade500 : Colors.grey.shade100,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Color(AppColors.surfaceDark) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 120.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: 5),
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return Stack(
      children: [
        // Bouton principal qui change selon la vue active
        Positioned(
          bottom: 16.h,
          right: 16.w,
          child: FloatingActionButton(
            onPressed: _currentView == 0
                ? _createNewSong
                : _createNewRepertoire,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.add),
          ).animate().scale(duration: 300.ms),
        ),

        // Bouton secondaire pour données de test
        // Positioned(
        //   bottom: 90, // légèrement au-dessus du principal
        //   right: 16,
        //   child: FloatingActionButton.small(
        //     onPressed: _initializeTestData,
        //     heroTag: 'test_data',
        //     backgroundColor: Colors.orange,
        //     foregroundColor: Colors.white,
        //     child: const Icon(Icons.data_usage),
        //   ).animate().scale(duration: 300.ms),
        // ),
      ],
    );
  }

  // Helper methods
  List<Song> _getFilteredSongs(List<Song> songs) {
    var filtered = songs;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (song) =>
                song.title.toLowerCase().contains(query) ||
                song.artist.toLowerCase().contains(query) ||
                song.key.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply key filter
    if (_selectedFilter != 'Tous') {
      if (_selectedFilter == 'Favoris') {
        filtered = filtered.where((song) => song.isFavorite).toList();
      } else {
        filtered = filtered
            .where((song) => song.key == _selectedFilter)
            .toList();
      }
    }

    return filtered;
  }

  Future<void> _refreshData() async {
    await Provider.of<SongProvider>(context, listen: false).loadSongs();
    await Provider.of<ExtractionSongProvider>(
      context,
      listen: false,
    ).loadSongs();
    await Provider.of<RepertoireProvider>(
      context,
      listen: false,
    ).loadRepertoires();
  }

  Future<Map<String, int>> _getCombinedStats(
    SongProvider songProvider,
    ExtractionSongProvider extractionSongProvider,
  ) async {
    final regularStats = await songProvider.getStats();
    final extractedStats = await extractionSongProvider.getStats();

    return {
      'songCount':
          (regularStats['songCount'] ?? 0) + (extractedStats['songCount'] ?? 0),
      'favoriteCount':
          (regularStats['favoriteCount'] ?? 0) +
          (extractedStats['favoriteCount'] ?? 0),
    };
  }

  void _onSearchChanged(String query) {
    // Debounced search would be implemented here
    setState(() {});
  }

  void _applyFilters() {
    setState(() {});
  }

  void _filterByType(String type) {
    // Implementation for filtering by type
  }

  void _showRepertoires() {
    // Implementation for showing repertoires
  }

  void _showFilterOptions() {
    // Implementation for filter options
  }

  void _showSortOptions() {
    // Implementation for sort options
  }

  void _showSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _createNewSong() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Créer une nouvelle chanson'),
          content: const Text('Comment souhaitez-vous créer votre chanson ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddSongScreen(),
                  ),
                );
              },
              child: const Text('Écrire les accords'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ExtractSongScreen()),
                );
              },
              child: const Text('Extraire par audio ou URL'),
            ),
          ],
        );
      },
    );
  }

  /// Initialise les données de test
  Future<void> _initializeTestData() async {
    try {
      final databaseHelper = DatabaseHelper();
      await TestDataService.initializeTestData(databaseHelper);

      // Recharger les données dans les providers
      final songProvider = Provider.of<SongProvider>(context, listen: false);
      final extractionSongProvider = Provider.of<ExtractionSongProvider>(
        context,
        listen: false,
      );
      final repertoireProvider = Provider.of<RepertoireProvider>(
        context,
        listen: false,
      );

      await songProvider.loadSongs();
      await extractionSongProvider.loadSongs();
      await repertoireProvider.loadRepertoires();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Données de test initialisées avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de l\'initialisation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToSongDetail(Song song) async {
    if (song.id != null) {
      // Check if song exists in regular provider first
      final regularSongProvider = Provider.of<SongProvider>(
        context,
        listen: false,
      );
      final regularSong = await regularSongProvider.getSongById(song.id!);

      if (regularSong != null) {
        // Song is from regular provider
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SongDetailScreen(songId: song.id!),
          ),
        );
      } else {
        // Song is from extracted provider
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExtractedSongDetailScreen(songId: song.id!),
          ),
        );
      }
    }
  }

  void _showSongContextMenu(Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Éditer'),
                onTap: () {
                  Navigator.pop(context);
                  _editSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Ajouter au répertoire'),
                onTap: () {
                  Navigator.pop(context);
                  _addToRepertoire(song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editSong(Song song) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => AddSongScreen(song: song)));
  }

  void _deleteSong(Song song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la chanson'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${song.title}" par ${song.artist} ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final songProvider = Provider.of<SongProvider>(
                    context,
                    listen: false,
                  );
                  final success = await songProvider.deleteSong(song.id!);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${song.title}" a été supprimé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la suppression'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addToRepertoire(Song song) {
    // Implementation for adding to repertoire
  }

  void _showRepertoireSongs(Repertoire repertoire) {
    print(
      'Trying to navigate to repertoire detail: ${repertoire.id} - ${repertoire.name}',
    );
    if (repertoire.id != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              RepertoireDetailScreen(repertoireId: repertoire.id!),
        ),
      );
    } else {
      print('Repertoire ID is null, cannot navigate');
    }
  }

  void _showRepertoireContextMenu(Repertoire repertoire) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Éditer'),
                onTap: () {
                  Navigator.pop(context);
                  _editRepertoire(repertoire);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteRepertoire(repertoire);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editRepertoire(Repertoire repertoire) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddRepertoireScreen(repertoire: repertoire),
      ),
    );
  }

  void _deleteRepertoire(Repertoire repertoire) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le répertoire'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${repertoire.name}" ? Toutes les chansons associées seront retirées du répertoire. Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final repertoireProvider = Provider.of<RepertoireProvider>(
                    context,
                    listen: false,
                  );
                  final success = await repertoireProvider.deleteRepertoire(
                    repertoire.id!,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${repertoire.name}" a été supprimé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la suppression'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createNewRepertoire() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddRepertoireScreen()),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: isActive
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.w,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withOpacity(isActive ? 0.1 : 0.05),
                blurRadius: isActive ? 12.r : 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isActive ? 28.sp : 24.sp),
              SizedBox(height: 8.h),
              Text(
                value,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: isActive ? 20.sp : 18.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(isActive ? 0.9 : 0.7),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Song Card Widget
class _SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SongCard({
    required this.song,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: _getSongColor(song.title),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      song.title.isNotEmpty ? song.title[0].toUpperCase() : '?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            song.artist,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          if (song.key.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                song.key,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (song.isFavorite)
                      Icon(Icons.favorite, color: Colors.red, size: 20.sp),
                    SizedBox(height: 4.h),
                    // Repertoire badge would go here
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSongColor(String title) {
    final colors = [
      Color(AppColors.primary),
      Color(AppColors.secondary),
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    final index = title.isNotEmpty ? title.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}

/// Repertoire Card Widget
class _RepertoireCard extends StatelessWidget {
  final Repertoire repertoire;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RepertoireCard({
    required this.repertoire,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: _getRepertoireColor(repertoire.name),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      repertoire.name.isNotEmpty
                          ? repertoire.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repertoire.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          if (repertoire.eventDate != null) ...[
                            Text(
                              repertoire.eventDateDisplay,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Repertoire actions would go here
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRepertoireColor(String title) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    final index = title.isNotEmpty ? title.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}
