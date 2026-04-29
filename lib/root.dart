import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_project/mock_data/mock_tracks.dart';
import 'package:my_project/models/track.dart';
import 'package:my_project/navigation/bottom_nav_bar.dart';
import 'package:my_project/screens/feed/feed_screen.dart';
import 'package:my_project/screens/home/home_screen.dart';
import 'package:my_project/screens/library/library_screen.dart';
import 'package:my_project/screens/search/search_screen.dart';
import 'package:my_project/screens/upgrade/upgrade_screen.dart';
import 'package:my_project/widgets/full_player.dart';
import 'package:my_project/widgets/mini_player.dart';
import './providers/track_provider.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _selectedIndex = 0;

  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool _hasLoaded = false;

  Track _currentTrack = MockTracks.hotTrack;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  final Map<int, Widget> _subScreens = {};

  void _pushSubScreen(Widget screen) {
    setState(() => _subScreens[_selectedIndex] = screen);
  }

  void _popSubScreen() {
    setState(() => _subScreens.remove(_selectedIndex));
  }

  @override
  void initState() {
    super.initState();
    _listenToPlayer();
  }

  void _listenToPlayer() {
    _positionSub = _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _currentPosition = position);
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() {
        _totalDuration =
            duration ?? Duration(seconds: _currentTrack.durationSeconds ?? 0);
      });
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// ✅ FIXED: now uses Riverpod correctly
  Future<void> _handlePlay(Track track) async {
    try {
      // 1. Fetch stream info from backend
      final streamData = await ref
          .read(tracksServiceProvider)
          .getTrackStream(trackId: track.trackId);

      debugPrint("Stream data: $streamData");

      final rawUrl = streamData['stream_url'];

      if (rawUrl == null || rawUrl.toString().isEmpty) {
        debugPrint("Invalid stream URL");
        return;
      }

      // 2. Convert relative URL → absolute URL
      final url = rawUrl.toString().startsWith('http')
          ? rawUrl.toString()
          : 'https://streamline-swp.duckdns.org$rawUrl';

      debugPrint("Final audio URL: $url");

      // 3. Pause if same track is playing
      if (_currentTrack.trackId == track.trackId && _isPlaying) {
        await _player.pause();
        return;
      }

      // 4. Load new track if needed
      if (_currentTrack.trackId != track.trackId || !_hasLoaded) {
        _hasLoaded = true;
        _currentTrack = track;
        _currentPosition = Duration.zero;

        try {
          await _player.setUrl(url);
        } catch (e) {
          debugPrint("just_audio load error: $e");
          return;
        }
      }

      // 5. Play
      await _player.play();
    } catch (e, stack) {
      debugPrint("Audio load failed: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Future<void> _toggleCurrentTrack() async {
    await _handlePlay(_currentTrack);
  }

  Future<void> _seekTo(Duration position) async {
    final maxDuration = _totalDuration.inMilliseconds > 0
        ? _totalDuration
        : Duration(seconds: _currentTrack.durationSeconds ?? 0);

    final clamped = position < Duration.zero
        ? Duration.zero
        : position > maxDuration
        ? maxDuration
        : position;

    await _player.seek(clamped);

    if (!mounted) return;
    setState(() => _currentPosition = clamped);
  }

  void _openFullPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPlayer(
          track: _currentTrack,
          player: _player,
          onPlayPause: _toggleCurrentTrack,
          onSeek: _seekTo,
        ),
      ),
    );
  }

  List<Widget> _buildScreens() => [
    HomeScreen(onTrackTap: _handlePlay),
    const FeedScreen(),
    SearchScreen(),
    LibraryScreen(
      onNavigate: _pushSubScreen,
      onBack: _popSubScreen,
      onTrackTap: _handlePlay,
    ),
    const UpgradeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _subScreens[_selectedIndex] ?? _buildScreens()[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            track: _currentTrack,
            isPlaying: _isPlaying,
            onPlay: _toggleCurrentTrack,
            onOpenFullPlayer: _openFullPlayer,
          ),
          BottomNavBar(
            onTabSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
        ],
      ),
    );
  }
}
