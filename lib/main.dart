import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _species;
  String? _condition;
  ImageSource? _lastUsedSource;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _analysisHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('analysisHistory');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      setState(() {
        _analysisHistory.addAll(historyList.map((item) => {
          'date': DateTime.parse(item['date']),
          'species': item['species'],
          'condition': item['condition'],
          'result': item['result'],
          'imagePath': item['imagePath'],
        }).toList());
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_analysisHistory.map((item) => {
      'date': item['date'].toIso8601String(),
      'species': item['species'],
      'condition': item['condition'],
      'result': item['result'],
      'imagePath': item['imagePath'],
    }).toList());
    await prefs.setString('analysisHistory', historyJson);
  }

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

  Future<String> _analyzeImage(File image) async {
    const serverUrl = 'https://proxy-server-rho-seven.vercel.app/generate';
    const prompt = '''
Ты — эксперт по орнитологии и распознаванию птиц. Твоя задача — определить вид птицы на изображении. Отвечай только при 100% уверенности, исключая слова "наверное", "возможно", "скорее всего". Если на изображении птица (включая живых птиц, рисунки, мультяшных персонажей, скульптуры и другие изображения птиц):  
Проверь, нет ли ошибки в предоставленных данных (например, неверное название вида). Если предоставленные данные содержат ошибку, укажи это в примечании. Следуй строгой инструкции:

1. Если это птица (включая рисунки, мультяшных персонажей, скульптуры и другие изображения птиц), ответь по пунктам:
1. Вид: [название]
2. Описание: [3-5 точных фактов]
3. Состояние: [анализ здоровья, рекомендации если есть]

2. Если это НЕ птица (абсолютно другой объект), напиши:
- Что изображено: [описание]
- Сообщение: На изображении нет птицы. Анализ невозможен. Пожалуйста, загрузите фото птицы.
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

  String _processResponse(String text) {
    text = text.trim();
    if (text.isEmpty) return '⚠️ Пустой ответ от сервера';

    final resultHeader = 'Результаты анализа:';
    if (text.contains(resultHeader)) {
      final parts = text.split(resultHeader);
      text = parts.first + resultHeader + parts.skip(1).join('').replaceAll(resultHeader, '');
    }

    text = text.replaceFirst(
      resultHeader,
      '🧠 Результаты анализа:',
    );

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

    text = text.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s(.*)', multiLine: true),
      (match) => '   • ${match.group(1)}',
    );

    return text;
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

      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
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
        _lastUsedSource = source;
      });

      final response = await _analyzeImage(_selectedImage!);
      setState(() {
        _result = _processResponse(response);
        final lines = response.split('\n');
        for (var line in lines) {
          if (line.startsWith('1. Вид:')) {
            _species = line.replaceFirst('1. Вид:', '').trim();
          } else if (line.startsWith('3. Состояние:')) {
            _condition = line.replaceFirst('3. Состояние:', '').trim();
          }
        }
        
        _analysisHistory.add({
          'date': DateTime.now(),
          'species': _species,
          'condition': _condition,
          'result': _result,
          'imagePath': _selectedImage?.path
        });
        _saveHistory();
      });
    } catch (e) {
      setState(() => _result = '⚠️ Ошибка: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showHistoryDialog() {
    if (_analysisHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История анализов пуста')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('История анализов'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _analysisHistory.length,
            itemBuilder: (context, index) {
              final item = _analysisHistory.reversed.toList()[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: item['imagePath'] != null 
                      ? Image.file(File(item['imagePath']), width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.photo),
                  title: Text(item['species'] ?? 'Неизвестный вид'),
                  subtitle: Text(
                    '${item['date'].toString().substring(0, 16)}\n'
                    'Состояние: ${item['condition']?.split('\n').first ?? ''}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = item['imagePath'] != null 
                          ? File(item['imagePath']) 
                          : null;
                      _result = item['result'];
                      _species = item['species'];
                      _condition = item['condition'];
                    });
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRescue() async {
    if (_species == null || _condition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала проанализируйте изображение птицы')),
      );
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Служба геолокации отключена. Включите ее в настройках.')),
      );
      return;
    }

    var permission = await Permission.location.request();
    if (!permission.isGranted) {
      if (permission.isPermanentlyDenied) {
        await openAppSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Разрешение на местоположение запрещено. Разрешите доступ в настройках.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Для отправки запроса необходимо разрешение на доступ к местоположению')),
        );
      }
      return;
    }

    String location = 'Не удалось определить местоположение';
    String locationLink = '';
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String city = place.locality ?? 'Неизвестный город';
        String street = place.street?.replaceFirst('ул.', '').trim() ?? 'Неизвестная улица';
        String country = place.country ?? 'Неизвестная страна';
        location = 'Страна: $country\nГород: $city\nУлица: $street\nКоординаты: ${position.latitude}, ${position.longitude}';
      } else {
        location = 'Не удалось определить адрес';
      }

      locationLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка получения местоположения: $e')),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => RescueRequestDialog(
        species: _species!,
        condition: _condition!,
        location: location,
        locationLink: locationLink,
        image: _selectedImage,
        onSubmit: (message) async {
          await _sendRescueRequest(
            species: _species!,
            condition: _condition!,
            location: location,
            message: message,
            image: _selectedImage,
            locationLink: locationLink,
          );
        },
      ),
    );
  }

  Future<void> _sendRescueRequest({
    required String species,
    required String condition,
    required String location,
    required String message,
    required File? image,
    required String locationLink,
  }) async {
    setState(() => _isLoading = true);
    
    final smtpServer = gmail('perozhizni@gmail.com', 'bmzo ggza nxuv biqc');

    final emailMessage = Message()
      ..from = Address('perozhizni@gmail.com')
      ..recipients.add('pozitivgame88@gmail.com')
      ..subject = 'Запрос на спасение птицы: $species'
      ..text = '''
Вид: $species
Состояние: $condition
Местоположение: $location
Ссылка на карту: $locationLink
Дополнительное сообщение: $message
''';

    try {
      if (image != null) {
        final compressedImage = await _compressImage(image);
        emailMessage.attachments.add(FileAttachment(
          compressedImage ?? image,
          fileName: 'bird_image.jpg',
        ));
      }

      await send(emailMessage, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запрос успешно отправлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Определитель птиц'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[100],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Перо жизни',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Приложение для определения видов птиц и их состояния. '
                    'Помогаем сохранить пернатых друзей и заботимся об их благополучии.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('История анализов'),
              onTap: () {
                Navigator.pop(context);
                _showHistoryDialog();
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Авторы программы:'),
                  SizedBox(height: 5),
                  Text('Кривошеенко Данил Дмитриевич'),
                  Text('Панов Максим Романович'),
                  Text('Полежаев Дмитрий Дмитриевич'),
                ],
              ),
            ),
          ],
        ),
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
                    onPressed: _isLoading 
                        ? null 
                        : () => _pickImage(ImageSource.camera),
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
              if (_species != null && _condition != null && _lastUsedSource == ImageSource.camera)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _requestRescue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Вызвать спасателей'),
                    ),
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
          text: parts[0],
          style: const TextStyle(color: Colors.black),
        ));
        spans.add(const TextSpan(
          text: '• ',
          style: TextStyle(color: Colors.black),
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

class RescueRequestDialog extends StatefulWidget {
  final String species;
  final String condition;
  final String location;
  final String locationLink;
  final File? image;
  final Function(String) onSubmit;

  const RescueRequestDialog({
    super.key,
    required this.species,
    required this.condition,
    required this.location,
    required this.locationLink,
    required this.image,
    required this.onSubmit,
  });

  @override
  State<RescueRequestDialog> createState() => _RescueRequestDialogState();
}

class _RescueRequestDialogState extends State<RescueRequestDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(
        child: Text(
          'Запрос на спасение',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вид: ${widget.species}'),
            const SizedBox(height: 10),
            Text('Состояние: ${widget.condition}'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Местоположение:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Копировать'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.locationLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Местоположение скопировано')),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.only(left: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            Text(widget.location),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Дополнительное сообщение:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                  borderRadius: BorderRadius.circular(4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue, width: 1.0),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                  borderRadius: BorderRadius.circular(4),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _isSending ? null : () => Navigator.pop(context),
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isSending
                    ? null
                    : () async {
                        setState(() => _isSending = true);
                        await widget.onSubmit(_messageController.text);
                        if (mounted) {
                          setState(() => _isSending = false);
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Подтвердить отправку',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}