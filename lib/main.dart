// =============== ИМПОРТЫ ===============
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
// ignore: unused_import
import 'package:audio_session/audio_session.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
// ignore: unused_import
import 'package:audioplayers/audioplayers.dart' hide PlayerState;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
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
import 'package:share_handler/share_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
// ignore: unused_import
import 'package:tflite_flutter/tflite_flutter.dart';
// ignore: unused_import
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
// ignore: unused_import
import 'package:record/record.dart';
import 'package:waveform_recorder/waveform_recorder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Добавляем задержку в 1 секунду
  await Future.delayed(const Duration(seconds: 1));

  runApp(const BirdIdentifierApp());
}

// =============== ГЛАВНОЕ ПРИЛОЖЕНИЕ ===============
class BirdIdentifierApp extends StatefulWidget {
  const BirdIdentifierApp({super.key});
  @override
  _BirdIdentifierAppState createState() => _BirdIdentifierAppState();
}

class _BirdIdentifierAppState extends State<BirdIdentifierApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
      if (!isFirstLaunch) return;
      await Future.delayed(const Duration(milliseconds: 300));
      final navContext = _navigatorKey.currentContext;
      if (navContext != null) {
        showDialog(
          context: navContext,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 24,
            title: Center(
              child: Text(
                "👋 Добро пожаловать в «Перо жизни»",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Приложение «Перо жизни» — создано для того, чтобы каждый мог помочь птицам.\n",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  ),
                  Center(
                    child: Text(
                      "📌 Как это работает:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "1️⃣ Сделайте фото или выберите из галереи.\n"
"2️⃣ Запишите голос птицы или выберите аудиофайл для анализа.\n"
"3️⃣ Искусственный интеллект определит вид птицы.\n"
"4️⃣ Вы получите рекомендации по её состоянию.\n"
"5️⃣ При необходимости можно отправить запрос в ближайший центр помощи.\n"
"📖 Подробная инструкция по использованию приложения доступна в разделе «Настройки» -> «Подробная справка по приложению».\n"
"✨ Вместе мы можем сделать больше! Присоединяйтесь к нашему сообществу людей, которые заботятся о природе и помогают птицам выживать в современном мире. Каждое ваше действие имеет значение!",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            actions: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isFirstLaunch', false);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text("Начать", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ).animate(
            effects: [
              ScaleEffect(duration: 400.ms, curve: Curves.elasticOut),
              FadeEffect(duration: 500.ms),
            ],
          ),
        );
      }
    } catch (e) {
      // Просто игнорируем ошибку, приветствие не покажется
    }
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
        navigatorKey: _navigatorKey,
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
        title: 'Перо жизни',
        scaffoldMessengerKey: _scaffoldMessengerKey,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'ComicSans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
            primary: Colors.blue,
            secondary: Colors.blueAccent,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.blue.shade800,
              fontFamily: 'ComicSans',
            ),
            iconTheme: IconThemeData(color: Colors.blue.shade800),
          ),
          cardTheme: CardThemeData(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: EdgeInsets.all(8),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
            ),
            filled: true,
            fillColor: Colors.blue.shade50,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          fontFamily: 'ComicSans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
            primary: Colors.blue,
            secondary: Colors.blueAccent,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            backgroundColor: Color(0xFF0A0E21),
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.blue.shade200,
              fontFamily: 'ComicSans',
            ),
            iconTheme: IconThemeData(color: Colors.blue.shade200),
          ),
          cardTheme: CardThemeData(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: EdgeInsets.all(8),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
            ),
            filled: true,
            fillColor: Colors.blue.shade900.withOpacity(0.3),
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

// =============== ОСНОВНОЙ ЭКРАН ===============
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
  List<Map<String, dynamic>> _voiceHistory = [];
  PlayerController? _historyPlayerController;
  bool _isHistoryPlaying = false;
  String? _currentPlayingPath;
  late AnimationController _animationController;
  late AnimationController _rescuePulseController;
  late Animation<double> _rescuePulseScale;
  late Animation<Color?> _rescuePulseColor;
  bool _saveCameraPhotos = false;
  late AnimationController _imageScaleController;
  late Animation<double> _imageScaleAnimation;
  bool _hasSelectedImage = false;

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
    final handler = ShareHandler.instance;
    handler.getInitialSharedMedia().then((SharedMedia? media) {
      if (media != null && media.attachments != null && media.attachments!.isNotEmpty) {
        _handleSharedImage(File(media.attachments!.first!.path));
      }
    });
    handler.sharedMediaStream.listen((SharedMedia media) {
      if (media.attachments != null && media.attachments!.isNotEmpty) {
        _handleSharedImage(File(media.attachments!.first!.path));
      }
    });
    _loadHistory();
    _loadRescueHistory();
    _loadVoiceHistory();
    _loadSaveCameraPhotos();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _imageScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _imageScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _imageScaleController, curve: Curves.easeInOut),
    );
    _rescuePulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _rescuePulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _rescuePulseController, curve: Curves.easeInOut),
    );
    _rescuePulseColor = ColorTween(begin: Colors.redAccent, end: Colors.red.shade700).animate(
      CurvedAnimation(parent: _rescuePulseController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _imageScaleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rescuePulseController.dispose();
    _imageScaleController.dispose();
    super.dispose();
  }

  Future<void> _loadVoiceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('voiceHistory');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      setState(() {
        _voiceHistory.clear();
        _voiceHistory.addAll(historyList.map((item) {
          return {
            'date': DateTime.parse(item['date']),
            'filePath': item['filePath'],
            'result': item['result'],
            'species': item['species'],
          };
        }).toList());
      });
    }
  }

  Future<void> _saveVoiceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_voiceHistory.map((item) => {
          'date': item['date'].toIso8601String(),
          'filePath': item['filePath'],
          'result': item['result'],
          'species': item['species'],
        }).toList());
    await prefs.setString('voiceHistory', historyJson);
  }

  void addVoiceToHistory(String filePath, String result) {
    _addToVoiceHistory(filePath, result);
  }

  void _addToVoiceHistory(String filePath, String result) {
    String? species;
    final lines = result.split('\n');
    for (var line in lines) {
      if (line.contains('🦜 Вид:')) {
        species = line.replaceFirst('🦜 Вид:', '').trim();
        break;
      }
    }
    final now = DateTime.now();
    final newEntry = {
      'date': now,
      'filePath': filePath,
      'result': result,
      'species': species ?? 'Неизвестный вид',
    };
    setState(() {
      _voiceHistory.add(newEntry);
    });
    _saveVoiceHistory();
  }

  Future<void> _launchTelegram() async {
    const url = 'https://t.me/PeroZhizni';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Не удалось открыть Telegram')),
        );
      }
    } catch (e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Widget _buildTelegramButton() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0088CC), Color(0xFF0077B5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(25), // Увеличил для овальной формы
      boxShadow: [
        BoxShadow(
          color: Color(0xFF0088CC).withOpacity(0.4),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25), // Увеличил для овальной формы
        onTap: _launchTelegram,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), // Изменил padding для овальной формы
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Наш Telegram-канал',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).animate(
    effects: [
      ScaleEffect(
        duration: 300.ms,
        curve: Curves.easeInOut,
      ),
    ],
  );
}

  // === ЗАГРУЗКА/СОХРАНЕНИЕ НАСТРОЕК ===
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
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'bird_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${directory.path}/$fileName';
    
    // Создаем копию файла
    final imageBytes = await image.readAsBytes();
    final newFile = File(newPath);
    await newFile.writeAsBytes(imageBytes);
    
    // Проверяем, что файл создан
    if (await newFile.exists()) {
      final fileSize = await newFile.length();
      print('💾 Изображение сохранено: $newPath (${fileSize} bytes)');
      return newPath;
    } else {
      print('❌ Ошибка: файл не создан');
      return null;
    }
  } catch (e) {
    print('❌ Ошибка сохранения изображения: $e');
    return null;
  }
}

  Future<void> _loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final historyJson = prefs.getString('analysisHistory');
  
  if (historyJson != null) {
    try {
      final List<dynamic> historyList = jsonDecode(historyJson);
      setState(() {
        _analysisHistory.clear();
        _analysisHistory.addAll(historyList.map((item) {
          final imagePath = item['imagePath'];
          
          // Проверяем существование файла
          bool fileExists = false;
          if (imagePath != null && imagePath is String) {
            try {
              fileExists = File(imagePath).existsSync();
            } catch (e) {
              fileExists = false;
            }
          }
          
          // Парсим дату
          DateTime date;
          try {
            if (item['date'] is String) {
              date = DateTime.parse(item['date']);
            } else {
              date = DateTime.now();
            }
          } catch (e) {
            date = DateTime.now();
          }
          
          return {
            'date': date,
            'species': item['species'] ?? 'Неизвестный вид',
            'condition': item['condition'] ?? 'Не указано',
            'result': item['result'] ?? '',
            'imagePath': fileExists ? imagePath : null,
          };
        }).toList());
      });
      
      print('📖 Загружено записей в историю: ${_analysisHistory.length}');
    } catch (e) {
      print('❌ Ошибка загрузки истории: $e');
    }
  } else {
    print('📖 История пуста');
  }
}

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_analysisHistory.map((item) => {
          'date': item['date'] is DateTime ? (item['date'] as DateTime).toIso8601String() : item['date'].toString(),
          'species': item['species'],
          'condition': item['condition'],
          'result': item['result'],
          'imagePath': item['imagePath'],
        }).toList());
    await prefs.setString('analysisHistory', historyJson);
  }

  String _formatHistoryDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  
  return '$day-$month-$year\n$hour:$minute';
}

  // === ИНТЕРНЕТ И СЖАТИЕ ===
  Future<bool> _checkInternet() async {
    final endpoints = ['https://1.1.1.1', 'https://8.8.8.8', 'https://api.github.com'];
    for (int attempt = 0; attempt < 2; attempt++) {
      for (final endpoint in endpoints) {
        try {
          final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 2));
          if (response.statusCode >= 200 && response.statusCode < 300) return true;
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<File?> _compressImage(File image) async {
    try {
      final fileSize = await image.length();
      if (fileSize < 500000) return image;
      final tempDir = Directory.systemTemp;
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path, targetPath, quality: 60, minWidth: 600, minHeight: 600, format: CompressFormat.jpeg,
      );
      if (compressedFile == null) return null;
      final compressedSize = await compressedFile.length();
      if (compressedSize > 4_000_000) return null;
      return File(compressedFile.path);
    } catch (e) {
      return null;
    }
  }

  // === АНАЛИЗ ИЗОБРАЖЕНИЯ ===
  Future<String> _analyzeImage(File image) async {
    const serverUrl = 'https://gemini-proxy-nine-alpha.vercel.app/generate';
    const prompt = '''
Ты — эксперт по орнитологии с навыками компьютерного зрения и по распознаванию птиц. Твоя задача — максимально точно определить вид птицы на изображении, включая даже самых маленьких (например, синиц, крапивников, воробьёв, карликовых и других). Для повышения точности дополнительно проверяй информацию в интернете, используя достоверные источники (например, eBird, Cornell Lab of Ornithology, научные статьи) для подтверждения визуальных признаков. Обязательно найди похожие фотографии в интернете и сравни с ними перед ответом. Не путай птиц Цесарка и Глазчатой индейкой! Отвечай только когда найдешь точное совпадение по визуальным признакам. 

ДОПОЛНИТЕЛЬНЫЕ КРИТЕРИИ ДЛЯ ТОЧНОСТИ:
- Проверь сезонность: соответствует ли оперение времени года
- Учитывай географию: могла ли эта птица быть в данном регионе
- Обрати внимание на возраст: взрослая особь или птенец
- Проверь половые различия: самец/самка могут выглядеть по-разному
- Сравни с похожими видами: исключи двойников по ключевым признакам

ПРИЗНАКИ ЖИВОЙ ПТИЦЫ:
- Естественная поза с напряжением мышц
- Реалистичное положение лап на поверхности
- Наличие мелких дефектов: взъерошенные перья, пыль
- Естественное освещение и тени
- Окружающая среда: ветки, трава, вода

ПРИЗНАКИ НЕЖИВОГО ОБЪЕКТА:
- Идеально симметричные черты
- Однородный цвет без градиентов
- Статичная, неестественная поза
- Отсутствие мелких деталей и дефектов
- Явные признаки рисунка или 3D-модели

Обращай особое внимание на то что некоторые птицы действительно могут быть очень миниатюрными — это не повод считать их игрушками или скульптурами. Будь особенно внимателен, чтобы не перепутать маленькую живую птицу с искусственным объектом. Обращай внимание на детали:
Перья: текстура, расположение, цвет (естественные градиенты, возможные дефекты).
Клюв/лапы: форма, структура (у живых птиц — естественные неровности, у арт-объектов — идеализированные линии).
Поведение/поза: динамика (например, напряжение лап на ветке) или статичность (как у чучел).
Фон: согласованность с естественной средой обитания вида.
Если видишь перья, натуральную текстуру, реалистичное поведение (например, птица сидит на пальце) — не пиши, что это скульптура или фейк. Скульптуры обычно имеют неестественные пропорции или материалы (металл, камень). 

ЕСЛИ НЕ УВЕРЕН:
- Напиши: "Требуется дополнительная проверка. Загрузите более четкое фото"
- Не пытайся угадать вид
- Укажи какие именно признаки вызывают сомнения

Отвечай только при 100% уверенности, исключая слова "наверное", "возможно", "скорее всего". Избегай предположений. Если на изображении птица (включая живых птиц, рисунки, мультяшных персонажей, другие изображения птиц):
Проверь, нет ли ошибки в предоставленных данных (например, неверное название вида). Если предоставленные данные содержат ошибку, укажи это в примечании. Ошибки в данных: если предоставленное название не совпадает с визуальным признакам, укажи это. Сравни визуальные признаки с данными из интернета (например, фотографии видов на eBird или в научных базах) для подтверждения идентификации.

Следуй строгой инструкции:
1. Если это птица (ТОЛЬКО живая птица, не рисунок, не статуя и др.), ответь строго по пунктам:
1. Вид: [название на русском и на латыни]
2. Описание: [3–5 коротких факта, но информация должна быть точной о виде, включая по желанию среду обитания, особенности оперения, поведения или отличия от похожих видов. Главное текста должно быть не слишком много!]
3. Состояние: [оценка здоровья, при необходимости — рекомендации - коротко]
4. Если изображение НЕ было сделано в реальных условиях (например, это снимок экрана, фотографии с бумаги, монитора и т.п.), и также если оно было сделано в реальной жизни укажи это. Обязательно укажи это в новой строке, начинающейся с:
🌐 Источник: [укажи откуда]
2. Если это НЕ птица (абсолютно другой объект), напиши:
- Что изображено: [описание]
- Сообщение: На изображении нет птицы. Анализ невозможен. Пожалуйста, загрузите фото птицы.
''';
    try {
      final compressedImage = await _compressImage(image);
      if (compressedImage == null) return '⚠️ Ошибка: Не удалось сжать изображение';
      final imageBytes = await compressedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      if (base64Image.length > 4_000_000) return '⚠️ Ошибка: Размер изображения превышает 4 МБ';
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt, 'image_base64': base64Image}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['response'] ?? 'Не получилось распознать ответ';
        if (result.trim() == 'Вид: Птица' || result.trim().isEmpty) {
          return '⚠️ Ошибка: Сервер не смог точно распознать вид птицы.';
        }
        return result;
      } else if (response.statusCode == 413) {
        return '⚠️ Ошибка 413: Изображение слишком большое.';
      } else if (response.statusCode == 504) {
        return '⚠️ Ошибка 504: Сервер не успел обработать запрос.';
      } else if (response.statusCode == 502) {
        return '⚠️ Ошибка 502: Ошибка соединения с сервером.';
      } else {
        return '⚠️ Ошибка сервера: ${response.statusCode}';
      }
    } on SocketException {
      return '⚠️ Ошибка соединения: Проверьте интернет.';
    } on TimeoutException {
      return '⚠️ Ошибка: Запрос превысил время ожидания.';
    }
  }

  String _processResponse(String text) {
    text = text.trim();
    if (text.isEmpty) return '⚠️ Пустой ответ';
    text = text.replaceAll(RegExp(r'^\d\.\s*', multiLine: true), '');
    text = text.replaceAllMapped(RegExp(r'^Вид:(.*)', multiLine: true), (match) => '🦜 Вид:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^Описание:(.*)', multiLine: true), (match) => '📘 Описание:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^(Состояние|Уверенность):(.*)', multiLine: true), (match) => '❤️ ${match.group(1)}:${match.group(2)}');
    text = text.replaceAllMapped(RegExp(r'^(Источник):(.*)', multiLine: true), (match) => '🌐 ${match.group(1)}:${match.group(2)}');
    text = text.replaceAllMapped(RegExp(r'^\s*[\*\-]\s(.*)', multiLine: true), (match) => '   • ${match.group(1)}');
    return text;
  }

  Future<void> _pickImage(bool useCamera) async {
    if (_isLoading) return;
    try {
      if (!await _checkInternet()) {
        setState(() => _result = '⚠️ Нет интернета');
        return;
      }
      File? selectedFile;
      if (useCamera) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          setState(() => _result = '⚠️ Камера не поддерживается');
          return;
        }
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            await openAppSettings();
            setState(() => _result = '⚠️ Разрешение запрещено. Разрешите в настройках.');
          } else {
            setState(() => _result = '⚠️ Предоставьте доступ к камере');
          }
          return;
        }
        final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);
        if (picked == null) {
          setState(() => _result = '⚠️ Изображение не выбрано');
          return;
        }
        final tempFile = File(picked.path);
        if (_saveCameraPhotos) {
          const channel = MethodChannel('com.example.bird_identifier/media');
          try {
            final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
            await channel.invokeMethod('saveToGallery', {'path': tempFile.path, 'name': fileName});
          } catch (e) {}
        }
        selectedFile = tempFile;
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            await openAppSettings();
            setState(() => _result = '⚠️ Разрешение на галерею запрещено.');
          } else {
            setState(() => _result = '⚠️ Предоставьте доступ к галерее');
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
            pathNameBuilder: (AssetPathEntity path) {
              if (path.isAll || path.name.toLowerCase() == 'recent' || path.name.toLowerCase() == 'recents' || path.name.toLowerCase() == 'all') {
                return 'Недавние';
              }
              return path.name;
            },
          ),
        );
        if (assets == null || assets.isEmpty) {
          setState(() => _result = '⚠️ Изображение не выбрано');
          return;
        }
        selectedFile = await assets.first.file;
      }
      if (selectedFile == null) {
        setState(() => _result = '⚠️ Ошибка: Не удалось получить файл');
        return;
      }
      setState(() {
        _selectedImage = selectedFile;
        _isLoading = true;
        _result = '';
        _isCameraSource = useCamera;
        _hasSelectedImage = true;
        _imageScaleController.stop();
      });
      final response = await _analyzeImage(_selectedImage!);
      final savedImagePath = await _saveImagePermanently(_selectedImage!);
if (savedImagePath == null) {
  setState(() {
    _result = '⚠️ Ошибка: Не удалось сохранить изображение';
    _isLoading = false;
  });
  return;
}
      setState(() async {
  _result = _processResponse(response);
  _species = null;
  _condition = null;
  
  // Извлекаем вид и состояние только при успешном анализе
  final lines = response.split('\n');
  bool isFakeSource = false;
  bool isError = response.contains('⚠️ Ошибка') || 
                 response.contains('Ошибка:') || 
                 response.contains('ошибка') ||
                 response.isEmpty;

  if (!isError) {
    for (var line in lines) {
      if (line.startsWith('1. Вид:') || line.startsWith('🦜 Вид:')) {
        _species = line.replaceAll('1. Вид:', '')
                      .replaceAll('🦜 Вид:', '')
                      .trim();
      } else if (line.startsWith('3. Состояние:') || line.startsWith('❤️ Состояние:')) {
        _condition = line.replaceAll('3. Состояние:', '')
                        .replaceAll('❤️ Состояние:', '')
                        .trim();
      } else if (line.startsWith('🌐 Источник:')) {
        isFakeSource = true;
      }
    }
  }
  
  if (isFakeSource) _isCameraSource = false;
  
  // Сохраняем в историю только успешные анализы с определенным видом
if (!isError && _species != null && _species!.isNotEmpty && _species != 'Неизвестный вид') {
  final now = DateTime.now();
  final newEntry = {
    'date': now,
    'species': _species,
    'condition': _condition ?? 'Не указано',
    'result': _result,
    'imagePath': savedImagePath,
  };
  
  // Упрощенная проверка дубликатов - только по времени (5 минут)
  bool isDuplicate = _analysisHistory.any((entry) {
    final entryDate = entry['date'] is DateTime ? entry['date'] as DateTime : DateTime.parse(entry['date'].toString());
    return entryDate.difference(now).inMinutes.abs() < 5 && entry['species'] == _species;
  });
  
  if (!isDuplicate) {
    _analysisHistory.add(newEntry);
    await _saveHistory();
    
    // Отладочная информация
    print('✅ Анализ сохранен в историю: ${_species}');
    print('📁 Путь: $savedImagePath');
    print('📊 Всего записей: ${_analysisHistory.length}');
    
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Анализ сохранен в историю'), duration: Duration(seconds: 2)),
    );
  } else {
    print('⚠️ Дубликат не сохранен: ${_species}');
  }
} else {
  print('❌ Не сохранено в историю. isError: $isError, species: $_species');
}
      });
    } catch (e) {
      setState(() => _result = '⚠️ Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _handleSharedImage(File file) {
  setState(() {
    _selectedImage = file;
    _result = '';
    _isLoading = true;
    _hasSelectedImage = true;
    _imageScaleController.stop(); 
  });
  
  _analyzeImage(file).then((response) async {
    final savedImagePath = await _saveImagePermanently(file);
    if (savedImagePath == null) {
      setState(() {
        _result = '⚠️ Ошибка: Не удалось сохранить изображение';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _result = _processResponse(response);
      _isLoading = false;
      // Сохраняем в историю с постоянным путем
      final now = DateTime.now();
      final newEntry = {
        'date': now.toIso8601String(),
        'species': _species,
        'condition': _condition,
        'result': _result,
        'imagePath': savedImagePath, // ← всегда постоянный путь
      };
      _analysisHistory.add(newEntry);
    });
    _saveHistory();
  });
}

  Future<Widget> _getImageWidget(String? path) async {
    if (path == null) return Icon(Icons.photo, color: Colors.blue.shade300);
    try {
      final file = File(path);
      if (await file.exists()) {
        return Image.file(file, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(Icons.photo, color: Colors.blue.shade300));
      }
    } catch (e) {}
    return Icon(Icons.photo, color: Colors.blue.shade300);
  }

// ------------------- История анализов -------------------
void _showHistoryDialog() {
  if (_analysisHistory.isEmpty) {
    Navigator.of(context).pop();
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
      builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  'История анализов',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _analysisHistory.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = _analysisHistory.length - 1 - index;
                      final item = _analysisHistory[reversedIndex];
                      return Dismissible(
                        key: Key('${item['date']}_${item['species'] ?? ''}'),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildConfirmationDialog(
                              title: 'Подтвердите удаление',
                              content: 'Вы действительно хотите удалить этот анализ?',
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          setState(() => _analysisHistory.removeAt(reversedIndex));
                          _saveHistory();
                          setDialogState(() {});
                          widget.scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(content: Text('Анализ удален'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: Theme.of(context).brightness == Brightness.dark
                                      ? [Colors.blue.shade900, Colors.blue.shade800]
                                      : [Colors.blue.shade50, Colors.blue.shade100],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blue.shade300),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: FutureBuilder<Widget>(
                                          future: _getImageWidget(item['imagePath']),
                                          builder: (context, snapshot) {
                                            return snapshot.hasData
                                                ? FittedBox(fit: BoxFit.cover, child: snapshot.data!)
                                                : const Icon(Icons.photo);
                                          },
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item['species'] ?? 'Неизвестный вид',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${_formatHistoryDate(item['date'])}\nСостояние: ${item['condition']?.split('\n').first ?? ''}',
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _selectedImage = item['imagePath'] != null ? File(item['imagePath']) : null;
                                        _result = item['result'];
                                        _species = item['species'];
                                        _condition = item['condition'];
                                        _isCameraSource = item['imagePath'] != null && item['imagePath']!.isNotEmpty;
                                        _hasSelectedImage = _selectedImage != null; // Добавьте эту строку
                                        if (_hasSelectedImage) {
                                          _imageScaleController.stop(); // Останавливаем анимацию
                                        }
                                      });
                                    },
                                  ),
                                  // КРЕСТИК ДЛЯ УДАЛЕНИЯ
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => _buildConfirmationDialog(
                                            title: 'Подтвердите удаление',
                                            content: 'Вы действительно хотите удалить этот анализ?',
                                          ),
                                        );
                                        if (confirm == true) {
                                          setState(() => _analysisHistory.removeAt(reversedIndex));
                                          _saveHistory();
                                          setDialogState(() {});
                                          if (mounted) {
                                            widget.scaffoldMessengerKey.currentState?.showSnackBar(
                                              const SnackBar(content: Text('Анализ удален'), duration: Duration(seconds: 2)),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedDialogButton(
                        text: 'Очистить всё',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildConfirmationDialog(
                              title: 'Подтвердите очистку',
                              content: 'Вы действительно хотите удалить всю историю анализов?',
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _analysisHistory.clear());
                            await _saveHistory();
                            if (mounted) {
                              Navigator.pop(context);
                              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                                const SnackBar(content: Text('История успешно очищена'), duration: Duration(seconds: 2)),
                              );
                            }
                          }
                        },
                        backgroundColor: Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildAnimatedDialogButton(
                        text: 'Закрыть',
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ------------------- История аудио-анализов -------------------
void _showVoiceHistoryDialog() {
  _selectedImage = null;
  if (_voiceHistory.isEmpty) {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('История аудио-анализов пуста'), duration: Duration(seconds: 2)),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  'История аудио анализов',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _voiceHistory.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = _voiceHistory.length - 1 - index;
                      final item = _voiceHistory[reversedIndex];
                      final isCurrentPlaying = _isHistoryPlaying && _currentPlayingPath == item['filePath'];
                      
                      return Dismissible(
                        key: Key('${item['date']}_${item['species'] ?? ''}'),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildConfirmationDialog(
                              title: 'Подтвердите удаление',
                              content: 'Удалить этот аудио-анализ?',
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          _removeFromVoiceHistory(reversedIndex);
                          setDialogState(() {});
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Container(
                            height: 100, // Увеличили высоту для двухстрочной даты
                            child: Stack(
                              children: [
                                // ОСНОВНОЙ КОНТЕНТ - ДОБАВЛЯЕМ INKWELL ДЛЯ НАЖАТИЯ
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _selectedImage = null;
                                      _result = item['result'];
                                      _species = item['species'];
                                      _condition = null;
                                      _isCameraSource = false;
                                      _hasSelectedImage = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16, right: 80), // Правое поле для кнопок
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue.shade300),
                                          ),
                                          child: const Icon(Icons.audio_file, color: Colors.blue),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatSpeciesText(item['species'] ?? 'Неизвестный вид'), 
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.visible,
                                              ),
                                              const SizedBox(height: 4),
                                              // Форматированная дата с переносом
                                              Text(
                                                _formatVoiceHistoryDate(item['date']),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // КНОПКА ПЛЕЕРА
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  right: 45,
                                  child: Center(
                                    child: IconButton(
                                      icon: Icon(
                                        isCurrentPlaying ? Icons.stop : Icons.play_arrow,
                                        color: isCurrentPlaying ? Colors.red.shade600 : Colors.blue.shade600,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        if (isCurrentPlaying) {
                                          _stopHistoryAudio();
                                        } else {
                                          _playAudioFromHistory(item['filePath'], setDialogState);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                // КРЕСТИК
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => _buildConfirmationDialog(
                                          title: 'Подтвердите удаление',
                                          content: 'Вы действительно хотите удалить этот аудио-анализ?',
                                        ),
                                      );
                                      if (confirm == true) {
                                        _removeFromVoiceHistory(reversedIndex);
                                        setDialogState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedDialogButton(
                        text: 'Очистить всё',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildConfirmationDialog(
                              title: 'Подтвердите очистку',
                              content: 'Вы действительно хотите удалить всю историю аудио-анализов?',
                            ),
                          );
                          if (confirm == true) {
                            _clearVoiceHistory();
                            if (mounted) {
                              Navigator.pop(context);
                              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                                const SnackBar(content: Text('История успешно очищена'), duration: Duration(seconds: 2)),
                              );
                            }
                          }
                        },
                        backgroundColor: Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildAnimatedDialogButton(
                        text: 'Закрыть',
                        onPressed: () {
                          _stopHistoryAudio();
                          Navigator.pop(context);
                        },
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// Функция для форматирования текста с переносом каждого слова
String _formatSpeciesText(String text) {
  // Разбиваем текст на слова и соединяем с переносами
  final words = text.split(' ');
  return words.join('\n');
}

// Функция для форматирования даты в нужном формате с переносом
String _formatVoiceHistoryDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  
  return '$day-$month-$year\n$hour:$minute';
}

// Обновленный метод воспроизведения
Future<void> _playAudioFromHistory(String? filePath, StateSetter setDialogState) async {
  if (filePath == null || filePath.isEmpty) {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Файл записи не найден'), duration: Duration(seconds: 2)),
    );
    return;
  }

  final file = File(filePath);
  if (!await file.exists()) {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Файл записи не существует'), duration: Duration(seconds: 2)),
    );
    return;
  }

  try {
    // Останавливаем предыдущее воспроизведение
    await _stopHistoryAudio();

    // Создаем или обновляем контроллер для проигрывания
if (_currentPlayingPath != filePath) {
  _currentPlayingPath = filePath;
  if (_historyPlayerController == null) {
    _historyPlayerController = PlayerController();
  } else {
    await _historyPlayerController!.stopPlayer();
  }

  await _historyPlayerController!.preparePlayer(path: _currentPlayingPath!);
}
await _historyPlayerController!.startPlayer();

    
    // Сохраняем путь текущего воспроизводимого файла
    _currentPlayingPath = filePath;
    
    // Обновляем состояние
    setDialogState(() {
      _isHistoryPlaying = true;
    });

    // Слушаем завершение воспроизведения
    _historyPlayerController!.onPlayerStateChanged.listen((state) async {
      if (state == PlayerState.stopped && mounted) {
        _stopHistoryAudio();
        setDialogState(() {
          _isHistoryPlaying = false;
        });
      }
    });

  } catch (e) {
    print("Ошибка воспроизведения: $e");
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Ошибка воспроизведения: $e'), duration: const Duration(seconds: 3)),
    );
  }
}

// Обновленный метод остановки
Future<void> _stopHistoryAudio() async {
  if (_historyPlayerController != null) {
    await _historyPlayerController!.stopPlayer();
    _historyPlayerController!.dispose();
    _historyPlayerController = null;
  }
  _currentPlayingPath = null;
  if (mounted) {
    setState(() {
      _isHistoryPlaying = false;
    });
  }
}

// НОВЫЙ МЕТОД: Удаление из истории
void _removeFromVoiceHistory(int index) {
  setState(() {
    _voiceHistory.removeAt(index);
  });
  _saveVoiceHistory(); // Используем существующий метод
  widget.scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Аудио-анализ удален'), duration: Duration(seconds: 2)),
  );
}

// НОВЫЙ МЕТОД: Очистка истории
void _clearVoiceHistory() {
  setState(() {
    _voiceHistory.clear();
  });
  _saveVoiceHistory(); // Используем существующий метод
}

// ------------------- История запросов о помощи -------------------
void _showRescueHistoryDialog() {
  _selectedImage = null;
  if (_rescueHistory.isEmpty) {
    Navigator.of(context).pop();
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
      builder: (context, setDialogState) {
        final Map<int, bool> expandedTiles = {};

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'История запросов о помощи',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _rescueHistory.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = _rescueHistory.length - 1 - index;
                      final item = _rescueHistory[reversedIndex];
                      final isExpanded = expandedTiles[reversedIndex] ?? false;
                      final isDark = Theme.of(context).brightness == Brightness.dark;

                      return Dismissible(
                        key: Key('${item['date']}_${item['species'] ?? ''}'),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildConfirmationDialog(
                              title: 'Подтвердите удаление',
                              content: 'Вы действительно хотите удалить этот запрос о помощи?',
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          setState(() => _rescueHistory.removeAt(reversedIndex));
                          _saveRescueHistory();
                          setDialogState(() {});
                          widget.scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(content: Text('Запрос удален'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.blueGrey.shade800, Colors.blueGrey.shade700]
                                    : [Colors.blue.shade50, Colors.blue.shade100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              onExpansionChanged: (expanded) {
                                setDialogState(() => expandedTiles[reversedIndex] = expanded);
                              },
                              iconColor: isExpanded ? Colors.blue : (isDark ? Colors.white : Colors.black87),
                              collapsedIconColor: isDark ? Colors.white : Colors.black87,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: FutureBuilder<Widget>(
                                  future: _getImageWidget(item['imagePath']),
                                  builder: (context, snapshot) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blue.shade300),
                                      ),
                                      child: snapshot.hasData
                                          ? FittedBox(fit: BoxFit.cover, child: snapshot.data!)
                                          : const Icon(Icons.photo, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                item['species'] ?? 'Неизвестный вид',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                _formatHistoryDate(item['date']),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Состояние: ${item['condition'] ?? 'Не указано'}'),
                                      const SizedBox(height: 6),
                                      Text('Местоположение: ${item['location'] ?? 'Не указано'}'),
                                      if (item['message'] != null && item['message'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text('Сообщение: ${item['message']}'),
                                        ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => _buildConfirmationDialog(
                                                title: 'Подтвердите удаление',
                                                content: 'Вы действительно хотите удалить этот запрос о помощи?',
                                              ),
                                            );
                                            if (confirm == true) {
                                              setState(() {
                                                _rescueHistory.removeAt(reversedIndex);
                                              });
                                              _saveRescueHistory();
                                              setDialogState(() {});
                                              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                                                const SnackBar(content: Text('Запрос удален'), duration: Duration(seconds: 2)),
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedDialogButton(
                        text: 'Очистить всё',
                        backgroundColor: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildConfirmationDialog(
                              title: 'Подтвердите очистку',
                              content: 'Вы действительно хотите удалить всю историю запросов о помощи?',
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _rescueHistory.clear());
                            await _saveRescueHistory();
                            if (mounted) {
                              Navigator.pop(context);
                              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                                const SnackBar(content: Text('История успешно очищена'), duration: Duration(seconds: 2)),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildAnimatedDialogButton(
                        text: 'Закрыть',
                        backgroundColor: Colors.blue,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildAnimatedDialogButton({required String text, required VoidCallback onPressed, required Color backgroundColor}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: backgroundColor.withOpacity(0.4), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ).animate(effects: [ScaleEffect(duration: 300.ms)]);
  }

  Widget _buildConfirmationDialog({required String title, required String content}) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(content, textAlign: TextAlign.center),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedDialogButton(text: 'Да', onPressed: () => Navigator.pop(context, true), backgroundColor: Colors.green),
                SizedBox(width: 16),
                _buildAnimatedDialogButton(text: 'Нет', onPressed: () => Navigator.pop(context, false), backgroundColor: Colors.red),
              ],
            ),
          ],
        ),
      ),
    ).animate(effects: [ScaleEffect(duration: 500.ms, curve: Curves.elasticOut), FadeEffect(duration: 400.ms)]);
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
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
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
${message.trim().isNotEmpty ? "Дополнительное сообщение: $message" : ""}
''';
    try {
      if (image != null) {
        final compressedImage = await _compressImage(image);
        emailMessage.attachments.add(FileAttachment(compressedImage ?? image, fileName: 'bird_image.jpg'));
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

  List<TextSpan> _buildTextSpans(String text) {
    final lines = text.split('\n');
    final spans = <TextSpan>[];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('•')) {
        final parts = line.split('•');
        spans.add(TextSpan(text: parts[0], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        spans.add(TextSpan(text: '• ', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        spans.add(TextSpan(text: parts[1].trim(), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
      } else {
        spans.add(TextSpan(text: line, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
      }
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isViewingFromHistory = ModalRoute.of(context)?.settings.name == '/history';
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAnimatedDrawer(isDarkMode, colorScheme),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.3,
      drawerEnableOpenDragGesture: true,
      appBar: _buildAnimatedAppBar(isDarkMode),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF0A0E21), Color(0xFF1D1E33), Color(0xFF2D2E44)]
                : [Colors.blue.shade50, Colors.blue.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedImageContainer(isDarkMode, colorScheme),
                const SizedBox(height: 30),
                _buildAnimatedButtons(isDarkMode, colorScheme),
                const SizedBox(height: 30),
                if (_result.isNotEmpty || _isLoading) _buildAnimatedResultContainer(isDarkMode, colorScheme),
                if (_showRescueButton && !isViewingFromHistory) _buildAnimatedRescueButton(),
              ].animate(interval: 100.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDrawer(bool isDarkMode, ColorScheme colorScheme) {
  return Drawer(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Color(0xFF0A0E21), Color(0xFF1D1E33)]
              : [Colors.blue.shade50, Colors.blue.shade100],
        ),
      ),
      child: Column(
        children: [
          // Верхний блок с названием
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [Colors.blue.shade900, Colors.blue.shade700]
                    : [Colors.blue.shade400, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 60, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Перо жизни',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Приложение для определения видов птиц и их состояния. '
                      'Помогаем сохранить пернатых друзей и заботимся об их благополучии.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ).animate(effects: [ScaleEffect(duration: 600.ms)]),

          // Список кнопок
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 8),
              children: [
                // === История анализов ===
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Уменьшил вертикальный padding
                  leading: Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    size: 28,
                  ),
                  title: Text(
                    'История анализов',
                    style: TextStyle(
                      fontSize: 18, // Увеличил размер шрифта
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showHistoryDialog();
                  },
                ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1, end: 0),

                // === История записи голосов ===
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Уменьшил вертикальный padding
                  leading: Icon(
                    Icons.music_note_outlined,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    size: 28,
                  ),
                  title: Text(
                    'История записи голосов',
                    style: TextStyle(
                      fontSize: 18, // Увеличил размер шрифта
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showVoiceHistoryDialog();
                  },
                ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1, end: 0),

                // === История запросов о помощи ===
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Уменьшил вертикальный padding
                  leading: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    size: 28,
                  ),
                  title: Text(
                    'История запросов о помощи',
                    style: TextStyle(
                      fontSize: 18, // Увеличил размер шрифта
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRescueHistoryDialog();
                  },
                ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1, end: 0),
              ],
            ),
          ),

          // Кнопка Telegram
          _buildTelegramButton(),

          SizedBox(height: 8),

          // Кнопка Настройки
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0, left: 16, right: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF003366) : Colors.blue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _navigateToSettings(isDarkMode),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.settings, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Настройки',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  AppBar _buildAnimatedAppBar(bool isDarkMode) {
    return AppBar(
      title: Text(
        'Определитель птиц',
        style: TextStyle(
          fontFamily: 'ComicSans',
          fontWeight: FontWeight.w800,
          shadows: [Shadow(blurRadius: 10, color: Colors.blue.withOpacity(0.3), offset: Offset(0, 2))],
        ),
      ).animate(effects: [FadeEffect(duration: 800.ms), SlideEffect(begin: Offset(0, -0.5), curve: Curves.easeOut)]),
      leading: IconButton(icon: Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode ? [Color(0xFF0A0E21), Color(0xFF1D1E33)] : [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
    );
  }

  Widget _buildAnimatedImageContainer(bool isDarkMode, ColorScheme colorScheme) {
  return _hasSelectedImage
      ? Container( // Статичный контейнер когда изображение выбрано
          width: MediaQuery.of(context).size.width * 0.85,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode ? [Color(0xFF1D1E33), Color(0xFF2D2E44)] : [Colors.blue.shade100, Colors.blue.shade200],
            ),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.2), blurRadius: 20, offset: Offset(0, 10))],
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
          ),
          child: _selectedImage != null
              ? GestureDetector(
                  onTap: () async {
                    final File? editedImage = await Navigator.push<File?>(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => ImageZoomScreen(image: _selectedImage!),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
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
                  child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.file(_selectedImage!, fit: BoxFit.cover)),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 80, color: Colors.blue.withOpacity(0.7)),
                    SizedBox(height: 16),
                    Text(
                      'Загрузите изображение или запись голоса птицы',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.8)),
                    ),
                  ],
                ),
        )
      : ScaleTransition( // Анимированный контейнер только когда нет изображения
          scale: _imageScaleAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode ? [Color(0xFF1D1E33), Color(0xFF2D2E44)] : [Colors.blue.shade100, Colors.blue.shade200],
              ),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(isDarkMode ? 0.3 : 0.2), blurRadius: 20, offset: Offset(0, 10))],
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 80, color: Colors.blue.withOpacity(0.7)).animate(effects: [ScaleEffect(duration: 2000.ms, curve: Curves.elasticOut)]),
                SizedBox(height: 16),
                Text(
                  'Загрузите изображение или запись голоса птицы',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.8)),
                ).animate(effects: [FadeEffect(duration: 1000.ms)]),
              ],
            ),
          ),
        ).animate(effects: [ScaleEffect(duration: 600.ms, curve: Curves.elasticOut), FadeEffect(duration: 800.ms)]);
      }

  Widget _buildAnimatedButtons(bool isDarkMode, ColorScheme colorScheme) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        _buildAnimatedButton(onPressed: _isLoading ? null : () => _pickImage(true), icon: Icons.camera_alt_rounded, text: "Камера", isDarkMode: isDarkMode),
        _buildAnimatedButton(onPressed: _isLoading ? null : () => _pickImage(false), icon: Icons.photo_library_rounded, text: "Галерея", isDarkMode: isDarkMode),
        _buildAnimatedButton(
          onPressed: _isLoading ? null : () async {
            await showDialog(
              context: context,
              builder: (context) => VoiceMenuDialog(onVoiceAnalyzed: addVoiceToHistory),
            );
          },
          icon: Icons.mic,
          text: "Запись голоса",
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildAnimatedButton({required VoidCallback? onPressed, required IconData icon, required String text, required bool isDarkMode}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: Colors.blue.withOpacity(isDarkMode ? 0.4 : 0.3),
                  blurRadius: isDarkMode ? 15 : 12,
                  spreadRadius: isDarkMode ? 1 : 0.5,
                  offset: Offset(0, isDarkMode ? 6 : 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? Colors.grey.shade400
              : isDarkMode
                  ? Color(0xFF1D1E33)
                  : Colors.blue.shade700,
          foregroundColor: onPressed == null
              ? Colors.grey.shade600
              : Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ).animate(effects: [ScaleEffect(duration: 400.ms, curve: Curves.elasticOut), FadeEffect(duration: 600.ms)]);
  }

  Widget _buildAnimatedResultContainer(bool isDarkMode, ColorScheme colorScheme) {
  final bool showRetryButton = _result.contains('⚠️') && 
                              (_result.contains('интернет') || 
                               _result.contains('соединение') ||
                               _result.contains('таймаут'));

  return Container(
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
    child: _isLoading
        ? Center(
            child: Lottie.asset(
              'assets/animations/Animation.json',
              width: 200,
              height: 200,
              repeat: true,
              frameRate: FrameRate(60),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text('🧠 Результаты анализа:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: colorScheme.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                child: SelectableText.rich(
                  TextSpan(children: _buildTextSpans(_result)),
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
              // Кнопка повторного анализа
if (showRetryButton) 
  Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: _selectedImage != null ? () async {
          setState(() {
            _isLoading = true;
            _result = '';
          });
          
          final response = await _analyzeImage(_selectedImage!);
          final savedImagePath = await _saveImagePermanently(_selectedImage!);
          
          if (savedImagePath == null) {
            setState(() {
              _result = '⚠️ Ошибка: Не удалось сохранить изображение';
              _isLoading = false;
            });
            return;
          }
          
          setState(() {
            _result = _processResponse(response);
            _isLoading = false;
            
            // Сохраняем в историю при повторном анализе
            final lines = response.split('\n');
            String? species;
            String? condition;
            bool isError = response.contains('⚠️ Ошибка') || 
                           response.contains('Ошибка:') || 
                           response.isEmpty;

            if (!isError) {
              for (var line in lines) {
                if (line.startsWith('1. Вид:') || line.startsWith('🦜 Вид:')) {
                  species = line.replaceAll('1. Вид:', '')
                              .replaceAll('🦜 Вид:', '')
                              .trim();
                } else if (line.startsWith('3. Состояние:') || line.startsWith('❤️ Состояние:')) {
                  condition = line.replaceAll('3. Состояние:', '')
                                  .replaceAll('❤️ Состояние:', '')
                                  .trim();
                }
              }
            }
            
            if (!isError && species != null && species.isNotEmpty && species != 'Неизвестный вид') {
              final now = DateTime.now();
              final newEntry = {
                'date': now,
                'species': species,
                'condition': condition ?? 'Не указано',
                'result': _result,
                'imagePath': savedImagePath,
              };
              
              // Сохраняем без проверки дубликатов для повторного анализа
              _analysisHistory.add(newEntry);
              _saveHistory();
              
              print('✅ Повторный анализ сохранен: $species');
              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text('Повторный анализ сохранен в историю'), duration: Duration(seconds: 2)),
              );
            }
          });
        } : null,
        icon: Icon(Icons.refresh),
        label: Text('Повторный анализ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    ),
  ),
            ],
          ),
  ).animate(effects: [ScaleEffect(duration: 600.ms, curve: Curves.elasticOut), FadeEffect(duration: 800.ms)]);
}

  Widget _buildAnimatedRescueButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ScaleTransition(
        scale: _rescuePulseScale,
        child: AnimatedBuilder(
          animation: _rescuePulseColor,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [_rescuePulseColor.value!, _rescuePulseColor.value!.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: _rescuePulseColor.value!.withOpacity(0.4), blurRadius: 15, offset: Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: _requestRescue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emergency_rounded, size: 24), SizedBox(width: 12), Text('Запросить помощь', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
              ),
            );
          },
        ),
      ).animate(effects: [SlideEffect(begin: Offset(0, 20), curve: Curves.easeOut), FadeEffect(duration: 600.ms)]),
    );
  }

  void _navigateToSettings(bool isDarkMode) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(
          onThemeToggle: widget.onThemeToggle,
          isDarkMode: isDarkMode,
          onSaveCameraPhotosToggle: _saveCameraPhotosSetting,
          saveCameraPhotos: _saveCameraPhotos,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }
}

// =============== ВСПОМОГАТЕЛЬНЫЕ ЭКРАНЫ ===============
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

class _SettingsScreenState extends State<SettingsScreen> {
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

  void _showHelpDialog(BuildContext context) {
    final textColor = _isDark ? Colors.white : Colors.black;
    final subTextColor = _isDark ? Colors.white70 : Colors.black87;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '📋 Подробная справка по приложению',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                _buildHelpSection('🎯 Краткая цель', '«Перо жизни» — это мобильное приложение, созданное для того, чтобы каждый мог быстро и аккуратно определить вид птицы, оценить её состояние и при необходимости вызвать помощь. Приложение подходит как для любителей природы, так и для волонтёров и работников реабилитационных центров.', subTextColor),
_buildHelpSection('🔄 Как это работает — пошагово', '• Сделайте фотографию птицы с камеры или загрузите из галереи\n• Или запишите голос птицы для аудиоанализа через встроенный диктофон\n• Изображение или аудио обрабатывается нейросетью — определяется вид, особенности оперения/пения и признаки возможных травм или болезней\n• Вы получаете развернутую карточку с результатом: название вида (рус./лат.), ключевые признаки, оценка состояния и краткие рекомендации\n• Если птица нуждается в помощи, вы можете отправить запрос в реабилитационный центр прямо из приложения — с фотографией и геолокацией', subTextColor),
_buildHelpSection('🔍 Что именно анализируется', '• Оперение: нарушение структуры, проплешины, нехарактерные пятна\n• Поведение/поза: заторможенность, повреждение лап/клюва, нестабильная поза\n• Наличие ран, кровотечения, следов удара, деформаций\n• Голос: особенности пения, виды птиц по аудиозаписи', subTextColor),
_buildHelpSection('📤 Отправка запроса о помощи', 'При отправке запроса приложение предложит добавить комментарий и автоматически приложит координаты места. Перед отправкой потребуется разрешение на доступ к геолокации. Центр получит фото, описание и ссылку на карту — это ускорит помощь.', subTextColor),
_buildHelpSection('📊 История и приватность', 'Все результаты анализов и отправленные запросы сохраняются локально на устройстве (история доступна в разделе «История анализов»). Данные не передаются третьим лицам без вашего запроса. Для отправки в центр используются только поля, которые вы подтверждаете: фото, комментарий и геолокация.', subTextColor),
_buildHelpSection('🛡️ Фильтрация подделок', 'Приложение включает алгоритм, который помогает отличать реальные фотографии птиц от рисунков, скульптур или фотографий на экране. Это снижает ложные срабатывания и направляет ресурсы на реальные случаи помощи.', subTextColor),
_buildHelpSection('💡 Советы для хорошего анализа', '• Сфотографируйте птицу крупно, в фокусе и при хорошем освещении\n• Сделайте несколько кадров с разных ракурсов, если возможно\n• Для аудиоанализа: запишите пение птицы в тихом месте без фоновых шумов\n• Не обесценивайте маленькую птицу — часто даже мелкие виды важны для экосистемы', subTextColor),
_buildHelpSection('❌ Частые проблемы и решения', '• Если приложение не распознаёт вид — попробуйте другое фото с чётким ракурсом\n• Если аудиоанализ не работает — проверьте качество записи и отсутствие шумов\n• Если отправка запроса не проходит — проверьте интернет и разрешения геолокации\n• Если вы видите ложные детекции — напишите в Поддержку с примером (почта внизу)', subTextColor),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Спасибо, что помогаете птицам — вместе мы сильнее! 🐦',
                    style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(String title, String content, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isDark ? Colors.white : Colors.black), textAlign: TextAlign.left),
        ),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(color: textColor, height: 1.4)),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isDark ? Colors.white : Colors.black;
    final subTextColor = _isDark ? Colors.white70 : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(fontFamily: 'ComicSans', fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6, color: subTextColor),
              title: Text('Тема', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              subtitle: Text(_isDark ? 'Тёмная' : 'Светлая', style: TextStyle(color: subTextColor)),
              trailing: Switch(value: _isDark, onChanged: _onThemeChanged, activeColor: Colors.blue),
            ),
            CheckboxListTile(
              value: _savePhotos,
              onChanged: (value) => _onSavePhotosChanged(value!),
              title: Text('Сохранять фотографии, сделанные через камеру', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              secondary: Icon(Icons.camera_alt, color: subTextColor),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text('Автор идеи программы:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Кривошеенко Данил Дмитриевич', style: TextStyle(color: subTextColor, fontSize: 14)),
                  const SizedBox(height: 16),
                  Text('Авторы разработки программы:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Панов Максим Романович', style: TextStyle(color: subTextColor, fontSize: 14)),
                  Text('Полежаев Дмитрий Дмитриевич', style: TextStyle(color: subTextColor, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text('Официальная почта:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 8),
                  SelectableText('perozhizni@gmail.com', style: TextStyle(color: subTextColor, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(120, 120), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Поддержка", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: FittedBox(
                child: ElevatedButton.icon(
                  onPressed: () => _showHelpDialog(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  icon: const Icon(Icons.article_outlined, size: 30),
                  label: const Text('Подробная справка по приложению', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const Spacer(),
            Text('Версия приложения: 2.7.5', style: TextStyle(color: subTextColor, fontStyle: FontStyle.italic, fontSize: 14)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр изображения', style: TextStyle(fontSize: 16,)),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: _isLoading ? null : _editImage)],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _editedImageBytes != null
                      ? Image.memory(_editedImageBytes!)
                      : Image.file(widget.image),
            ),
          ),
          if (_editedImageBytes != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                onPressed: _isLoading ? null : _saveEditedImage,
                icon: const Icon(Icons.save),
                label: const Text("Сохранить", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editImage() async {
    setState(() => _isLoading = true);
    try {
      final imageBytes = await widget.image.readAsBytes();
      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ImageEditor(image: imageBytes)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка редактирования: $e'), duration: Duration(seconds: 2)));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e'), duration: Duration(seconds: 2)));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<File> _attachedImages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
  // Если уже выбрано 10 фото — блокируем добавление
  if (_attachedImages.length >= 10) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Можно прикрепить не более 10 фотографий")),
    );
    return;
  }

  final int remaining = 10 - _attachedImages.length;

  final List<AssetEntity>? assets = await AssetPicker.pickAssets(
    context,
    pickerConfig: AssetPickerConfig(
      maxAssets: remaining, // ← разрешаем выбрать только оставшееся количество
      requestType: RequestType.image,
      textDelegate: const RussianAssetPickerTextDelegate(),
      pathNameBuilder: (AssetPathEntity path) {
        if (path.isAll ||
            path.name.toLowerCase() == 'recent' ||
            path.name.toLowerCase() == 'recents' ||
            path.name.toLowerCase() == 'all') {
          return 'Недавние';
        }
        return path.name;
      },
    ),
  );

  if (assets != null && assets.isNotEmpty) {
    final List<File> newImages = [];
    for (var asset in assets) {
      final file = await asset.file;
      if (file != null) newImages.add(file);
    }

    setState(() {
      _attachedImages.addAll(newImages);
    });

    // Если после добавления достигнут лимит — сообщаем пользователю
    if (_attachedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Вы достигли лимита — максимум 10 фото")),
      );
    }
  }
}

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  Future<void> _sendSupport() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && _attachedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заполните сообщение или прикрепите хотя бы одно фото"))
      );
      return;
    }
    
    setState(() => _isSending = true);
    final smtpServer = gmail('perozhizni.helper@gmail.com', 'blii goux nufu itcj');
    final emailMessage = Message()
      ..from = Address('perozhizni.helper@gmail.com')
      ..recipients.add('perozhizni@gmail.com')
      ..subject = 'Обращение в поддержку (Перо жизни)'
      ..text = '''
Пользователь отправил запрос в поддержку.
${messageText.isNotEmpty ? "Сообщение: $messageText" : ""}
''';

    try {
      for (int i = 0; i < _attachedImages.length; i++) {
        final image = _attachedImages[i];
        final compressed = await FlutterImageCompress.compressAndGetFile(
          image.path,
          '${image.parent.path}/support_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          quality: 70,
        );
        if (compressed != null) {
          emailMessage.attachments.add(FileAttachment(File(compressed.path), fileName: 'support_image_$i.jpg'));
        }
      }
      
      await send(emailMessage, smtpServer);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Сообщение успешно отправлено"))
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка отправки: $e"))
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = _messageController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Поддержка",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'ComicSans',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Если у вас есть вопросы или вы нашли баг в приложении — напишите нам.\n"
              "Вы можете приложить скриншоты или фото, чтобы мы быстрее разобрались.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // TextField с центрированным плейсхолдером и всплывающей меткой
            TextField(
              controller: _messageController,
              maxLines: 4,
              cursorColor: Colors.blue,
              textAlign: TextAlign.start, // Вводимый текст слева
              decoration: InputDecoration(
                hintText: isEmpty ? "Ваше сообщение" : null, // Центрированный плейсхолдер
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.blue[300]!.withOpacity(0.6) : Colors.blue.withOpacity(0.6),
                  fontSize: 16,
                ),
                labelText: isEmpty ? null : "Ваше сообщение", // Метка появляется при вводе
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.blue[300] : Colors.blue,
                  fontSize: 16,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto, // Всплывает при фокусе
                floatingLabelAlignment: FloatingLabelAlignment.center, // Центрированная метка
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                alignLabelWithHint: true,
              ),
              textAlignVertical: TextAlignVertical.center,
            ),

            const SizedBox(height: 12),

            // Отображение прикреплённых изображений
            if (_attachedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _attachedImages[index],
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Кнопки вертикально
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _pickImages,
                  icon: const Icon(Icons.photo),
                  label: const Text("Прикрепить фото"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendSupport,
                  icon: const Icon(Icons.send),
                  label: Text(_isSending ? "Отправка…" : "Отправить"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Center(
        child: Text(
          'Запрос в реабилитационный центр',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
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
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Состояние: ${widget.condition}',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Местоположение: ${widget.location}',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(widget.locationLink);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  widget.scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Не удалось открыть карту'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                'Открыть на карте',
                style: TextStyle(
                  color: colorScheme.primary,
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
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                fillColor: colorScheme.surfaceVariant,
                filled: true,
              ),
              maxLines: 4,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withOpacity(0.7),
          ),
          child: const Text('Отмена'),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    try {
                      await widget.onSubmit(_messageController.text);
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      widget.scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('Ошибка: $e'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Отправить'),
          ),
        ),
      ],
    );
  }
}

// =============== АУДИО-ЗАПИСЬ И ВЫБОР ===============
class VoiceMenuDialog extends StatelessWidget {
  final Function(String, String)? onVoiceAnalyzed;

  const VoiceMenuDialog({Key? key, this.onVoiceAnalyzed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Выберите действие',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SquareButton(
                  size: 100,
                  icon: Icons.mic,
                  text: "Записать\nголос",
                  color: Colors.blue.shade600,
                  onPressed: () async {
                    final result = await showDialog<String?>(
                      context: context,
                      builder: (context) => VoiceRecorderDialog(
                        onAnalyze: (filePath) {
                          Navigator.pop(context, filePath);
                        },
                      ),
                    );
                    
                    if (result != null) {
                      Navigator.pop(context); // Закрываем VoiceMenuDialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BirdNetAnalyzerScreen(
                            initialFilePath: result,
                            onAnalysisComplete: onVoiceAnalyzed,
                          ),
                        ),
                      );
                    }
                  },
                ),
                SquareButton(
                  size: 100,
                  icon: Icons.audio_file,
                  text: "Выбрать\nзапись",
                  color: Colors.green.shade600,
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
                    );
                    if (result != null && result.files.single.path != null) {
                      String path = result.files.single.path!;
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BirdNetAnalyzerScreen(
                            initialFilePath: path,
                            onAnalysisComplete: onVoiceAnalyzed,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Могут быть неточности",
              style: TextStyle(
                color: Colors.orange.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                  minimumSize: Size(0, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Закрыть"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceRecorderDialog extends StatefulWidget {
  final Function(String)? onAnalyze;
  const VoiceRecorderDialog({Key? key, this.onAnalyze}) : super(key: key);

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final WaveformRecorderController _waveController = WaveformRecorderController();

  bool _isPlaying = false;
  bool _isRecordingPaused = false;
  bool _isInitialized = false;
  // ignore: unused_field
  bool _isRecording = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _requestPermission();
      setState(() => _isInitialized = true);
    } catch (e) {
      _showSnackBar("Ошибка инициализации: $e");
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _requestPermission() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) throw Exception('Нет доступа к микрофону');
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.request();
      if (!audioStatus.isGranted) throw Exception('Нет разрешения на запись аудио');
    }
  }

  Future<void> _toggleRecording() async {
  try {
    if (_waveController.isRecording) {
      await _waveController.stopRecording();

      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isRecordingPaused = false;
          _isRecording = false;
          _currentPosition = Duration.zero;
        });
      }
    } else {
      if (_isPlaying) await _stopPlaying();

      await _waveController.startRecording();

      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }
    }
  } catch (e) {
    _showSnackBar("Ошибка записи: $e");
  }
}


  Future<void> _pauseResumeRecording() async {
    try {
      if (_waveController.isRecording) {
        if (_isRecordingPaused) {
          await _waveController.resumeRecording();
          setState(() => _isRecordingPaused = false);
        } else {
          await _waveController.pauseRecording();
          setState(() => _isRecordingPaused = true);
        }
      }
    } catch (e) {
      _showSnackBar("Ошибка паузы записи: $e");
    }
  }

  Future<void> _playRecording() async {
    final file = _waveController.file;
    if (file == null || !File(file.path).existsSync()) return;

    try {
      await _audioPlayer.stop();
      await _positionSubscription?.cancel();
      await _playerStateSubscription?.cancel();

      await _audioPlayer.setSourceUrl(file.path);
      _totalDuration = (await _audioPlayer.getDuration()) ?? Duration.zero;

      setState(() => _currentPosition = Duration.zero);
      await _audioPlayer.resume();
      setState(() => _isPlaying = true);

      _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
        if (mounted) setState(() => _currentPosition = pos);
      });

      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted && state == PlayerState.stopped) {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
        }
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      });
    } catch (e) {
      _showSnackBar("Ошибка воспроизведения: $e");
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    } catch (e) {
      _showSnackBar("Ошибка остановки: $e");
    }
  }

  Future<void> _deleteRecording() async {
    try {
      if (_isPlaying) await _stopPlaying();
      if (_waveController.isRecording) await _waveController.stopRecording();

      final file = _waveController.file;
      if (file != null && File(file.path).existsSync()) {
        await File(file.path).delete();
      }

      // Очистка контроллера
      _waveController.clear();

      if (mounted) {
        setState(() {
          _currentPosition = Duration.zero;
          _totalDuration = Duration.zero;
          _isPlaying = false;
          _isRecordingPaused = false;
        });
      }
    } catch (e) {
      _showSnackBar("Ошибка удаления: $e");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _waveController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blue = Colors.blue.shade600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 380,
        child: !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: _waveController,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Запись голоса",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: blue)),
                      const SizedBox(height: 16),

                      // волны
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.shade900.withOpacity(0.1)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: blue.withOpacity(0.3)),
                        ),
                        child: _waveController.isRecording
                            ? _buildRecordingWave(blue)
                            : _isPlaying
                                ? _buildPlaybackWave(blue)
                                : _buildIdleState(blue),
                      ),
                      const SizedBox(height: 20),

                      // Таймер при воспроизведении
                      if (_isPlaying && !_waveController.isRecording)
                        Text(
                          "${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: blue,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Кнопки управления
                      _buildControlButtons(blue),

                      const SizedBox(height: 20),
                      _formatInfo(blue),
                      const SizedBox(height: 20),

                      // Кнопки закрытия и анализа
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_isPlaying) _stopPlaying();
                              if (_waveController.isRecording) _waveController.stopRecording();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              foregroundColor:
                                  isDark ? Colors.white : Colors.black,
                            ),
                            child: const Text("Закрыть"),
                          ),
                        ),
                        // Кнопка Анализ появляется когда есть запись и НЕ идет запись и НЕ идет воспроизведение
                        if (_waveController.file != null &&
                            !_waveController.isRecording &&
                            !_isPlaying) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, _waveController.file!.path);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Анализ"),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  );
                }),
      ),
    );
  }

  Widget _buildRecordingWave(Color blue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: WaveformRecorder(
            height: 120,
            controller: _waveController,
            waveColor: blue,
            durationTextStyle: TextStyle(
              color: blue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            onRecordingStopped: () {
              if (mounted) setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackWave(Color blue) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;
    final progressIndex = (40 * progress).toInt();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.volume_up, size: 40, color: blue),
        const SizedBox(height: 8),
        Text("Воспроизведение...",
            style: TextStyle(color: blue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(40, (i) {
              final h = 8 + (i % 8) * 4.0;
              final played = i <= progressIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 2,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: played ? blue : blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState(Color blue) {
    if (_waveController.file == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Нажмите 'Записать' чтобы начать",
                style: TextStyle(color: blue, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
    // Используем длительность напрямую из контроллера
    final duration = _waveController.length; // или _waveController.duration
    final seconds = duration.inSeconds;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 40, color: blue),
          const SizedBox(height: 8),
          Text("Запись готова",
              style: TextStyle(
                color: blue, 
                fontWeight: FontWeight.bold,
                fontSize: 18,
              )),
          const SizedBox(height: 4),
          Text(
            "(${seconds}.${(duration.inMilliseconds % 1000) ~/ 100} сек)",
            style: TextStyle(
              color: blue.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

  Widget _buildControlButtons(Color blue) {
    return Column(
      children: [
        if (!_waveController.isRecording && _waveController.file == null)
          SquareButton(
            size: 90,
            icon: Icons.mic,
            text: "Записать",
            color: blue,
            fontSize: 14,
            onPressed: _toggleRecording,
          ),
        
        if (_waveController.isRecording)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SquareButton(
                size: 90,
                icon: _isRecordingPaused ? Icons.play_arrow : Icons.pause,
                text: _isRecordingPaused ? "Продолжить" : "Пауза",
                color: Colors.orange,
                fontSize: 11,
                onPressed: _pauseResumeRecording,
              ),
              const SizedBox(width: 12),
              SquareButton(
                size: 90,
                icon: Icons.stop,
                text: "Стоп",
                color: Colors.red,
                fontSize: 14,
                onPressed: _toggleRecording,
              ),
            ],
          ),
        
        if (!_waveController.isRecording && _waveController.file != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlaying)
                SquareButton(
                  size: 90,
                  icon: Icons.play_arrow,
                  text: "Прослушать",
                  color: Colors.green,
                  fontSize: 12,
                  onPressed: _playRecording,
                ),
              
              if (_isPlaying)
                SquareButton(
                  size: 90,
                  icon: Icons.stop,
                  text: "Стоп",
                  color: Colors.orange,
                  fontSize: 14,
                  onPressed: _stopPlaying,
                ),
              
              const SizedBox(width: 12),
              
              SquareButton(
                size: 90,
                icon: Icons.delete,
                text: "Удалить",
                color: Colors.red,
                fontSize: 14,
                onPressed: _deleteRecording,
              ),
            ],
          ),
      ],
    );
  }

  Widget _formatInfo(Color blue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blue.withOpacity(0.3)),
      ),
      child: Text(
        "WAV • 48kHz • 16-bit • Mono",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: blue,
        ),
      ),
    );
  }
}

class SquareButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final String text;
  final Color color;
  final double fontSize;
  final VoidCallback onPressed;

  const SquareButton({
    Key? key,
    required this.size,
    required this.icon,
    required this.text,
    required this.color,
    required this.onPressed,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size * 0.3),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _WavParseResult {
  final List<double> samples;
  final int sampleRate;
  final int channels;
  _WavParseResult({required this.samples, required this.sampleRate, required this.channels});
}