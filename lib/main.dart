import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const BirdIdentifierApp());

class BirdIdentifierApp extends StatefulWidget {
  const BirdIdentifierApp({super.key});

  @override
  _BirdIdentifierAppState createState() => _BirdIdentifierAppState();
}

class _BirdIdentifierAppState extends State<BirdIdentifierApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    _saveTheme(isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru'),
          Locale('en'),
        ],
        locale: const Locale('ru'),
        title: 'Определитель птиц',
        scaffoldMessengerKey: _scaffoldMessengerKey,
        theme: ThemeData(
          fontFamily: 'ComicSans',
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
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
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.blue[500];
              }
              return Colors.grey[300];
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.blue[700];
              }
              return Colors.grey[400];
            }),
          ),
        ),
        darkTheme: ThemeData(
          fontFamily: 'ComicSans',
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.grey[900],
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Color.fromARGB(255, 33, 33, 33),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Colors.blue,
            selectionHandleColor: Colors.blue,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.blue[300];
              }
              return Colors.grey[400];
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.blue[700];
              }
              return Colors.grey[600];
            }),
          ),
        ),
        themeMode: _themeMode,
        home: BirdIdentifierScreen(
          onThemeToggle: _toggleTheme,
          scaffoldMessengerKey: _scaffoldMessengerKey,
        ),
      ),
    );
  }
}

class BirdIdentifierScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const BirdIdentifierScreen({super.key, required this.onThemeToggle, required this.scaffoldMessengerKey});

  @override
  State<BirdIdentifierScreen> createState() => _BirdIdentifierScreenState();
}

class _BirdIdentifierScreenState extends State<BirdIdentifierScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  String _result = '';
  bool _isLoading = false;
  String? _species;
  String? _condition;
  bool _isCameraSource = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _analysisHistory = [];
  final List<Map<String, dynamic>> _rescueHistory = [];
  late AnimationController _animationController;
  late AnimationController _rescuePulseController;
  late Animation<double> _rescuePulseScale;
  late Animation<Color?> _rescuePulseColor;
  bool _saveCameraPhotos = false;

  bool get _showRescueButton {
    if (_species == null || _condition == null) return false;
    if (!_isCameraSource) return false;
    if (_result.contains('🌐 Источник:')) return false;

    final condition = _condition!.toLowerCase();
    return condition.contains(RegExp(
      r'(травм|не может|рана|слаб|болен|слом|плох|нуждает|помощ|кров|ушиб)',
      caseSensitive: false,
    ));
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadRescueHistory();
    _loadSaveCameraPhotos();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rescuePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _rescuePulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _rescuePulseController, curve: Curves.easeInOut),
    );

    _rescuePulseColor = ColorTween(
      begin: Colors.redAccent,
      end: Colors.red,
    ).animate(
      CurvedAnimation(parent: _rescuePulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rescuePulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSaveCameraPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveCameraPhotos = prefs.getBool('saveCameraPhotos') ?? false;
    });
  }

  Future<void> _saveCameraPhotosSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('saveCameraPhotos', value);
    setState(() {
      _saveCameraPhotos = value;
    });
  }

  Future<void> _loadRescueHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('rescueHistory');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      setState(() {
        _rescueHistory.addAll(historyList.map((item) {
          return {
            'date': DateTime.parse(item['date']),
            'species': item['species'],
            'condition': item['condition'],
            'location': item['location'],
            'message': item['message'],
            'imagePath': item['imagePath'],
          };
        }).toList());
      });
    }
  }

  Future<void> _saveRescueHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_rescueHistory.map((item) => {
          'date': item['date'].toIso8601String(),
          'species': item['species'],
          'condition': item['condition'],
          'location': item['location'],
          'message': item['message'],
          'imagePath': item['imagePath'],
        }).toList());
    await prefs.setString('rescueHistory', historyJson);
  }

  Future<String?> _saveImagePermanently(File image) async {
  if (!_saveCameraPhotos) return null;
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'bird_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${directory.path}/$fileName';
    final newFile = await image.copy(newPath);
    return newFile.path;
  } catch (e) {
    print('Ошибка сохранения изображения: $e');
    return null;
  }
}

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('analysisHistory');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      setState(() {
        _analysisHistory.addAll(historyList.map((item) {
          final imagePath = item['imagePath'];
          if (imagePath == null) return null;

          final file = File(imagePath);
          if (!file.existsSync()) {
            return {
              'date': DateTime.parse(item['date']),
              'species': item['species'],
              'condition': item['condition'],
              'result': item['result'],
              'imagePath': null,
            };
          }

          return {
            'date': DateTime.parse(item['date']),
            'species': item['species'],
            'condition': item['condition'],
            'result': item['result'],
            'imagePath': imagePath,
          };
        }).whereType<Map<String, dynamic>>().toList());
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
      print('Исходный размер изображения: $fileSize байт');
      if (fileSize < 500000) return image;

      final tempDir = Directory.systemTemp;
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: 60,
        minWidth: 600,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        print('Ошибка: Не удалось сжать изображение');
        return null;
      }

      final compressedSize = await compressedFile.length();
      print('Размер сжатого изображения: $compressedSize байт');
      if (compressedSize > 4_000_000) {
        print('Ошибка: Сжатое изображение слишком большое');
        return null;
      }

      return File(compressedFile.path);
    } catch (e) {
      print('Ошибка сжатия изображения: $e');
      return null;
    }
  }

  Future<String> _analyzeImage(File image) async {
    const serverUrl = 'https://gemini-proxy-nine-alpha.vercel.app/generate';
    const prompt = '''
Ты — эксперт по орнитологии с навыками компьютерного зрения и по распознаванию птиц. Твоя задача — максимально точно определить вид птицы на изображении, включая даже самых маленьких (например, синиц, крапивников, воробьёв, карликовых и других). Для повышения точности дополнительно проверяй информацию в интернете, используя достоверные источники (например, eBird, Cornell Lab of Ornithology, научные статьи) для подтверждения визуальных признаков. Обращай особое внимание на различия между Шлемоносной цесаркой и Глазчатой индейкой. Ключевые отличия: Шлемоносная цесарка: серое тело с белыми точками, костный "шлем" на голове, Африка. Глазчатая индейка: тёмное оперение с "глазками" на хвосте, сине-оранжевая голова, Юкатан. Важно: Если видишь "глазчатые" перья или оранжевые бусины на голове — это индейка, не цесарка! Некоторые птицы действительно могут быть очень миниатюрными — это не повод считать их игрушками или скульптурами. Будь особенно внимателен, чтобы не перепутать маленькую живую птицу с искусственным объектом. Обращай внимание на детали:
Перья: текстура, расположение, цвет (естественные градиенты, возможные дефекты).
Клюв/лапы: форма, структура (у живых птиц — естественные неровности, у арт-объектов — идеализированные линии).
Поведение/поза: динамика (например, напряжение лап на ветке) или статичность (как у чучел).
Фон: согласованность с естественной средой обитания вида.
Если видишь перья, натуральную текстуру, реалистичное поведение (например, птица сидит на пальце) — не пиши, что это скульптура или фейк. Скульптуры обычно имеют неестественные пропорции или материалы (металл, камень). Отвечай только при 100% уверенности, исключая слова "наверное", "возможно", "скорее всего". Избегай предположений. Если на изображении птица (включая живых птиц, рисунки, мультяшных персонажей, другие изображения птиц):
Проверь, нет ли ошибки в предоставленных данных (например, неверное название вида). Если предоставленные данные содержат ошибку, укажи это в примечании. Ошибки в данных: если предоставленное название не совпадает с визуальными признаками, укажи это. Сравни визуальные признаки с данными из интернета (например, фотографии видов на eBird или в научных базах) для подтверждения идентификации.

Следуй строгой инструкции:

1. Если это птица (включая рисунки, мультяшных персонажей, скульптуры и другие изображения птиц), ответь по пунктам:
1. Вид: [название на русском и на латыни]
2. Описание: [3–5 точных фактов о виде, включая среду обитания, особенности оперения, поведения или отличия от похожих видов]
3. Состояние: [оценка здоровья, при необходимости — рекомендации]
4. Если изображение НЕ было сделано в реальных условиях (например, это снимок экрана, фотографии с бумаги, монитора и т.п.), и также если оно было сделано в реальной жизни укажи это. Обязательно укажи это в новой строке, начинающейся с:
🌐 Источник: [укажи откуда]

2. Если это НЕ птица (абсолютно другой объект), напиши:
- Что изображено: [описание]
- Сообщение: На изображении нет птицы. Анализ невозможен. Пожалуйста, загрузите фото птицы.
''';
    try {
      final compressedImage = await _compressImage(image);
      if (compressedImage == null) {
        return '⚠️ Ошибка: Не удалось сжать изображение';
      }

      final imageBytes = await compressedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      print('Размер base64: ${base64Image.length} байт');
      if (base64Image.length > 4_000_000) {
        return '⚠️ Ошибка: Размер изображения превышает 4 МБ';
      }

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'image_base64': base64Image,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Request timed out after 30 seconds');
      });

      print('Статус: ${response.statusCode}, Тело: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['response'] ?? 'Не получилось распознать ответ';
        if (result.trim() == 'Вид: Птица' || result.trim().isEmpty) {
          return '⚠️ Ошибка: Сервер не смог точно распознать вид птицы.';
        }
        return result;
      } else if (response.statusCode == 413) {
        return '⚠️ Ошибка 413: Изображение слишком большое. Попробуйте загрузить меньшее изображение.';
      } else if (response.statusCode == 504) {
        return '⚠️ Ошибка 504: Сервер не успел обработать запрос. Попробуйте позже.';
      } else if (response.statusCode == 502) {
        return '⚠️ Ошибка 502: Ошибка соединения с сервером. Проверьте интернет и попробуйте снова.';
      } else {
        return '⚠️ Ошибка сервера: ${response.statusCode}, ${response.body}';
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      return '⚠️ Ошибка соединения: Не удалось подключиться к серверу. Проверьте интернет и попробуйте снова.';
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      return '⚠️ Ошибка: Запрос превысил время ожидания. Попробуйте снова.';
    } catch (e) {
      print('Ошибка: $e');
      return '⚠️ Ошибка: $e';
    }
  }

  String _processResponse(String text) {
    text = text.trim();
    if (text.isEmpty) {
      return '⚠️ Пустой или некорректный ответ от сервера';
    }

    text = text.replaceFirst(
      'Результаты анализа:',
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
      RegExp(r'^3\.\s*(Состояние|Уверенность):(.*)', multiLine: true),
      (match) => '❤️ ${match.group(1)}:${match.group(2)}',
    );

    text = text.replaceAllMapped(
      RegExp(r'^4\.\s*(Источник):(.*)', multiLine: true),
      (match) => '🌐 ${match.group(1)}:${match.group(2)}',
    );

    text = text.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s(.*)', multiLine: true),
      (match) => '   • ${match.group(1)}',
    );

    return text;
  }

  Future<void> _pickImage(bool useCamera) async {
  if (_isLoading) return;

   try {
    // Проверяем наличие интернета, используя _checkInternet()
    if (!await _checkInternet()) {
      setState(() => _result = '⚠️ Ошибка: Нет интернет-соединения. Проверьте подключение и попробуйте снова.');
      return;
    }
    
    File? selectedFile;

    if (useCamera) {
      if (!Platform.isAndroid && !Platform.isIOS) {
        setState(() => _result = '⚠️ Камера не поддерживается на этой платформе');
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

      final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);

      if (picked == null) {
        setState(() => _result = '⚠️ Изображение не выбрано');
        return;
      }

      final tempFile = File(picked.path);

      // Сохраняем в галерею через MediaStore, если включена галочка
if (_saveCameraPhotos) {
  const channel = MethodChannel('com.example.bird_identifier/media');
  try {
    final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await channel.invokeMethod('saveToGallery', {
      'path': tempFile.path,
      'name': fileName,
    });
  } catch (e) {
    print('Ошибка при сохранении фото в галерею: $e');
  }
}

selectedFile = tempFile;

    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          setState(() => _result = '⚠️ Разрешение было полностью запрещено. Пожалуйста, предоставьте доступ к галерее в настройках приложения.');
        } else {
          setState(() => _result = '⚠️ Для доступа к галерее необходимо предоставить разрешение');
        }
        return;
      }

      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
          selectedAssets: [],
          textDelegate: const RussianAssetPickerTextDelegate(),
        ),
      );

      if (assets == null || assets.isEmpty) {
        setState(() => _result = '⚠️ Изображение не выбрано');
        return;
      }

      selectedFile = await assets.first.file;
    }

    if (selectedFile == null) {
      setState(() => _result = '⚠️ Ошибка: Не удалось получить файл изображения');
      return;
    }

    setState(() {
      _selectedImage = selectedFile;
      _isLoading = true;
      _result = '';
      _isCameraSource = useCamera;
    });

    final response = await _analyzeImage(_selectedImage!);
    final savedImagePath = await _saveImagePermanently(_selectedImage!);

    setState(() {
      _result = _processResponse(response);
      final lines = response.split('\n');
      bool isFakeSource = false;

      for (var line in lines) {
        if (line.startsWith('1. Вид:')) {
          _species = line.replaceFirst('1. Вид:', '').trim();
        } else if (line.startsWith('3. Состояние:')) {
          _condition = line.replaceFirst('3. Состояние:', '').trim();
        } else if (line.startsWith('🌐 Источник:')) {
          isFakeSource = true;
        }
      }

      if (isFakeSource) {
        _isCameraSource = false;
      }

      final now = DateTime.now();
      final newEntry = {
        'date': now.toIso8601String(),
        'species': _species,
        'condition': _condition,
        'result': _result,
        'imagePath': savedImagePath,
      };

      String? lastEntryJson;
      if (_analysisHistory.isNotEmpty) {
        final last = _analysisHistory.last;
        lastEntryJson = jsonEncode({
          'date': (last['date'] is DateTime)
              ? (last['date'] as DateTime).toIso8601String()
              : last['date'],
          'species': last['species'],
          'condition': last['condition'],
          'result': last['result'],
          'imagePath': last['imagePath'],
        });
      }

      final newEntryJson = jsonEncode(newEntry);

      if (_analysisHistory.isEmpty || lastEntryJson != newEntryJson) {
        _analysisHistory.add({
          ...newEntry,
          'date': now,
        });
        _saveHistory();
      }
    });
  } catch (e) {
    setState(() => _result = '⚠️ Ошибка: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<Widget> _getImageWidget(String? path) async {
    if (path == null) return const Icon(Icons.photo);

    try {
      final file = File(path);
      if (await file.exists()) {
        return Image.file(
          file,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.photo),
        );
      }
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
    }
    return const Icon(Icons.photo);
  }

  void _showHistoryDialog() {
    if (_analysisHistory.isEmpty) {
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('История анализов пуста'),
            duration: Duration(seconds: 2),
          ),
        );
      });
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
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
                        ? FutureBuilder(
                            future: _getImageWidget(item['imagePath']),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return snapshot.data!;
                              }
                              return const Icon(Icons.photo);
                            },
                          )
                        : const Icon(Icons.audiotrack),
                    title: Text(item['species'] ?? 'Неизвестный вид'),
                    subtitle: Text(
                      '${item['date'].toString().substring(0, 16)}\n'
                      'Состояние: ${item['condition']?.split('\n').first ?? ''}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(this.context).pop();
                      setState(() {
                        _selectedImage = item['imagePath'] != null ? File(item['imagePath']) : null;
                        _result = item['result'];
                        _species = item['species'];
                        _condition = item['condition'];
                        _isCameraSource = item['imagePath'] != null && item['imagePath'].isNotEmpty;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            AnimatedTextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Center(
                      child: Text(
                        'Подтвердите очистку',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    content: const Text(
                      'Вы действительно хотите удалить всю историю анализов?',
                      textAlign: TextAlign.center,
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      AnimatedTextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue),
                        child: const Text('Да'),
                      ),
                      AnimatedTextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue),
                        child: const Text('Нет'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  setState(() {
                    _analysisHistory.clear();
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('analysisHistory');

                  Navigator.pop(context);
                  Navigator.of(this.context).pop();

                  Future.delayed(const Duration(milliseconds: 100), () {
                    widget.scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text('История успешно очищена'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Очистить'),
            ),
            AnimatedTextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescueHistoryDialog() {
    if (_rescueHistory.isEmpty) {
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('История запросов о помощи пуста'),
            duration: Duration(seconds: 2),
          ),
        );
      });
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final Map<int, bool> expandedTiles = {};

          return AlertDialog(
            title: const Center(child: Text('История запросов о помощи')),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rescueHistory.length,
                itemBuilder: (context, index) {
                  final reversedIndex = _rescueHistory.length - 1 - index;
                  final item = _rescueHistory[reversedIndex];
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  final isExpanded = expandedTiles[reversedIndex] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpansionTile(
                      onExpansionChanged: (expanded) {
                        setStateDialog(() {
                          expandedTiles[reversedIndex] = expanded;
                        });
                      },
                      iconColor: isExpanded ? Colors.blue : (isDarkMode ? Colors.white : Colors.black),
                      collapsedIconColor: isDarkMode ? Colors.white : Colors.black,
                      leading: item['imagePath'] != null
                          ? FutureBuilder(
                              future: _getImageWidget(item['imagePath']),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return snapshot.data!;
                                }
                                return const Icon(Icons.photo);
                              },
                            )
                          : const Icon(Icons.photo),
                      title: Text(
                        item['species'] ?? 'Неизвестный вид',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item['date'].toString().substring(0, 16)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Состояние: ${item['condition']}'),
                              const SizedBox(height: 8),
                              Text('Местоположение: ${item['location']}'),
                              if (item['message'] != null && item['message'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Сообщение: ${item['message']}'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedTextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Center(
                            child: Text(
                              'Подтвердите очистку',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: const Text(
                            'Вы действительно хотите удалить всю историю запросов?',
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            AnimatedTextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.blue),
                              child: const Text('Да'),
                            ),
                            AnimatedTextButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: TextButton.styleFrom(foregroundColor: Colors.blue),
                              child: const Text('Нет'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        setState(() {
                          _rescueHistory.clear();
                        });
                        await _saveRescueHistory();

                        Navigator.pop(context);
                        Navigator.of(this.context).pop();

                        Future.delayed(const Duration(milliseconds: 100), () {
                          widget.scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('История запросов очищена'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        });
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    child: const Text('Очистить'),
                  ),
                  const SizedBox(width: 20),
                  AnimatedTextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _requestRescue() async {
    if (_species == null || _condition == null) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Сначала проанализируйте изображение птицы'), duration: Duration(seconds: 2)),
      );
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Служба геолокации отключена. Включите ее в настройках.'), duration: Duration(seconds: 3)),
      );
      return;
    }

    var permission = await Permission.location.request();
    if (!permission.isGranted) {
      if (permission.isPermanentlyDenied) {
        await openAppSettings();
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Разрешение на местоположение запрещено. Разрешите доступ в настройках.'), duration: Duration(seconds: 3)),
        );
      } else {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Для отправки запроса необходимо разрешение на доступ к местоположению'), duration: Duration(seconds: 3)),
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
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка получения местоположения: $e'), duration: Duration(seconds: 3)),
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
        scaffoldMessengerKey: widget.scaffoldMessengerKey,
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

    String? imagePath;
    if (image != null) {
      imagePath = await _saveImagePermanently(image);
    }

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

      setState(() {
        _rescueHistory.add({
          'date': DateTime.now(),
          'species': species,
          'condition': condition,
          'location': location,
          'message': message,
          'imagePath': imagePath,
        });
        _saveRescueHistory();
      });

      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Запрос успешно отправлен'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e'), duration: Duration(seconds: 3)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = screenWidth < 360 ? 12.0 : screenWidth < 600 ? 14.0 : 16.0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final isViewingFromHistory = ModalRoute.of(context)?.settings.name == '/history';

    return Scaffold(
      key: _scaffoldKey,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.3,
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: const Text(
          'Определитель птиц',
          style: TextStyle(
            fontFamily: 'ComicSans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Container(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1D1B20) : Colors.blue[100],
                    ),
                    padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Перо жизни',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Приложение для определения видов птиц и их состояния. '
                          'Помогаем сохранить пернатых друзей и заботимся об их благополучии.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.history,
                              color: isDarkMode ? Colors.white70 : Colors.black87),
                          title: Text('История анализов',
                              style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black)),
                          onTap: () => _showHistoryDialog(),
                        ),
                        ListTile(
                          leading: Icon(Icons.help_outline,
                              color: isDarkMode ? Colors.white70 : Colors.black87),
                          title: Text('История запросов о помощи',
                              style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black)),
                          onTap: () => _showRescueHistoryDialog(),
                        ),
                      ],
                    ),
                  ),

                  // Увеличенный отступ для поднятия кнопки
                  const SizedBox(height: 20),

                  // Уже по бокам + приподнята
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: AnimatedElevatedButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(
                              onThemeToggle: widget.onThemeToggle,
                              isDarkMode: isDarkMode,
                              onSaveCameraPhotosToggle: _saveCameraPhotosSetting,
                              saveCameraPhotos: _saveCameraPhotos,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.settings,
                          color: isDarkMode ? Colors.white : Colors.black),
                      child: Text(
                        'Настройки',
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? const Color(0xFF003366)
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ),
),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 350,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color.fromARGB(255, 21, 38, 51)
                          : const Color.fromARGB(255, 188, 230, 250),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF003366) : Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: _selectedImage != null
                        ? GestureDetector(
                            onTap: () async {
                              final File? editedImage = await Navigator.push<File?>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageZoomScreen(image: _selectedImage!),
                                ),
                              );

                              if (editedImage != null) {
                                setState(() {
                                  _selectedImage = editedImage;
                                  _result = '';
                                  _isLoading = true;
                                });

                                final response = await _analyzeImage(editedImage);

                                setState(() {
                                  _result = _processResponse(response);
                                  _isLoading = false;
                                });
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FittedBox(
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                child: Image.file(_selectedImage!),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                size: 50,
                                color: isDarkMode ? Colors.blue[300] : Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Загрузите изображение птицы',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: baseFontSize + 2,
                                    color: isDarkMode ? Colors.blue[300] : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: _animationController.drive(
                    Tween<Offset>(
                      begin: const Offset(0.0, 0.4),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                  ),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      AnimatedElevatedButton(
                        onPressed: _isLoading ? null : () => _pickImage(true),
                        icon: const Icon(Icons.camera_alt),
                        child: Text(
                          "Камера",
                          style: TextStyle(fontSize: baseFontSize),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF003366) : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      AnimatedElevatedButton(
                        onPressed: _isLoading ? null : () => _pickImage(false),
                        icon: const Icon(Icons.photo_library),
                        child: Text(
                          "Галерея",
                          style: TextStyle(fontSize: baseFontSize),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF003366) : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_result.isNotEmpty || _isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color.fromARGB(255, 27, 27, 32) : Colors.blue[50],
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
                                style: TextStyle(
                                  fontSize: baseFontSize + 2,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.blue[300] : Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                                  child: SelectableText.rich(
                                    TextSpan(
                                      children: _buildTextSpans(_result),
                                    ),
                                    style: TextStyle(
                                      fontSize: baseFontSize,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                ),
              if (_showRescueButton && !isViewingFromHistory)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                    child: ScaleTransition(
                      scale: _rescuePulseScale,
                      child: AnimatedBuilder(
                        animation: _rescuePulseColor,
                        builder: (context, child) {
                          return ElevatedButton(
                            onPressed: _requestRescue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _rescuePulseColor.value,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              minimumSize: const Size(300, 50),
                              alignment: Alignment.center,
                            ),
                            child: const Text(
                              'Отправить запрос в реабилитационный центр',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    for (var line in lines) {
      if (line.contains('•')) {
        final parts = line.split('•');
        spans.add(TextSpan(
          text: parts[0],
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ));
        spans.add(TextSpan(
          text: '• ',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ));
        spans.add(TextSpan(
          text: parts[1].trim(),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ));
      } else {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ));
      }
      spans.add(const TextSpan(text: '\n'));
    }

    return spans;
  }
}

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;
  final Function(bool) onSaveCameraPhotosToggle;
  final bool saveCameraPhotos;

  const SettingsScreen({
    Key? key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.onSaveCameraPhotosToggle,
    required this.saveCameraPhotos,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late bool _isDark;
  late bool _savePhotos;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkMode;
    _savePhotos = widget.saveCameraPhotos;
  }

  void _onThemeChanged(bool value) {
    setState(() => _isDark = value);
    widget.onThemeToggle(value);
  }

  void _onSavePhotosChanged(bool value) {
    setState(() => _savePhotos = value);
    widget.onSaveCameraPhotosToggle(value);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isDark ? Colors.white : Colors.black;
    final subTextColor = _isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Настройки',
          style: TextStyle(fontFamily: 'ComicSans', fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6, color: subTextColor),
              title: Text('Тема', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              subtitle: Text(_isDark ? 'Тёмная' : 'Светлая', style: TextStyle(color: subTextColor)),
              trailing: Switch(
                value: _isDark,
                onChanged: _onThemeChanged,
                activeColor: Colors.blue,
                inactiveThumbColor: Colors.grey[300],
                inactiveTrackColor: Colors.grey[400],
              ),
            ),
            CheckboxTheme(
              data: CheckboxThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: WidgetStateBorderSide.resolveWith(
                  (states) => BorderSide(color: subTextColor, width: 2),
                ),
                fillColor: WidgetStateProperty.all(Colors.transparent),
                checkColor: WidgetStateProperty.all(Colors.blue),
              ),
              child: CheckboxListTile(
                value: _savePhotos,
                onChanged: (value) => _onSavePhotosChanged(value!),
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(
                  'Сохранять фотографии, сделанные через камеру',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                secondary: Icon(Icons.camera_alt, color: subTextColor),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Авторы программы:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 8),
            Text('Кривошеенко Данил Дмитриевич', style: TextStyle(color: subTextColor, fontSize: 14)),
            Text('Панов Максим Романович', style: TextStyle(color: subTextColor, fontSize: 14)),
            Text('Полежаев Дмитрий Дмитриевич', style: TextStyle(color: subTextColor, fontSize: 14)),
            const SizedBox(height: 30),
            Text(
              'Официальная почта:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 8),
            Text('perozhizni@gmail.com', style: TextStyle(color: subTextColor, fontSize: 14)),
            const Spacer(),
            Text(
              'Версия приложения: 2.6.0',
              style: TextStyle(color: subTextColor, fontStyle: FontStyle.italic, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedElevatedButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget? icon;
  final Widget child;
  final ButtonStyle? style;

  const AnimatedElevatedButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.child,
    this.style,
  });

  @override
  State<AnimatedElevatedButton> createState() => _AnimatedElevatedButtonState();
}

class _AnimatedElevatedButtonState extends State<AnimatedElevatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePressed() async {
    if (_isAnimating || widget.onPressed == null) return;

    setState(() => _isAnimating = true);
    await _controller.forward();
    await _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 80));
    await widget.onPressed?.call();
    setState(() => _isAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: widget.onPressed == null ? null : _handlePressed,
        style: widget.style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 8),
            ],
            widget.child,
          ],
        ),
      ),
    );
  }
}

class ImageZoomScreen extends StatefulWidget {
  final File image;

  const ImageZoomScreen({super.key, required this.image});

  @override
  State<ImageZoomScreen> createState() => _ImageZoomScreenState();
}

class _ImageZoomScreenState extends State<ImageZoomScreen> {
  Uint8List? _editedImageBytes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр изображения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editImage,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading || _editedImageBytes == null ? null : _saveEditedImage,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _editedImageBytes != null
                ? Image.memory(_editedImageBytes!)
                : Image.file(widget.image),
      ),
    );
  }

  Future<void> _editImage() async {
    setState(() => _isLoading = true);

    try {
      final imageBytes = await widget.image.readAsBytes();

      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: imageBytes,
          ),
        ),
      );

      if (editedImage != null && editedImage is Uint8List) {
        setState(() {
          _editedImageBytes = editedImage;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка редактирования: $e'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _saveEditedImage() async {
    if (_editedImageBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(_editedImageBytes!);

      Navigator.pop(context, file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e'), duration: Duration(seconds: 2)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class AnimatedTextButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const AnimatedTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  State<AnimatedTextButton> createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<AnimatedTextButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePressed() async {
    if (_isAnimating || widget.onPressed == null) return;

    setState(() => _isAnimating = true);
    await _controller.forward();
    await _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 80));
    widget.onPressed?.call();
    setState(() => _isAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: TextButton(
        onPressed: widget.onPressed == null ? null : _handlePressed,
        style: widget.style,
        child: widget.child,
      ),
    );
  }
}

class RescueRequestDialog extends StatefulWidget {
  final String species;
  final String condition;
  final String location;
  final String locationLink;
  final File? image;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Future<void> Function(String message) onSubmit;

  const RescueRequestDialog({
    super.key,
    required this.species,
    required this.condition,
    required this.location,
    required this.locationLink,
    this.image,
    required this.scaffoldMessengerKey,
    required this.onSubmit,
  });

  @override
  State<RescueRequestDialog> createState() => _RescueRequestDialogState();
}

class _RescueRequestDialogState extends State<RescueRequestDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Center(
        child: Text(
          'Запрос в реабилитационный центр',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вид: ${widget.species}'),
            const SizedBox(height: 8),
            Text('Состояние: ${widget.condition}'),
            const SizedBox(height: 8),
            Text('Местоположение: ${widget.location}'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(widget.locationLink);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  widget.scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Не удалось открыть карту'), duration: Duration(seconds: 2)),
                  );
                }
              },
              child: Text(
                'Открыть на карте',
                style: TextStyle(
                  color: isDarkMode ? Colors.blue[300] : Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    widget.image!,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Дополнительное сообщение',
                border: const OutlineInputBorder(),
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                filled: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        AnimatedTextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          child: const Text('Отмена'),
        ),
        AnimatedTextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await widget.onSubmit(_messageController.text);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    widget.scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(content: Text('Ошибка: $e'), duration: Duration(seconds: 2)),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          child: _isLoading ? const CircularProgressIndicator() : const Text('Отправить'),
        ),
      ],
    );
  }
}