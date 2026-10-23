import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'config.dart';
import 'main.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final String? initialAudioUrl;
  final ValueChanged<String?> onAudioChanged;

  const VoiceRecorderWidget({
    super.key,
    this.initialAudioUrl,
    required this.onAudioChanged,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  late final AudioRecorder _recorder;
  late final AudioPlayer _player;

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isUploading = false;
  String? _localPath;
  String? _remoteUrl;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _player = AudioPlayer();
    _remoteUrl = widget.initialAudioUrl;

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/prompt_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        setState(() {
          _isRecording = true;
          _localPath = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record voice.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _localPath = path;
      });

      if (path != null) {
        await _uploadVoice(path);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recording: $e')),
        );
      }
    }
  }

  Future<void> _uploadVoice(String localFilePath) async {
    setState(() => _isUploading = true);
    try {
      final file = File(localFilePath);
      final bytes = await file.readAsBytes();
      final fileName = 'prompt_${elderId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Ensure storage upload
      await db.storage.from('audio-prompts').uploadBinary(
        fileName,
        bytes,
      );

      final publicUrl = db.storage.from('audio-prompts').getPublicUrl(fileName);
      setState(() {
        _remoteUrl = publicUrl;
      });
      widget.onAudioChanged(publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF2E7D32), content: Text('Voice prompt uploaded successfully!')),
        );
      }
    } catch (e) {
      // In case storage bucket isn't set up yet, fallback to saving local path or data
      widget.onAudioChanged(_remoteUrl ?? localFilePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recorded locally. (Storage sync note: $e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.stop();
      return;
    }

    if (_localPath != null && File(_localPath!).existsSync()) {
      await _player.play(DeviceFileSource(_localPath!));
    } else if (_remoteUrl != null && _remoteUrl!.isNotEmpty) {
      await _player.play(UrlSource(_remoteUrl!));
    }
  }

  void _clearRecording() {
    _player.stop();
    setState(() {
      _localPath = null;
      _remoteUrl = null;
    });
    widget.onAudioChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = (_localPath != null && _localPath!.isNotEmpty) || (_remoteUrl != null && _remoteUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6C8B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, size: 20, color: Color(0xFF343B2D)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Record Malayalam Voice Prompt:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF343B2D)),
                ),
              ),
              if (hasAudio)
                const Chip(
                  label: Text('Voice Saved', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                  backgroundColor: Color(0xFFE8F5E9),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Record your own voice asking Amma (e.g. "Food kazhicho?", "Medicine edutho?"). She will hear this during the call.',
            style: TextStyle(fontSize: 12, color: Color(0xFF555C54)),
          ),
          const SizedBox(height: 12),
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Recording your voice...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Done'),
                  ),
                ],
              ),
            )
          else if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Uploading audio...', style: TextStyle(fontSize: 13)),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF343B2D),
                      side: const BorderSide(color: Color(0xFF343B2D)),
                    ),
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic),
                    label: Text(hasAudio ? 'Re-record Voice' : 'Tap to Record'),
                  ),
                ),
                if (hasAudio) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _isPlaying ? 'Stop' : 'Play preview',
                    onPressed: _togglePlayback,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: 'Delete recording',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _clearRecording,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
