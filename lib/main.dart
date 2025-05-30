import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

void main() => runApp(const BirdIdentifierApp());

class BirdIdentifierApp extends StatelessWidget {
  const BirdIdentifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Определитель птиц',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Colors.blue,
          selectionHandleColor: Colors.blue,
        ),
      ),
      home: const BirdIdentifierScreen(),
    );
  }
}

class BirdIdentifierScreen extends StatefulWidget {
  const BirdIdentifierScreen({super.key});

  @override
  State<BirdIdentifierScreen> createState() => _BirdIdentifierScreenState();
}

class _BirdIdentifierScreenState extends State<BirdIdentifierScreen> {
  File? _selectedImage;
  String _result = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<bool> _checkInternet() async {
    final endpoints = [
      'https://1.1.1.1',
      'https://8.8.8.8',
      'https://api.github.com',
    ];

    for (int attempt = 0; attempt < 2; attempt++) {
      for (final endpoint in endpoints) {
        try {
          final response = await http.get(Uri.parse(endpoint)).timeout(
            const Duration(seconds: 2),
            onTimeout: () => http.Response('Timeout', 408),
          );
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return true;
          }
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
  if (_isLoading) return;

  try {
    if (!await _checkInternet()) {
      setState(() => _result = '⚠️ Ошибка: Нет интернет-соединения. Проверьте подключение и попробуйте снова.');
      return;
    }

    if (source == ImageSource.camera) {
      if (!Platform.isAndroid && !Platform.isIOS) {
        setState(() => _result = '⚠️ Ошибка: Камера не поддерживается на этой платформе');
        return;
      }
      
      // Всегда запрашиваем разрешение, даже если ранее было запрещено
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        // Показываем объяснение, если разрешение было отклонено
        if (status.isPermanentlyDenied) {
          // Открываем настройки, если пользователь выбрал "больше не спрашивать"
          await openAppSettings();
          setState(() => _result = '⚠️ Разрешение было полностью запрещено. Пожалуйста, предоставьте доступ к камере в настройках приложения.');
        } else {
          setState(() => _result = '⚠️ Для использования камеры необходимо предоставить разрешение');
        }
        return;
      }
    }

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) {
        setState(() => _result = '⚠️ Ошибка: Изображение не выбрано');
        return;
      }

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isLoading = true;
        _result = '';
      });

      final response = await _analyzeImage(_selectedImage!);
      setState(() => _result = _processResponse(response));
    } catch (e) {
      setState(() => _result = '⚠️ Ошибка: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _analyzeImage(File image) async {
    const serverUrl = 'https://proxy-server-rho-seven.vercel.app/generate';
    const prompt = '''
Ты — эксперт по распознаванию птиц. Отвечай только когда абсолютно уверен на 100%. Избегай слов: "наверное", "возможно", "скорее всего". Проанализируй изображение и строго следуй инструкции, Отвечай четко, без слов неуверенности:

1. Если это птица (включая рисунки, мультяшных персонажей, скульптуры и другие изображения птиц), ответь по пунктам:
1. Вид: [название]
2. Описание: [3-5 точных фактов]
3. Состояние: [анализ здоровья, рекомендации если есть]

2. Если это НЕ птица (абсолютно другой объект), напиши:
- Что изображено: [описание]
- Сообщение: На изображении нет птицы. Анализ невозможен.
''';

    try {
      final compressedImage = await _compressImage(image);
      if (compressedImage == null) {
        return 'Ошибка: Не удалось сжать изображение';
      }

      final imageBytes = await compressedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'image_base64': base64Image,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['response'] ?? 'Не получилось распознать ответ';
      }
      return 'Ошибка сервера: ${response.statusCode}';
    } catch (e) {
      return 'Ошибка: ${e.toString()}';
    }
  }

  Future<File?> _compressImage(File image) async {
    try {
      final fileSize = await image.length();
      if (fileSize < 1000000) return image;

      final tempDir = Directory.systemTemp;
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        return null;
      }

      final compressedSize = await compressedFile.length();
      if (compressedSize > 10000000) {
        return null;
      }

      return File(compressedFile.path);
    } catch (e) {
      print('Compression error: $e');
      return null;
    }
  }

  String _processResponse(String text) {
    text = text.trim();
    if (text.isEmpty) return '⚠️ Пустой ответ от сервера';

    // Удаляем все вхождения "Результаты анализа:", кроме первого
    final resultHeader = 'Результаты анализа:';
    if (text.contains(resultHeader)) {
      final parts = text.split(resultHeader);
      text = parts.first + resultHeader + parts.skip(1).join('').replaceAll(resultHeader, '');
    }

    // Добавляем emoji только к первому вхождению
    text = text.replaceFirst(
      resultHeader,
      '🧠 Результаты анализа:',
    );

    // Остальная обработка остается без изменений
    text = text.replaceAllMapped(
      RegExp(r'^1\.\s*Вид:(.*)', multiLine: true),
      (match) => '🦜 Вид:${match.group(1)}',
    );

    text = text.replaceAllMapped(
      RegExp(r'^2\.\s*Описание:(.*)', multiLine: true),
      (match) => '📘 Описание:${match.group(1)}',
    );

    text = text.replaceAllMapped(
      RegExp(r'^3\.\s*Состояние:(.*)', multiLine: true),
      (match) => '❤️ Состояние:${match.group(1)}',
    );

    // Черные точки вместо синих
    text = text.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s(.*)', multiLine: true),
      (match) => '   • ${match.group(1)}',
    );

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Определитель птиц'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 188, 230, 250),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload, size: 50, color: Colors.blue),
                          const SizedBox(height: 8),
                          const Text(
                            'Загрузите изображение птицы',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Камера"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Галерея"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_result.isNotEmpty || _isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? Center(
                          child: Lottie.asset(
                            'assets/animations/Animation.json',
                            width: 150,
                            height: 150,
                            repeat: true,
                            frameRate: FrameRate(60),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                '🧠 Результаты анализа:',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SelectableText.rich(
                              TextSpan(
                                children: _buildTextSpans(_result),
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String text) {
    final lines = text.split('\n');
    final spans = <TextSpan>[];

    for (var line in lines) {
      if (line.contains('•')) {
        final parts = line.split('•');
        spans.add(TextSpan(
          text: parts[0], // Spaces before the bullet
          style: const TextStyle(color: Colors.black),
        ));
        spans.add(const TextSpan(
          text: '• ',
          style: TextStyle(color: Colors.black), // Black bullet
        ));
        spans.add(TextSpan(
          text: parts[1].trim(),
          style: const TextStyle(color: Colors.black),
        ));
      } else {
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(color: Colors.black),
        ));
      }
      spans.add(const TextSpan(text: '\n'));
    }

    return spans;
  }
}