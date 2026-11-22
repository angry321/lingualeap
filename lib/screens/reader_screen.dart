import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/material_item.dart';
import '../models/segment.dart';
import '../providers/app_providers.dart';
import '../utils/text_tokenizer.dart';
import '../widgets/word_span_widget.dart';
import 'word_sheet.dart';

class ReaderScreen extends StatefulWidget {
  final MaterialItem material;

  const ReaderScreen({super.key, required this.material});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  YoutubePlayerController? _ytController;
  Timer? _positionTimer;
  int _currentPositionMs = 0;
  int _activeSegmentIndex = -1;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _segmentKeys = {};

  late List<Segment> _segments;
  late List<List<Token>> _tokenizedSegments;

  bool _isAutoScrollEnabled = true;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _segments = widget.material.segments;
    _tokenizedSegments = _segments.map((s) => TextTokenizer.tokenize(s.text)).toList();

    for (int i = 0; i < _segments.length; i++) {
      _segmentKeys[i] = GlobalKey();
    }

    final settings = context.read<SettingsProvider>();
    _isAutoScrollEnabled = settings.autoScroll;
    _fontSize = settings.fontSize;

    if (widget.material.isYouTube && widget.material.youtubeId != null) {
      _initYouTubePlayer(widget.material.youtubeId!);
    }
  }

  void _initYouTubePlayer(String videoId) {
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableCaption: false, // We render our own interactive subtitles!
      ),
    );

    // Poll position every 300 ms for smooth subtitle tracking
    _positionTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (!mounted || _ytController == null) return;
      try {
        final positionSeconds = await _ytController!.currentTime;
        final currentMs = (positionSeconds * 1000).toInt();

        if (currentMs != _currentPositionMs) {
          _updateActiveSegment(currentMs);
        }
      } catch (_) {}
    });
  }

  void _updateActiveSegment(int currentMs) {
    setState(() {
      _currentPositionMs = currentMs;
    });

    int foundIndex = -1;
    for (int i = 0; i < _segments.length; i++) {
      final s = _segments[i];
      // If segment has startMs & durationMs
      if (s.durationMs > 0) {
        if (currentMs >= s.startMs && currentMs < s.endMs) {
          foundIndex = i;
          break;
        }
      } else {
        // Fallback: until next segment starts
        final nextStart = (i + 1 < _segments.length) ? _segments[i + 1].startMs : (s.startMs + 5000);
        if (currentMs >= s.startMs && currentMs < nextStart) {
          foundIndex = i;
          break;
        }
      }
    }

    if (foundIndex != -1 && foundIndex != _activeSegmentIndex) {
      setState(() {
        _activeSegmentIndex = foundIndex;
      });

      if (_isAutoScrollEnabled) {
        _scrollToActiveSegment(foundIndex);
      }
    }
  }

  void _scrollToActiveSegment(int index) {
    final key = _segmentKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        alignment: 0.35, // Keep active segment slightly above the middle
      );
    }
  }

  void _seekToSegment(int startMs) {
    if (_ytController != null) {
      _ytController!.seekTo(
        seconds: startMs / 1000.0,
        allowSeekAhead: true,
      );
      _ytController!.playVideo();
    }
  }

  String _formatTime(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _ytController?.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.material.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          if (widget.material.isYouTube)
            IconButton(
              tooltip: _isAutoScrollEnabled ? 'Автопрокрутка включена' : 'Автопрокрутка выключена',
              icon: Icon(
                _isAutoScrollEnabled ? Icons.sync : Icons.sync_disabled,
                color: _isAutoScrollEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isAutoScrollEnabled = !_isAutoScrollEnabled;
                });
              },
            ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.format_size),
            tooltip: 'Размер шрифта',
            onSelected: (val) {
              setState(() {
                _fontSize = val;
              });
              context.read<SettingsProvider>().updateFontSize(val);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 15.0, child: Text('Мелкий (15pt)')),
              const PopupMenuItem(value: 18.0, child: Text('Средний (18pt)')),
              const PopupMenuItem(value: 22.0, child: Text('Крупный (22pt)')),
              const PopupMenuItem(value: 26.0, child: Text('Очень крупный (26pt)')),
            ],
          ),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  /// Wide layout (PC / Tablet / Landscape)
  Widget _buildWideLayout() {
    return Row(
      children: [
        if (widget.material.isYouTube && _ytController != null)
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _ytController!,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.material.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Сегментов: ${_segments.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '💡 Подсказка: кликайте на любое слово в тексте справа для мгновенного контекстного перевода через ИИ и добавления в личный словарь.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 6,
          child: _buildSegmentsList(),
        ),
      ],
    );
  }

  /// Narrow layout (Phone / Portrait)
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        if (widget.material.isYouTube && _ytController != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: _ytController!,
            ),
          ),
        Expanded(
          child: _buildSegmentsList(),
        ),
      ],
    );
  }

  Widget _buildSegmentsList() {
    if (_segments.isEmpty) {
      return const Center(
        child: Text('Материал не содержит текста.'),
      );
    }

    // Consumer of WordsProvider so any word status change updates instantly!
    return Consumer<WordsProvider>(
      builder: (context, wordsProvider, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: _segments.length,
          itemBuilder: (context, index) {
            final segment = _segments[index];
            final tokens = _tokenizedSegments[index];
            final isActive = widget.material.isYouTube && index == _activeSegmentIndex;

            return Container(
              key: _segmentKeys[index],
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Play timecode button for YouTube
                  if (widget.material.isYouTube)
                    Padding(
                      padding: const EdgeInsets.only(right: 10, top: 2),
                      child: InkWell(
                        onTap: () => _seekToSegment(segment.startMs),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                size: 14,
                                color: isActive
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatTime(segment.startMs),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Interactive clickable words in Wrap
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: tokens.map((token) {
                        final savedWord = token.isWord
                            ? wordsProvider.findWord(token.cleanWord)
                            : null;

                        return WordSpanWidget(
                          token: token,
                          savedWord: savedWord,
                          fontSize: _fontSize,
                          onTap: token.isWord
                              ? () {
                                  WordSheet.show(
                                    context,
                                    word: token.text,
                                    cleanWord: token.cleanWord,
                                    contextSentence: segment.text,
                                  );
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
