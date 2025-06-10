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
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return MaterialApp(
       title: 'Определитель птиц',
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        fontFamily: 'ComicSans',
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
  centerTitle: true,
  backgroundColor: Colors.white, // для светлой темы
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
              return Colors.blue[500]; // Цвет "шарика" в активном состоянии
            }
            return Colors.grey[300]; // Цвет "шарика" в неактивном состоянии
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.blue[700]; // Цвет трека в активном состоянии
            }
            return Colors.grey[400]; // Цвет трека в неактивном состоянии
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
              return Colors.blue[300]; // Цвет "шарика" в активном состоянии
            }
            return Colors.grey[400]; // Цвет "шарика" в неактивном состоянии
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.blue[700]; // Цвет трека в активном состоянии
            }
            return Colors.grey[600]; // Цвет трека в неактивном состоянии
          }),
        ),
      ),
      themeMode: _themeMode,
      home: BirdIdentifierScreen(
        onThemeToggle: _toggleTheme,
        scaffoldMessengerKey: _scaffoldMessengerKey,
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
  final ImagePicker _picker = ImagePicker();
  String? _species;
  String? _condition;
  ImageSource? _lastUsedSource;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _analysisHistory = [];
  final List<Map<String, dynamic>> _rescueHistory = [];
  late AnimationController _animationController;
  late AnimationController _rescuePulseController;
  late Animation<double> _rescuePulseScale;
  late Animation<Color?> _rescuePulseColor;


  bool get _showRescueButton {
    if (_species == null || _condition == null) return false;
    if (_lastUsedSource != ImageSource.camera) return false;
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

  // запуск анимации при загрузке
  _animationController.forward();
}

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();

    _rescuePulseController.dispose();
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
          if (imagePath != null) {
            final file = File(imagePath);
            if (!file.existsSync()) {
              return {
                'date': DateTime.parse(item['date']),
                'species': item['species'],
                'condition': item['condition'],
                'result': item['result'],
                'imagePath': null
              };
            }
          }
          return {
            'date': DateTime.parse(item['date']),
            'species': item['species'],
            'condition': item['condition'],
            'result': item['result'],
            'imagePath': imagePath
          };
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
        print('Ошибка: Не удалось сжать изображение');
        return null;
      }

      final compressedSize = await compressedFile.length();
      if (compressedSize > 10000000) {
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
    const serverUrl = 'https://proxy-server-rho-seven.vercel.app/generate';
    const prompt = '''
Ты — эксперт распознаванию птиц. Твоя задача — определить реальный вид птицы на изображении, включая даже самых маленьких (например, синиц, крапивников, воробьёв, карликовых и других). Некоторые птицы действительно могут быть очень миниатюрными — это не повод считать их игрушками или скульптурами. Будь особенно внимателен, чтобы не перепутать маленькую живую птицу с искусственным объектом. Обращай особое внимание на детали: структуру перьев, клюва, лап, поведение, фон и взаимодействие с рукой человека - у реальных птиц они выглядят естественно. Если видишь перья, натуральную текстуру, реалистичное поведение (например, птица сидит на пальце) — не пиши, что это скульптура или фейк. Скульптуры обычно имеют неестественные пропорции или материалы (металл, камень). Отвечай только при 100% уверенности, исключая слова "наверное", "возможно", "скорее всего". Если на изображении птица (включая живых птиц, рисунки, мультяшных персонажей, другие изображения птиц):   
Проверь, нет ли ошибки в предоставленных данных (например, неверное название вида). Если предоставленные данные содержат ошибку, укажи это в примечании. Следуй строгой инструкции:

1. Если это птица (включая рисунки, мультяшных персонажей, скульптуры и другие изображения птиц), ответь по пунктам:
1. Вид: [название на русском и на латыни]
2. Описание: [3–5 точных фактов о виде]
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
        print('Ошибка: Не удалось сжать изображение');
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

      print('Ответ сервера: statusCode=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['response'] ?? 'Не получилось распознать ответ';
        if (result.trim() == 'Вид: Птица' || result.trim().isEmpty) {
          return '⚠️ Ошибка: Сервер не смог точно распознать вид птицы. Попробуйте загрузить другое изображение.';
        }
        return result;
      } else if (response.statusCode == 503) {
        return '⚠️ Ошибка 503: Сервер временно недоступен. Попробуйте позже.';
      } else if (response.statusCode == 413) {
        return '⚠️ Ошибка 413: Загружаемый файл слишком большой. Попробуйте уменьшить изображение.';
      } else {
        return '⚠️ Ошибка сервера: ${response.statusCode}';
      }
    } catch (e) {
      print('Ошибка при анализе изображения: $e');
      return '⚠️ Ошибка: $e';
    }
  }

  String _processResponse(String text) {
    text = text.trim();
    if (text.isEmpty || text == 'Вид: Птица') {
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
      RegExp(r'^3\.\s*Состояние:(.*)', multiLine: true),
      (match) => '❤️ Состояние:${match.group(1)}',
    );

    text = text.replaceAllMapped(
      RegExp(r'^🌐\s*Источник:(.*)', multiLine: true),
      (match) => '🌐 Источник:${match.group(1)}',
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
          _lastUsedSource = null;
        }

        final now = DateTime.now();
        final newEntry = {
          'date': now.toIso8601String(),
          'species': _species,
          'condition': _condition,
          'result': _result,
          'imagePath': savedImagePath
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
  Navigator.pop(context); // закрыть диалог
  Navigator.of(context).pop(); // закрыть боковое меню
  Future.delayed(const Duration(milliseconds: 100), () {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('История анализов пуста'), duration: Duration(seconds: 2)),
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
                        : const Icon(Icons.photo),
                    title: Text(item['species'] ?? 'Неизвестный вид'),
                    subtitle: Text(
                      '${item['date'].toString().substring(0, 16)}\n'
                      'Состояние: ${item['condition']?.split('\n').first ?? ''}',
                    ),
                    onTap: () {
  Navigator.pop(context); // закрывает диалог
  Navigator.of(context).pop(); // закрывает Drawer

  setState(() {
    if (item['imagePath'] != null) {
      _selectedImage = File(item['imagePath']);
    } else {
      _selectedImage = null;
    }
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        child: const Text('Да'),
                      ),
                      AnimatedTextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
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
                  widget.scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('История успешно очищена'), duration: Duration(seconds: 2)),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text('Очистить'),
            ),
            AnimatedTextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescueHistoryDialog() {
    if (_rescueHistory.isEmpty) {
  Navigator.pop(context);
  Future.delayed(const Duration(milliseconds: 100), () {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('История запросов о помощи пуста'), duration: Duration(seconds: 2)),
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
            title: const Center(
              child: Text(
                'История запросов о помощи',
                textAlign: TextAlign.center,
              ),
            ),
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
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                              child: const Text('Да'),
                            ),
                            AnimatedTextButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
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
                        widget.scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(content: Text('История запросов очищена'), duration: Duration(seconds: 2)),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                    child: const Text('Очистить'),
                  ),
                  const SizedBox(width: 20),
                  AnimatedTextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
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

  // Добавляем проверку, просматриваем ли мы из истории
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
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, // 👈 общий фон
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Верхняя часть
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

                  // Кнопки меню
                  Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.history, color: isDarkMode ? Colors.white70 : Colors.black87),
                        title: Text('История анализов', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                        onTap: () => _showHistoryDialog(),
                      ),
                      ListTile(
                        leading: Icon(Icons.help_outline, color: isDarkMode ? Colors.white70 : Colors.black87),
                        title: Text('История запросов о помощи', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                        onTap: () => _showRescueHistoryDialog(),
                      ),
                      ListTile(
                        leading: Icon(Icons.brightness_6, color: isDarkMode ? Colors.white70 : Colors.black87),
                        title: Text('Тема', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                        subtitle: Text(
                          isDarkMode ? 'Тёмная' : 'Светлая',
                          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (value) => widget.onThemeToggle(value),
                        ),
                      ),
                    ],
                  ),

                  // Заполнитель пространства — теперь внутри цветного контейнера
                  Expanded(child: SizedBox()),

                  // Нижний блок с авторами
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Авторы программы:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Кривошеенко Данил Дмитриевич', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                          Text('Панов Максим Романович', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                          Text('Полежаев Дмитрий Дмитриевич', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                          const SizedBox(height: 10),
                          Text(
                            'Тестировщик:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Козлов Матвей Евгеньевич', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                          const SizedBox(height: 10),
                          Text(
                            'Официальная почта:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text('perozhizni@gmail.com', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
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
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageZoomScreen(image: _selectedImage!),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain,
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
                    Text(
                      'Загрузите изображение птицы',
                      style: TextStyle(
                        fontSize: baseFontSize + 2,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  child: Text(
                    "Камера",
                    style: TextStyle(fontSize: baseFontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? const Color(0xFF003366) : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 20),
                AnimatedElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  child: Text(
                    "Галерея",
                    style: TextStyle(fontSize: baseFontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? const Color(0xFF003366) : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
        scale: _rescuePulseScale, // Анимация увеличения кнопки
        child: AnimatedBuilder(
          animation: _rescuePulseColor, // Анимация цвета
          builder: (context, child) {
            return ElevatedButton(
              onPressed: _requestRescue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rescuePulseColor.value, // Цвет кнопки меняется с анимацией
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

class AnimatedElevatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget child;
  final ButtonStyle? style;

  const AnimatedElevatedButton({
    super.key,
    this.onPressed,
    this.icon,
    required this.child,
    this.style,
  });

  @override
  _AnimatedElevatedButtonState createState() => _AnimatedElevatedButtonState();
}

class _AnimatedElevatedButtonState extends State<AnimatedElevatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTween(
      begin: widget.style?.backgroundColor?.resolve({}) ?? Colors.blue,
      end: (widget.style?.backgroundColor?.resolve({}) ?? Colors.blue).withOpacity(0.7),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) _controller.forward();
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          _controller.reverse();
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return ElevatedButton.icon(
              onPressed: widget.onPressed,
              style: widget.style?.merge(
                ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(_colorAnimation.value),
                  elevation: WidgetStateProperty.all(_controller.value * 8),
                  shadowColor: WidgetStateProperty.all(Colors.black54),
                ),
              ),
              icon: widget.icon ?? const SizedBox(),
              label: widget.child,
            );
          },
        ),
      ),
    );
  }
}

class ImageZoomScreen extends StatelessWidget {
  final File image;

  const ImageZoomScreen({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр изображения'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.file(image),
        ),
      ),
    );
  }
}

class AnimatedTextButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const AnimatedTextButton({
    super.key,
    this.onPressed,
    required this.child,
    this.style,
  });

  @override
  _AnimatedTextButtonState createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<AnimatedTextButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) _controller.forward();
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          _controller.reverse();
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: TextButton(
          onPressed: widget.onPressed,
          style: widget.style,
          child: widget.child,
        ),
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
  final Function(String) onSubmit;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const RescueRequestDialog({
    super.key,
    required this.species,
    required this.condition,
    required this.location,
    required this.locationLink,
    required this.image,
    required this.onSubmit,
    required this.scaffoldMessengerKey,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = screenWidth < 360 ? 12.0 : screenWidth < 600 ? 14.0 : 16.0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Center(
        child: Text(
          'Запрос на спасение',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize + 4,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вид: ${widget.species}',
              style: TextStyle(
                fontSize: baseFontSize,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Состояние: ${widget.condition}',
              style: TextStyle(
                fontSize: baseFontSize,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Местоположение:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: baseFontSize,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                AnimatedTextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.locationLink));
                    widget.scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Местоположение скопировано'), duration: Duration(seconds: 2)),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.only(left: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.content_copy,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Копировать',
                        style: TextStyle(fontSize: baseFontSize),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              widget.location,
              style: TextStyle(
                fontSize: baseFontSize,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Дополнительное сообщение:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: baseFontSize,
                  color: isDarkMode ? Colors.white : Colors.black,
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
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
              ),
              maxLines: 3,
              style: TextStyle(
                fontSize: baseFontSize,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
      actions: [
  Center(
    child: Column(
      children: [
        AnimatedTextButton(
          onPressed: () async {
            if (await canLaunchUrl(Uri.parse(widget.locationLink))) {
              await launchUrl(Uri.parse(widget.locationLink));
            } else {
              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(content: Text('Не удалось открыть карту'), duration: Duration(seconds: 2)),
              );
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Открыть карту',
                style: TextStyle(
                  fontSize: baseFontSize,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedTextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Отмена',
            style: TextStyle(
              fontSize: baseFontSize,
              color: isDarkMode ? Colors.white : Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 20),
              AnimatedElevatedButton(
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
                    : Text(
                        'Подтвердить отправку',
                        style: TextStyle(fontSize: baseFontSize),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}