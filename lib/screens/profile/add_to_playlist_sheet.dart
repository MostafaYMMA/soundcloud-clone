import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/auth_providers.dart';

void showAddToPlaylistSheet(BuildContext context, Track track) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AddToPlaylistSheet(track: track),
  );
}

class _AddToPlaylistSheet extends ConsumerStatefulWidget {
  const _AddToPlaylistSheet({required this.track});
  final Track track;

  @override
  ConsumerState<_AddToPlaylistSheet> createState() =>
      _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<_AddToPlaylistSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Maps playlist id → whether it contains the track
  final Set<String> _selected = {};
  // Original state to detect changes
  final Set<String> _originallyContained = {};
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final username = ref.read(authProvider).user?.userName;
    if (username != null && username.isNotEmpty) {
      await ref.read(playlistProvider.notifier).fetchUserPlaylists(username);
    }
    if (!mounted) return;

    final playlists = ref.read(playlistProvider).userPlaylists;

    // Fetch full details for each playlist to get their track lists
    final Set<String> contained = {};
    for (final playlist in playlists) {
      final details = await ref
          .read(playlistProvider.notifier)
          .getPlaylistDetails(playlist.id);
      if (details != null) {
        final hasTrack = details.tracks.any(
          (t) => t.id == widget.track.trackId,
        );
        if (hasTrack) contained.add(playlist.id);
      }
    }

    if (!mounted) return;
    setState(() {
      _selected.addAll(contained);
      _originallyContained.addAll(contained);
      _initialized = true;
    });
  }

  List<Playlist> _filteredPlaylists(List<Playlist> all) {
    if (_searchQuery.trim().isEmpty) return all;
    return all
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()),
        )
        .toList();
  }

  Future<void> _done() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(playlistProvider.notifier);
    final allPlaylists = ref.read(playlistProvider).userPlaylists;

    for (final playlist in allPlaylists) {
      final wasContained = _originallyContained.contains(playlist.id);
      final isSelected = _selected.contains(playlist.id);

      if (isSelected && !wasContained) {
        await notifier.addTrack(
          playlistId: playlist.id,
          trackId: widget.track.trackId,
        );
      } else if (!isSelected && wasContained) {
        await notifier.removeTrack(
          playlistId: playlist.id,
          trackId: widget.track.trackId,
        );
      }
    }

    final username = ref.read(authProvider).user?.userName;
    if (username != null) {
      await notifier.fetchUserPlaylists(username);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _createNewPlaylist() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'New Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Create', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final playlist = await ref
          .read(playlistProvider.notifier)
          .createPlaylist(name: name);
      if (playlist != null) {
        await ref
            .read(playlistProvider.notifier)
            .addTrack(playlistId: playlist.id, trackId: widget.track.trackId);
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);
    final allPlaylists = playlistState.userPlaylists;
    final filtered = _filteredPlaylists(allPlaylists);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search, color: Colors.white54, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Search ${allPlaylists.length} playlists',
                            hintStyle: const TextStyle(
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // List
              Expanded(
                child: !_initialized
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          ListTile(
                            onTap: _createNewPlaylist,
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            title: const Text(
                              'New playlist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 1),
                          ...filtered.map((playlist) {
                            final isChecked = _selected.contains(playlist.id);
                            return ListTile(
                              onTap: () => setState(() {
                                if (isChecked) {
                                  _selected.remove(playlist.id);
                                } else {
                                  _selected.add(playlist.id);
                                }
                              }),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: playlist.coverUrl.isNotEmpty
                                    ? Image.network(
                                        playlist.coverUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _PlaylistThumb(),
                                      )
                                    : _PlaylistThumb(),
                              ),
                              title: Text(
                                playlist.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${playlist.trackCount} tracks',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Checkbox(
                                value: isChecked,
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(playlist.id);
                                  } else {
                                    _selected.remove(playlist.id);
                                  }
                                }),
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                                side: const BorderSide(color: Colors.white54),
                              ),
                            );
                          }),
                        ],
                      ),
              ),

              // Done button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: SizedBox(
                  width: 140,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _done,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaylistThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.queue_music, color: Colors.white38, size: 24),
    );
  }
}
