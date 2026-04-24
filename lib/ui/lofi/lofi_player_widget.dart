import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio/lofi_audio_providers.dart';
import '../../services/audio/lofi_track.dart';

class LofiPlayerWidget extends ConsumerStatefulWidget {
  const LofiPlayerWidget({super.key});

  @override
  ConsumerState<LofiPlayerWidget> createState() => _LofiPlayerWidgetState();
}

class _LofiPlayerWidgetState extends ConsumerState<LofiPlayerWidget> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(lofiCatalogProvider);
    final currentTrack = ref.watch(lofiCurrentTrackProvider);
    final volume = ref.watch(lofiVolumeProvider);
    final isPlaying = ref.watch(lofiIsPlayingProvider);

    return catalogAsync.when(
      data: (catalog) {
        _selectedCategory ??= catalog.categories.isNotEmpty ? catalog.categories[0].slug : null;

        final filteredTracks = _selectedCategory != null ? catalog.tracks.where((t) => t.category == _selectedCategory).toList() : [];

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lofi Music',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (currentTrack != null) ...[
                      Text(
                        'Now: ${currentTrack.title}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _PlaybackControls(
                      currentTrack: currentTrack,
                      isPlaying: isPlaying,
                      volume: volume,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: catalog.categories.length,
                  itemBuilder: (context, index) {
                    final category = catalog.categories[index];
                    final isSelected = _selectedCategory == category.slug;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category.label, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category.slug : null;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Tracks',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTracks.length,
                  itemBuilder: (context, index) {
                    final track = filteredTracks[index];
                    final isCurrent = currentTrack?.filename == track.filename;
                    return ListTile(
                      dense: true,
                      title: Text(
                        track.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: isCurrent,
                      onTap: () => _playTrack(track),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error: ${error.toString()}',
          style: const TextStyle(fontSize: 12, color: Colors.red),
        ),
      ),
    );
  }

  void _playTrack(LofiTrack track) async {
    final service = ref.read(lofiAudioServiceProvider);
    try {
      ref.read(lofiCurrentTrackProvider.notifier).setTrack(track);
      await service.playTrack(track);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing track: $e')),
      );
    }
  }
}

class _PlaybackControls extends ConsumerWidget {
  final LofiTrack? currentTrack;
  final AsyncValue<bool> isPlaying;
  final double volume;

  const _PlaybackControls({
    required this.currentTrack,
    required this.isPlaying,
    required this.volume,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(lofiAudioServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: isPlaying.when(
                data: (playing) => Icon(playing ? Icons.pause : Icons.play_arrow),
                loading: () => const Icon(Icons.hourglass_empty),
                error: (_, __) => const Icon(Icons.error),
              ),
              onPressed: currentTrack == null
                  ? null
                  : () async {
                      await isPlaying.when(
                        data: (playing) async {
                          if (playing) {
                            await service.pause();
                          } else {
                            await service.resume();
                          }
                        },
                        loading: () {},
                        error: (_, __) {},
                      );
                    },
              tooltip: 'Play/Pause',
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: currentTrack == null
                  ? null
                  : () async {
                      await service.stop();
                      ref.read(lofiCurrentTrackProvider.notifier).clearTrack();
                    },
              tooltip: 'Stop',
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.volume_down, size: 16),
            SizedBox(
              width: 100,
              child: Slider(
                value: volume,
                onChanged: (value) {
                  ref.read(lofiVolumeProvider.notifier).setVolume(value);
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
            const Icon(Icons.volume_up, size: 16),
          ],
        ),
      ],
    );
  }
}
