// TODO Implement this library.
// bird_net_analyzer_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io';
import 'package:bird_identifier/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audio_waveforms/audio_waveforms.dart';

// Остальные импорты, которые нужны для этого класса

// =============== ОПРЕДЕЛЕНИЕ _WavParseResult ===============
class _WavParseResult {
  final List<double> samples;
  final int sampleRate;
  final int channels;
  _WavParseResult({required this.samples, required this.sampleRate, required this.channels});
}

// =============== КЛАСС BirdNetAnalyzerScreen ===============
class BirdNetAnalyzerScreen extends StatefulWidget {
  final String? initialFilePath;
  final Function(String filePath, String result)? onAnalysisComplete;

  const BirdNetAnalyzerScreen({Key? key, this.initialFilePath, this.onAnalysisComplete}) : super(key: key);

  @override
  State<BirdNetAnalyzerScreen> createState() => _BirdNetAnalyzerScreenState();
}

class _BirdNetAnalyzerScreenState extends State<BirdNetAnalyzerScreen> {
  Interpreter? _audioInterpreter;
  Interpreter? _metaInterpreter;
  List<String> _labels = [];
  bool _modelLoaded = false;
  bool _isAnalyzing = false;
  String? _geminiResult;
  late PlayerController _playerController;
  bool _isPlaying = false;
  String? _currentAudioPath;

  static const String _serverUrl = 'https://gemini-proxy-nine-alpha.vercel.app';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _currentAudioPath = widget.initialFilePath;
    if (widget.initialFilePath != null) {
      setState(() {
        _isAnalyzing = true;
      });
    }
    _loadModelsAndLabels().then((_) {
      if (widget.initialFilePath != null && _modelLoaded) {
        _analyzeFile(File(widget.initialFilePath!));
      } else if (widget.initialFilePath != null && !_modelLoaded) {
        setState(() {
          _isAnalyzing = false;
          _geminiResult = 'Ошибка: не удалось загрузить модели для анализа.';
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    _playerController = PlayerController();
  }

  Future<void> _playRecording() async {
  if (_currentAudioPath == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет доступной записи для воспроизведения')));
    return;
  }

  try {
    // Если уже воспроизводится - останавливаем
    if (_isPlaying) {
      await _stopPlaying();
      return;
    }

    setState(() => _isPlaying = true);
    final file = File(_currentAudioPath!);
    
    if (await file.exists()) {
      final length = await file.length();
      if (length == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Файл пустой')));
        setState(() => _isPlaying = false);
        return;
      }
      
      // Останавливаем предыдущее воспроизведение и готовим новый файл
      await _playerController.stopPlayer();
      await _playerController.preparePlayer(path: _currentAudioPath!);
      await _playerController.startPlayer();
      
      // Слушаем завершение воспроизведения
      _playerController.onPlayerStateChanged.listen((state) {
        if (mounted) {
          if (state == PlayerState.stopped) {
            setState(() => _isPlaying = false);
          } else if (state == PlayerState.playing) {
            setState(() => _isPlaying = true);
          } else if (state == PlayerState.paused) {
            setState(() => _isPlaying = false);
          }
        }
      });
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Файл не найден')));
      setState(() => _isPlaying = false);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка воспроизведения: $e')));
    setState(() => _isPlaying = false);
  }
}

  Future<void> _stopPlaying() async {
  try {
    await _playerController.stopPlayer();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  } catch (e) {
    print('Ошибка остановки: $e');
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }
}

  @override
  void dispose() {
    _audioInterpreter?.close();
    _metaInterpreter?.close();
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _loadModelsAndLabels() async {
    try {
      try {
        _audioInterpreter = await Interpreter.fromAsset('assets/birdnet/audio-model.tflite', options: InterpreterOptions()..threads = 4);
      } catch (e) {
        try {
          _audioInterpreter = await Interpreter.fromAsset('birdnet/audio-model.tflite', options: InterpreterOptions()..threads = 4);
        } catch (e2) {
          _audioInterpreter = null;
        }
      }
      try {
        _metaInterpreter = await Interpreter.fromAsset('assets/birdnet/meta-model.tflite', options: InterpreterOptions()..threads = 2);
      } catch (_) {
        _metaInterpreter = null;
      }
      try {
        final raw = await rootBundle.loadString('assets/birdnet/labels/ru.txt');
        _labels = raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } catch (_) {
        try {
          final raw = await rootBundle.loadString('assets/birdnet/labels/en_us.txt');
          _labels = raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } catch (e) {
          _labels = [];
        }
      }
      setState(() {
        _modelLoaded = _audioInterpreter != null;
      });
    } catch (e) {
      setState(() => _modelLoaded = false);
    }
  }

  Future<void> _pickAndAnalyzeFile() async {
    if (_isAnalyzing || !_modelLoaded) return;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'aac', 'flac', 'ogg', 'webm'],
    );

    if (res == null || res.files.isEmpty) return;

    final path = res.files.single.path!;
    // ИСПРАВЛЕНО: обновляем текущий путь
    setState(() {
      _currentAudioPath = path;
      _isAnalyzing = true;
      _geminiResult = null;
    });

    await _analyzeFile(File(path));
  }

   Future<void> _startNewRecording() async {
  // Останавливаем текущее воспроизведение
  if (_isPlaying) {
    await _stopPlaying();
  }
  
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => VoiceRecorderDialog(
      onAnalyze: (filePath) {
        Navigator.pop(context, filePath);
      },
    ),
  );
  
  if (result != null && mounted) {
    setState(() {
      _currentAudioPath = result;
      _isAnalyzing = true;
      _geminiResult = null;
    });
    await _analyzeFile(File(result));
  }
}

  Future<void> _analyzeFile(File file) async {
    setState(() {
      _isAnalyzing = true;
      _geminiResult = null;
      _currentAudioPath = file.path; // ОБНОВЛЯЕМ текущий путь
    });

    if (!_modelLoaded || _audioInterpreter == null) {
      setState(() {
        _isAnalyzing = false;
        _geminiResult = 'Ошибка: модель не загружена.';
      });
      return;
    }

    try {
      final String filePath = file.path.toLowerCase();
      _WavParseResult? parsed;

      if (!await file.exists()) {
        setState(() {
          _isAnalyzing = false;
          _geminiResult = 'Ошибка: файл не существует.';
        });
        return;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        setState(() {
          _isAnalyzing = false;
          _geminiResult = 'Ошибка: файл пустой.';
        });
        return;
      }

      print('Анализируем файл: $filePath, размер: $fileSize байт');

      if (filePath.endsWith('.wav')) {
        setState(() {
          _geminiResult = 'Чтение WAV файла...';
        });
        
        try {
          final bytes = await file.readAsBytes();
          parsed = _parseWav(bytes);
          if (parsed == null) {
            throw Exception('Не удалось распарсить WAV файл');
          }
          print('WAV файл успешно распарсен: ${parsed.samples.length} samples, ${parsed.sampleRate} Hz');
        } catch (e) {
          print('Ошибка парсинга WAV: $e');
          setState(() {
            _geminiResult = 'Конвертация аудио на сервере...';
          });
          parsed = await _convertAudioOnServer(file);
        }
      } else {
        setState(() {
          _geminiResult = 'Конвертация аудио на сервере...';
        });
        parsed = await _convertAudioOnServer(file);
      }

      if (parsed == null) {
        setState(() {
          _isAnalyzing = false;
          _geminiResult = 'Ошибка: не удалось обработать аудиофайл.\n'
              'Поддерживаемые форматы: WAV, MP3, M4A, AAC, FLAC, OGG, WEBM\n'
              'Убедитесь, что файл не поврежден.';
        });
        return;
      }

      List<double> samples = parsed.samples;
      int sr = parsed.sampleRate;
      const targetSR = 48000;

      print('Получено samples: ${samples.length}, sample rate: $sr');

      if (sr != targetSR) {
        setState(() {
          _geminiResult = 'Ресемплинг аудио...';
        });
        samples = _resampleLinear(samples, sr, targetSR);
      }

      const requiredLen = 10 * 48000; // 10 секунд * 48000 Hz
      
      if (samples.length < requiredLen) {
        samples = [...samples, ...List<double>.filled(requiredLen - samples.length, 0.0)];
        print('Запись дополнена до 10 секунд');
      } else if (samples.length > requiredLen) {
        samples = samples.sublist(0, requiredLen);
        print('Взяты первые 10 секунд из записи');
      }

      print('Анализируемый фрагмент: ${samples.length} samples (${samples.length / 48000} секунд)');

      setState(() {
        _geminiResult = 'Анализ аудио BirdNET...';
      });

      final predictions = await _runAudioModelOnWave(samples);
      final topResults = predictions.take(3).toList();

      print('Получено предсказаний: ${predictions.length}');
      for (var result in topResults) {
        print('${result.key}: ${result.value}');
      }

      if (topResults.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _geminiResult = 'Не удалось определить птицу.\nПопробуйте запись с более четким пением птиц.';
        });
        return;
      }

      final birdNetResults = topResults.map((e) => '${e.key}: ${e.value.toStringAsFixed(4)}').join('\n');
      
      setState(() {
        _geminiResult = 'Получение анализа...';
      });

      final geminiResponse = await _sendBirdNetResultsToGemini(birdNetResults);

      if (widget.onAnalysisComplete != null) {
        widget.onAnalysisComplete!(file.path, geminiResponse);
      }

      setState(() {
        _isAnalyzing = false;
        _geminiResult = _processResponse(geminiResponse);
      });
    } catch (e) {
      print('Ошибка анализа: $e');
      setState(() {
        _isAnalyzing = false;
        _geminiResult = 'Ошибка анализа: ${e.toString()}';
      });
    }
  }

  Future<_WavParseResult?> _convertAudioOnServer(File audioFile) async {
    try {
      final audioBytes = await audioFile.readAsBytes();
      final audioBase64 = base64Encode(audioBytes);

      final response = await http.post(
        Uri.parse('$_serverUrl/convert-audio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio_data': audioBase64,
          'filename': audioFile.path.split('/').last,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (jsonResponse['success'] == true) {
          final wavBase64 = jsonResponse['wav_data'] as String;
          final wavBytes = base64Decode(wavBase64);
          
          return _parseWav(wavBytes);
        } else {
          throw Exception(jsonResponse['error'] ?? 'Unknown conversion error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка конвертации через сервер: $e');
      return null;
    }
  }

  Future<String> _sendBirdNetResultsToGemini(String birdNetResults) async {
    const prompt = '''
Ты — эксперт по орнитологии. Проанализируй результаты BirdNET по аудио. Строго следуй инструкции:
1. Определи только первую строку (самая вероятная птица).
2. Если указан конкретный вид (например, "Виргинский филин") → напиши только общий род ("Филин").
3. Игнорируй отрицательные проценты, указывай уверенность 70–90%.
4. Если в результатах первым идёт "Engine", а вторым "Human" → это Человек. Затем напиши что это не птица и пректати анализ
5. Если это не птица и не человек → "⚠️ На записи нет птицы. Анализ невозможен."
Формат ответа:
🦜 Вид: [Название]  
📘 Факты: [3–5 фактов о виде]  
🌐 Среда обитания: [описание]  
🎶 Голос: [описание пения]  
❤️ Уверенность: [70–90%]  
''';
    
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/analyze-audio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'birdnet_results': birdNetResults,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse['response'] ?? 'Не удалось получить ответ от сервера';
      } else {
        return 'Ошибка сервера: ${response.statusCode}';
      }
    } catch (e) {
      return 'Ошибка отправки: $e';
    }
  }

  Future<List<MapEntry<String, double>>> _runAudioModelOnWave(List<double> waveSamples) async {
    final interpreter = _audioInterpreter!;
    final inputTensor = interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape;
    final int expectedElements = inputShape.skip(1).fold(1, (a, b) => a * b);
    final List<double> flat = List<double>.filled(expectedElements, 0.0);
    for (int i = 0; i < math.min(waveSamples.length, expectedElements); i++) {
      flat[i] = waveSamples[i];
    }
    Object input;
    if (inputShape.length == 2) {
      input = [flat];
    } else if (inputShape.length == 3) {
      final int dim1 = inputShape[1];
      final int dim2 = inputShape[2];
      final List<List<double>> twoD = List.generate(dim1, (i) {
        if (dim2 == 1) return [flat[i]];
        return List<double>.filled(dim2, i < flat.length ? flat[i] : 0.0);
      });
      input = [twoD];
    } else if (inputShape.length == 4) {
      final int h = inputShape[1];
      final int w = inputShape[2];
      final int c = inputShape[3];
      List<List<List<double>>> arr = List.generate(h, (i) => List.generate(w, (j) => List<double>.filled(c, 0.0)));
      int idx = 0;
      for (int i = 0; i < h; i++) {
        for (int j = 0; j < w; j++) {
          for (int k = 0; k < c; k++) {
            if (idx < flat.length) arr[i][j][k] = flat[idx++];
          }
        }
      }
      input = [arr];
    } else {
      input = [flat];
    }
    final out0 = interpreter.getOutputTensor(0);
    final outShape = out0.shape;
    final int outSize = outShape.skip(1).fold(1, (a, b) => a * b);
    dynamic output;
    if (outShape.length == 2) {
      output = List.generate(outShape[0], (_) => List<double>.filled(outShape[1], 0.0));
    } else if (outShape.length == 3) {
      output = List.generate(outShape[0], (_) => List.generate(outShape[1], (_) => List<double>.filled(outShape[2], 0.0)));
    } else {
      output = List.generate(1, (_) => List<double>.filled(outSize, 0.0));
    }
    interpreter.run(input, output);
    List<MapEntry<String, double>> results = [];
    if (outShape.length >= 2 && _labels.isNotEmpty && outShape.last == _labels.length) {
      final List<double> probs = (output[0] as List).cast<double>();
      for (int i = 0; i < probs.length; i++) {
        results.add(MapEntry(_labels[i], probs[i]));
      }
      results.sort((a, b) => b.value.compareTo(a.value));
      return results.take(10).toList();
    } else {
      if (_metaInterpreter != null) {
        final metaIn = _metaInterpreter!.getInputTensor(0);
        final metaShape = metaIn.shape;
        if (metaShape.length == 2 && metaShape[1] == outSize) {
          List<double> embedding;
          if (outShape.length == 2) {
            embedding = (output[0] as List).cast<double>();
          } else {
            embedding = [];
            void _appendAny(dynamic x) {
              if (x is double) embedding.add(x);
              else if (x is List) x.forEach(_appendAny);
            }
            _appendAny(output);
          }
          var metaInput = [embedding];
          final metaOut0 = _metaInterpreter!.getOutputTensor(0);
          final metaOutShape = metaOut0.shape;
          var metaOut = List.generate(metaOutShape[0], (_) => List<double>.filled(metaOutShape[1], 0.0));
          _metaInterpreter!.run(metaInput, metaOut);
          final List<double> probs = (metaOut[0] as List).cast<double>();
          if (_labels.isNotEmpty && probs.length == _labels.length) {
            for (int i = 0; i < probs.length; i++) results.add(MapEntry(_labels[i], probs[i]));
            results.sort((a, b) => b.value.compareTo(a.value));
            return results.take(10).toList();
          } else {
            for (int i = 0; i < math.min(10, probs.length); i++) results.add(MapEntry('class_$i', probs[i]));
            return results;
          }
        } else {
          List<double> emb;
          if (outShape.length == 2) emb = (output[0] as List).cast<double>();
          else {
            emb = [];
            void _appendAny(dynamic x) {
              if (x is double) emb.add(x);
              else if (x is List) x.forEach(_appendAny);
            }
            _appendAny(output);
          }
          for (int i = 0; i < math.min(10, emb.length); i++) results.add(MapEntry('emb_$i', emb[i]));
          return results;
        }
      } else {
        List<double> emb;
        if (outShape.length == 2) emb = (output[0] as List).cast<double>();
        else {
          emb = [];
          void _appendAny(dynamic x) {
            if (x is double) emb.add(x);
            else if (x is List) x.forEach(_appendAny);
          }
          _appendAny(output);
        }
        for (int i = 0; i < math.min(10, emb.length); i++) results.add(MapEntry('emb_$i', emb[i]));
        return results;
      }
    }
  }

  String _processResponse(String text) {
    text = text.trim();
    if (text.isEmpty) return '⚠️ Пустой ответ';
    
    text = text.replaceAll(RegExp(r'^\d\.\s*', multiLine: true), '');
    
    text = text.replaceAllMapped(RegExp(r'^\s*[\*\-]\s+(.*)', multiLine: true), 
        (match) => '   • ${match.group(1)}');
    
    text = text.replaceAllMapped(RegExp(r'^Вид:(.*)', multiLine: true), 
        (match) => '🦜 Вид:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^Описание:(.*)', multiLine: true), 
        (match) => '📘 Описание:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^(Факты|Уверенность):(.*)', multiLine: true), 
        (match) => '❤️ ${match.group(1)}:${match.group(2)}');
    text = text.replaceAllMapped(RegExp(r'^(Среда|Место обитания|Источник):(.*)', multiLine: true), 
        (match) => '🌐 ${match.group(1)}:${match.group(2)}');
    text = text.replaceAllMapped(RegExp(r'^(Голос|Звук|Пение):(.*)', multiLine: true), 
        (match) => '🎶 ${match.group(1)}:${match.group(2)}');
    
    return text;
  }

  List<TextSpan> _buildTextSpans(String text) {
    final lines = text.split('\n');
    final spans = <TextSpan>[];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.trim().startsWith('•') || line.trim().startsWith('-') || line.trim().startsWith('*')) {
        final markerMatch = RegExp(r'^(\s*)([\*\-•])\s+(.*)').firstMatch(line);
        
        if (markerMatch != null) {
          final indent = markerMatch.group(1) ?? '';
          final marker = markerMatch.group(2) ?? '•';
          final content = markerMatch.group(3) ?? '';
          
          spans.add(TextSpan(text: indent, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
          spans.add(TextSpan(text: '$marker ', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
          spans.add(TextSpan(text: content, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        } else {
          spans.add(TextSpan(text: line, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        }
      } else {
        spans.add(TextSpan(text: line, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
      }
      
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return spans;
  }

  _WavParseResult? _parseWav(Uint8List bytes) {
    if (bytes.length < 44) return null;
    final bd = bytes.buffer.asByteData();
    int dataStart = -1;
    int dataSize = 0;
    for (int i = 0; i < bytes.length - 8; i++) {
      if (bytes[i] == 0x64 && bytes[i + 1] == 0x61 && bytes[i + 2] == 0x74 && bytes[i + 3] == 0x61) {
        dataSize = bd.getUint32(i + 4, Endian.little);
        dataStart = i + 8;
        break;
      }
    }
    if (dataStart == -1) {
      dataStart = 44;
      dataSize = bytes.length - 44;
    }
    final format = bd.getUint16(20, Endian.little);
    final numChannels = bd.getUint16(22, Endian.little);
    final sampleRate = bd.getUint32(24, Endian.little);
    final bitsPerSample = bd.getUint16(34, Endian.little);
    if (format != 1 || bitsPerSample != 16) {
      return null;
    }
    final int bytesPerSample = (bitsPerSample ~/ 8) * numChannels;
    final int numSamples = dataSize ~/ bytesPerSample;
    List<double> samples = List<double>.filled(numSamples, 0.0);
    int sampleIdx = 0;
    for (int offset = dataStart; offset + 1 < dataStart + dataSize; offset += bytesPerSample) {
      final int16 = bd.getInt16(offset, Endian.little);
      samples[sampleIdx++] = int16 / 32768.0;
    }
    return _WavParseResult(samples: samples, sampleRate: sampleRate, channels: numChannels);
  }

  List<double> _resampleLinear(List<double> input, int srcRate, int dstRate) {
    if (srcRate == dstRate) return input;
    final inputLen = input.length;
    final double ratio = dstRate / srcRate;
    final int outputLen = (inputLen * ratio).round();
    final List<double> out = List<double>.filled(outputLen, 0.0);
    for (int i = 0; i < outputLen; i++) {
      final double srcPos = i / ratio;
      final int idx = srcPos.floor();
      final double frac = srcPos - idx;
      final double a = (idx >= 0 && idx < inputLen) ? input[idx] : 0.0;
      final double b = (idx + 1 >= 0 && idx + 1 < inputLen) ? input[idx + 1] : 0.0;
      out[i] = a + (b - a) * frac;
    }
    return out;
  }

  @override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;
  
  return Scaffold(
    appBar: AppBar(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Анализ птиц по голосу'),
          const SizedBox(height: 2),
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Text(
                'powered by BirdNET',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.normal,
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
    ),
    body: _isAnalyzing
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'assets/animations/Loading.json',
                    repeat: true,
                    frameRate: FrameRate(60),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _geminiResult ?? 'Анализируем аудио...', 
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : _geminiResult == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.audio_file, size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    const Text(
                      'Выберите аудиофайл для анализа', 
                      style: TextStyle(fontSize: 16), 
                      textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 30),
                    
                    // Кнопка прослушать - проверяет _currentAudioPath
                    if (_currentAudioPath != null) ...[
                      ElevatedButton.icon(
                        onPressed: _isPlaying ? _stopPlaying : _playRecording,
                        icon: _isPlaying 
                            ? const Icon(Icons.stop)
                            : const Icon(Icons.play_arrow),
                        label: Text(_isPlaying ? "Остановить" : "Прослушать запись"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          backgroundColor: _isPlaying ? Colors.orange.shade600 : Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    ElevatedButton.icon(
                      onPressed: _modelLoaded ? _pickAndAnalyzeFile : null,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Выбрать аудиофайл'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _modelLoaded ? _startNewRecording : null,
                      icon: const Icon(Icons.mic),
                      label: const Text('Новая запись'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                    if (!_modelLoaded) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      const Text('Загрузка моделей...'),
                    ],
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode ? [Color(0xFF1D1E33), Color(0xFF2D2E44)] : [Colors.white, Colors.blue.shade50],
                          ),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(isDarkMode ? 0.2 : 0.1), blurRadius: 20, offset: Offset(0, 10))],
                          border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text('🔍 Результаты анализа:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(color: colorScheme.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                              child: SelectableText.rich(
                                TextSpan(children: _buildTextSpans(_geminiResult!)),
                                style: TextStyle(fontSize: 16, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Кнопка прослушать в результатах - проверяет _currentAudioPath
                      if (_currentAudioPath != null) 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
  onPressed: _isPlaying ? _stopPlaying : _playRecording,
  icon: _isPlaying ? const Icon(Icons.stop) : const Icon(Icons.play_arrow),
  label: Text(_isPlaying ? "Остановить воспроизведение" : "Прослушать запись"),
  style: ElevatedButton.styleFrom(
    backgroundColor: _isPlaying ? Colors.orange.shade600 : Colors.blue.shade600,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
  ),
),
                        ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickAndAnalyzeFile,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Выбрать файл'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startNewRecording,
                              icon: const Icon(Icons.mic),
                              label: const Text('Новая запись'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}