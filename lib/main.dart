import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() => runApp(MusicPlayerApp());

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MusicPlayer(),
      theme: ThemeData.dark(),
    );
  }
}

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<File> _playlist = [];
  int _currentTrackIndex = -1;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.onPlayerCompletion.listen((_) => _playNextTrack());
  }

  Future<void> _loadPlaylist() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _playlist = Directory(result)
            .listSync()
            .where((file) => file.path.endsWith('.mp3'))
            .map((file) => File(file.path))
            .toList();
        _currentTrackIndex = _playlist.isNotEmpty ? 0 : -1;
      });
      if (_playlist.isEmpty) {
        _showAlert('No MP3 files found in the selected folder.');
      }
    }
  }

  void _playTrack() async {
    if (_playlist.isEmpty || _currentTrackIndex < 0) {
      _showAlert("Please load a playlist first.");
      return;
    }

    if (_isPaused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.play(_playlist[_currentTrackIndex].path, isLocal: true);
      _audioPlayer.setVolume(_volume);
    }

    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });
  }

  void _pauseTrack() async {
    await _audioPlayer.pause();
    setState(() {
      _isPaused = true;
      _isPlaying = false;
    });
  }

  void _stopTrack() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  void _playNextTrack() {
    setState(() {
      _currentTrackIndex = (_currentTrackIndex + 1) % _playlist.length;
    });
    _playTrack();
  }

  void _shufflePlaylist() {
    setState(() {
      _playlist.shuffle();
      _currentTrackIndex = 0;
    });
    _playTrack();
  }

  void _removeTrack(int index) {
    if (_playlist.isNotEmpty) {
      setState(() {
        _playlist.removeAt(index);
        if (_currentTrackIndex >= _playlist.length) {
          _currentTrackIndex = max(0, _playlist.length - 1);
        }
        _stopTrack();
      });
      if (_playlist.isNotEmpty) {
        _playTrack();
      }
    }
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume;
    });
    _audioPlayer.setVolume(volume);
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text("Music Player"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _playlist.isNotEmpty
                ? 'Playing: ${_playlist[_currentTrackIndex].path.split('/').last}'
                : 'No track loaded',
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPlaylist,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: Text("Load Playlist"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _playlist.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_playlist[index].path.split('/').last,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      _currentTrackIndex = index;
                    });
                    _playTrack();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTrack(index),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _playTrack,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text("Play"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _pauseTrack,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text("Pause"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _playNextTrack,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("Next"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _shufflePlaylist,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text("Shuffle"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _stopTrack,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Stop"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Slider(
            value: _volume,
            onChanged: _setVolume,
            min: 0,
            max: 1,
            divisions: 10,
            label: "Volume",
          ),
        ],
      ),
    );
  }
}
