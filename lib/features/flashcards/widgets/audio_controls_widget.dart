import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import '../../../utils/logger.dart';

class AudioControlsWidget extends StatefulWidget {
  final String? initialAudioPath;
  final ValueChanged<String?> onAudioChanged;
  const AudioControlsWidget({Key? key, this.initialAudioPath, required this.onAudioChanged}) : super(key: key);

  @override
  State<AudioControlsWidget> createState() => _AudioControlsWidgetState();
}

class _AudioControlsWidgetState extends State<AudioControlsWidget> {
  final Logger _logger = Logger();
  late final AudioRecorder _recorder;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _audioPath;
  Timer? _timer;
  Duration _recordDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _audioPath = widget.initialAudioPath;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final String filePath = '${appDir.path}/recording_$timestamp.m4a';
        await _recorder.start(path: filePath);
        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });
        _timer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration = Duration(seconds: timer.tick);
          });
        });
        _logger.info('Enregistrement démarré: $filePath');
      } else {
        _logger.error('Permission d\'enregistrement non accordée');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission d\'enregistrement non accordée')),
        );
      }
    } catch (e) {
      _logger.error('Erreur lors du démarrage de l\'enregistrement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du démarrage de l\'enregistrement')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioPath = path;
          widget.onAudioChanged(_audioPath);
          _logger.info('Enregistrement terminé: $path');
        }
      });
    } catch (e) {
      _logger.error('Erreur lors de l\'arrêt de l\'enregistrement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'arrêt de l\'enregistrement')),
      );
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath != null && _audioPath!.isNotEmpty) {
      try {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await _audioPlayer.setFilePath(_audioPath!);
          await _audioPlayer.play();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fichier audio introuvable')),
          );
          _logger.warning('Fichier audio non trouvé: $_audioPath');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la lecture audio')),
        );
        _logger.error('Erreur lors de la lecture audio: $e');
      }
    }
  }

  void _deleteAudio() {
    setState(() {
      _audioPath = null;
      widget.onAudioChanged(null);
    });
    _logger.info('Audio supprimé');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Audio", style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Orbitron')),
        Row(
          children: [
            if (_audioPath != null && !_isRecording)
              IconButton(
                icon: Icon(Icons.play_arrow),
                tooltip: 'Écouter l\'audio actuel',
                onPressed: _playAudio,
              ),
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
              label: Text(_isRecording ? 'Arrêter' : (_audioPath == null ? 'Enregistrer' : 'Ré-enregistrer'), style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
            ),
            if (_audioPath != null && !_isRecording)
              IconButton(
                icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                tooltip: 'Supprimer l\'audio',
                onPressed: _deleteAudio,
              ),
          ],
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Durée: ${_formatDuration(_recordDuration)}',
              style: TextStyle(fontFamily: 'Orbitron', color: theme.colorScheme.primary),
            ),
          ),
      ],
    );
  }
}
