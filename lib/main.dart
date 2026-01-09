// =============== ИМПОРТЫ ===============
import 'dart:async';
// ignore: unused_import
import 'dart:math' as math;
import 'dart:typed_data';
// ignore: unused_import
import 'package:audio_session/audio_session.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart' hide PlayerState;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
// ignore: unused_import
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
import 'package:android_intent_plus/android_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'bird_net_analyzer_screen.dart';
// ignore: unused_import
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool _isRescuerMode = false;
  int _titleTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadRescuerMode();
    _checkFirstLaunch();
  }

  Future<void> _loadRescuerMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRescuerMode = prefs.getBool('isRescuerMode') ?? false;
    });
  }

  Future<void> _toggleRescuerMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRescuerMode', value);
    setState(() {
      _isRescuerMode = value;
    });
  }

  void _handleTitleTap() {
    final now = DateTime.now();
    
    if (_lastTapTime == null || now.difference(_lastTapTime!) > Duration(seconds: 2)) {
      _titleTapCount = 1;
    } else {
      _titleTapCount++;
    }
    
    _lastTapTime = now;
    
    if (_titleTapCount >= 7) {
      _titleTapCount = 0;
      _showSecretMenu();
    }
  }

  Future<void> _showSecretMenu() async {
  final navContext = _navigatorKey.currentContext;
  if (navContext == null) return;

  // ignore: unused_local_variable
  String password = '';
  bool passwordCorrect = false;
  bool showError = false;
  final ScrollController _scrollController = ScrollController();

  await showDialog(
    context: navContext,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        // Проверяем, уже ли активирован режим спасателя
        final isAlreadyActivated = _isRescuerMode;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 16,
          title: Column(
            children: [
              Icon(
                isAlreadyActivated ? Icons.verified : Icons.verified_user,
                size: 50,
                color: isAlreadyActivated ? Colors.green : Colors.blue
              ),
              SizedBox(height: 10),
              Text(
                "Секретное меню",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAlreadyActivated 
                      ? "Режим спасателя уже активирован!" 
                      : "Вы нашли секретное меню!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  if (!isAlreadyActivated) ...[
                    Text(
                      "Для активации возможности включения режима спасателя введите пароль:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: TextField(
                        onChanged: (value) {
                          password = value;
                          setState(() {
                            passwordCorrect = value == 'kubsu1st';
                            showError = value.isNotEmpty && !passwordCorrect;
                            
                            // Мгновенно прокручиваем вниз при ошибке
                            if (showError) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                              });
                            }
                          });
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          labelStyle: TextStyle(
                            color: showError 
                              ? Colors.red 
                              : Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showError ? Colors.red : Theme.of(context).colorScheme.outline,
                              width: showError ? 2 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showError ? Colors.red : Theme.of(context).colorScheme.outline,
                              width: showError ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showError ? Colors.red : Theme.of(context).colorScheme.primary,
                              width: showError ? 2 : 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          suffixIcon: passwordCorrect ? Icon(Icons.check, color: Colors.green) : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Сообщение об ошибке
                    if (showError)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        margin: EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Неверный пароль. Попробуйте еще раз.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                  ] else ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Возможность включения режима спасателя уже активирована!',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            // Кнопка "Выйти из режима" (если режим уже активирован)
            if (isAlreadyActivated)
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _toggleRescuerMode(false);
                    Navigator.pop(context);
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Возможность включения режима спасателя отключена!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Выйти из режима'),
                ),
              ),
            
            if (isAlreadyActivated) SizedBox(height: 8),
            
            // Основные кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Закрыть'),
                  ),
                ),
                if (!isAlreadyActivated) ...[
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: passwordCorrect
                          ? () async {
                              await _toggleRescuerMode(true);
                              Navigator.pop(context);
                              _scaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text('Возможность включения режима спасателя активирована!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: passwordCorrect ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Активировать'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    ),
  );
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
    } catch (e) {}
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
          isRescuerMode: _isRescuerMode,
          onTitleTap: _handleTitleTap,
          onRescuerModeToggle: _toggleRescuerMode,
        ),
      ),
    );
  }
}

// =============== УЛУЧШЕННОЕ ОКНО ЗАПРОСА ПОМОЩИ ===============
class EnhancedRescueRequestDialog extends StatefulWidget {
  final String species;
  final String condition;
  final String recommendations;
  final String location;
  final String locationLink;
  final double? latitude;
  final double? longitude;
  final File? image;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Future<void> Function(String message) onSubmit;

  const EnhancedRescueRequestDialog({
    super.key,
    required this.species,
    required this.condition,
    required this.recommendations,
    required this.location,
    required this.locationLink,
    this.latitude,
    this.longitude,
    this.image,
    required this.scaffoldMessengerKey,
    required this.onSubmit,
  });

  @override
  State<EnhancedRescueRequestDialog> createState() => _EnhancedRescueRequestDialogState();
}

// Диалог запроса помощи
class _EnhancedRescueRequestDialogState extends State<EnhancedRescueRequestDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500, 
          maxHeight: MediaQuery.of(context).size.height * 0.8
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Запрос экстренной помощи',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildInfoCard('🦜 Вид птицы', widget.species, Icons.pets, Colors.blue),
                    _buildInfoCard('🩺 Состояние', widget.condition, Icons.medical_services, Colors.red),
                    
                    if (widget.recommendations.isNotEmpty)
                      _buildInfoCard('💡 Рекомендации', widget.recommendations, Icons.lightbulb, Colors.orange),
                    
                    _buildInfoCard('📍 Местоположение', widget.location, Icons.location_on, Colors.green),
                    
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: InkWell(
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
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.map, color: Colors.green, size: 24),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Открыть на карте',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Нажмите для просмотра местоположения в Google Maps',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.green),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    if (widget.image != null)
                      Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.photo, color: Colors.purple, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Фотография птицы',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  widget.image!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.message, color: Colors.blueAccent, size: 24),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Дополнительная информация',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    softWrap: true, // Разрешить перенос текста
                                    overflow: TextOverflow.visible, // Показать весь текст
                                    maxLines: 2, // Максимум 2 строки
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            TextField(
                              controller: _messageController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Опишите подробнее ситуацию или добавьте контакты для связи...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: isDarkMode 
                                  ? Colors.grey.shade900.withOpacity(0.3)
                                  : Colors.grey.shade50,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Column(
              children: [
                // Кнопка Отмена (первая)
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: colorScheme.primary),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Отмена', style: TextStyle(color: colorScheme.primary)),
                ),
                
                SizedBox(height: 12), // Отступ между кнопками
                
                // Кнопка Отправить запрос (вторая)
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    minimumSize: Size(double.infinity, 50),
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
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              SizedBox(width: 8),
                              Text('Отправить запрос', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
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

class ImprovedRescueMessengerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rescueHistory;
  final List<Map<String, dynamic>> rescueMessages;
  final bool isRescuerMode;
  final Function(bool) onRescuerModeToggle;
  final Future<void> Function(String requestId, String message) onSendMessage;
  final Future<void> Function(String requestId, List<String> filePaths) onSendFiles;

  const ImprovedRescueMessengerScreen({
    Key? key,
    required this.rescueHistory,
    required this.rescueMessages,
    required this.isRescuerMode,
    required this.onRescuerModeToggle,
    required this.onSendMessage,
    required this.onSendFiles,
  }) : super(key: key);

  @override
  _ImprovedRescueMessengerScreenState createState() => _ImprovedRescueMessengerScreenState();
}

// =============== УЛУЧШЕННЫЙ ЭКРАН ЗАПРОСОВ О ПОМОЩИ ===============
class _ImprovedRescueMessengerScreenState extends State<ImprovedRescueMessengerScreen> {
  // ignore: unused_field
  final TextEditingController _messageController = TextEditingController();
  // ignore: unused_field
  final ScrollController _scrollController = ScrollController();
  String? _selectedRequestId;
  List<Map<String, dynamic>> _filteredMessages = [];
  // ignore: unused_field
  bool _isSending = false;
  // ignore: unused_field
  List<String> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.rescueHistory.isNotEmpty) {
      _selectedRequestId = widget.rescueHistory.last['id'];
      _updateFilteredMessages();
    }
  }

  void _updateFilteredMessages() {
    if (_selectedRequestId == null) {
      _filteredMessages = [];
    } else {
      _filteredMessages = widget.rescueMessages
          .where((msg) => msg['requestId'] == _selectedRequestId)
          .toList();
      _filteredMessages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    }
    
    // Уведомляем об изменении
    if (mounted) {
      setState(() {});
    }
  }

  void _openChat(Map<String, dynamic> request) {
    // Получаем актуальные сообщения для этого запроса
    final messagesForRequest = widget.rescueMessages
        .where((msg) => msg['requestId'] == request['id'])
        .toList();
    
    messagesForRequest.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatScreen(
          request: request,
          messages: messagesForRequest,
          isRescuerMode: widget.isRescuerMode,
          onSendMessage: (message) async {
            await widget.onSendMessage(request['id'], message);
            // После отправки сообщения обновляем список сообщений
            if (mounted) {
              setState(() {
                // Обновляем filteredMessages для текущего выбранного запроса
                _updateFilteredMessages();
              });
            }
          },
          onSendFiles: (filePaths) async {
            await widget.onSendFiles(request['id'], filePaths);
            // После отправки файлов обновляем список сообщений
            if (mounted) {
              setState(() {
                // Обновляем filteredMessages для текущего выбранного запроса
                _updateFilteredMessages();
              });
            }
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isRescuer = message['sender'] == 'rescuer';
    final isSystem = message['sender'] == 'system';
    final hasFiles = message['files'] != null && (message['files'] as List).isNotEmpty;

    if (isSystem) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message['text'],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: isRescuer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isRescuer)
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              'Пользователь',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isRescuer ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isRescuer)
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
            
            SizedBox(width: 8),
            
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRescuer 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message['text'] != null && message['text'].toString().isNotEmpty)
                      Text(
                        message['text'].toString(),
                        style: TextStyle(
                          color: isRescuer
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    
                    if (hasFiles)
                      Column(
                        children: (message['files'] as List).map<Widget>((file) {
                          return Container(
                            margin: EdgeInsets.only(top: 8),
                            child: Text(
                              '📎 ${file.toString().split('/').last}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    SizedBox(height: 4),
                    
                    Text(
                      DateFormat('HH:mm').format(
                        message['timestamp'] is DateTime 
                          ? message['timestamp'] 
                          : DateTime.parse(message['timestamp'].toString()),
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (isRescuer)
              CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.security, color: Colors.white, size: 18),
              ),
          ],
        ),
      ],
    );
  }

  void _showRescueDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Детали запроса',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('🦜 Вид птицы', request['species'] ?? 'Неизвестный вид'),
                      _buildDetailItem('🩺 Состояние', request['condition'] ?? 'Не указано'),
                      _buildDetailItem('📍 Местоположение', request['location'] ?? 'Не указано'),
                      _buildDetailItem('📝 Сообщение', request['message'] ?? 'Без сообщения'),
                      if (request['date'] != null)
                        _buildDetailItem('📅 Дата', DateFormat('dd.MM.yyyy HH:mm').format(
                          request['date'] is DateTime 
                            ? request['date'] 
                            : DateTime.parse(request['date'].toString()),
                        )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Закрыть'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openChat(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Открыть чат'),
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

  Widget _buildDetailItem(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Запросы о помощи'),
      ),
      body: Column(
        children: [
          // УБРАЛ заголовок "Запросы о помощи" отсюда, так как он уже есть в AppBar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                // УБРАЛ: Text('Запросы о помощи', ...)
                SizedBox(height: 8), // Уменьшил отступ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Режим спасателя',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(width: 12),
                    Switch(
                      value: widget.isRescuerMode,
                      onChanged: widget.onRescuerModeToggle,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Список запросов (вертикальный)
          Expanded(
            child: widget.rescueHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Нет активных запросов',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Отправленные запросы о помощи будут отображаться здесь',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: widget.rescueHistory.length,
                    itemBuilder: (context, index) {
                      final request = widget.rescueHistory[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: InkWell(
                          onTap: () => _showRescueDetails(request),
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          request['species'] ?? 'Неизвестный вид',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Удалить'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'share',
                                            child: Row(
                                              children: [
                                                Icon(Icons.share, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Поделиться'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            // Удаление запроса
                                          } else if (value == 'share') {
                                            // Поделиться запросом
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    request['condition'] ?? 'Состояние не указано',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    request['location'] ?? 'Местоположение не указано',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd.MM.yyyy HH:mm').format(
                                          request['date'] is DateTime 
                                            ? request['date'] 
                                            : DateTime.parse(request['date'].toString()),
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _openChat(request),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                        child: Text('Открыть чат'),
                                      ),
                                    ],
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
          
          // Кнопка очистки всех запросов
          if (widget.rescueHistory.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Подтвердите очистку'),
                      content: Text('Вы действительно хотите удалить все запросы?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Очистить', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    // Очистка истории запросов
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Очистить все запросы'),
              ),
            ),
        ],
      ),
    );
  }
}

// =============== ЭКРАН ЧАТА ===============
class _ChatScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> messages;
  final bool isRescuerMode;
  final Future<void> Function(String message) onSendMessage;
  final Future<void> Function(List<String> filePaths) onSendFiles;

  const _ChatScreen({
    Key? key,
    required this.request,
    required this.messages,
    required this.isRescuerMode,
    required this.onSendMessage,
    required this.onSendFiles,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  List<String> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty && _attachedFiles.isEmpty) return;

    setState(() => _isSending = true);

    try {
      if (_messageController.text.isNotEmpty) {
        await widget.onSendMessage(_messageController.text);
      }
      
      if (_attachedFiles.isNotEmpty) {
        await widget.onSendFiles(_attachedFiles);
      }

      _messageController.clear();
      _attachedFiles.clear();
      
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _attachFiles() async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 10 - _attachedFiles.length,
        requestType: RequestType.image,
        textDelegate: const RussianAssetPickerTextDelegate(),
        pathNameBuilder: (AssetPathEntity path) {
          if (path.isAll || path.name.toLowerCase() == 'recent') {
            return 'Недавние';
          }
          return path.name;
        },
      ),
    );

    if (assets != null && assets.isNotEmpty) {
      for (var asset in assets) {
        final file = await asset.file;
        if (file != null) {
          _attachedFiles.add(file.path);
        }
      }
      setState(() {});
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isRescuer = message['sender'] == 'rescuer';
    final isSystem = message['sender'] == 'system';
    final hasFiles = message['files'] != null && (message['files'] as List).isNotEmpty;

    if (isSystem) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message['text'],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: isRescuer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isRescuer)
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              'Пользователь',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isRescuer ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isRescuer)
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
            
            SizedBox(width: 8),
            
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRescuer 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message['text'] != null && message['text'].toString().isNotEmpty)
                      Text(
                        message['text'].toString(),
                        style: TextStyle(
                          color: isRescuer
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    
                    if (hasFiles)
                      Column(
                        children: (message['files'] as List).map<Widget>((file) {
                          return Container(
                            margin: EdgeInsets.only(top: 8),
                            child: Text(
                              '📎 ${file.toString().split('/').last}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    SizedBox(height: 4),
                    
                    Text(
                      DateFormat('HH:mm').format(
                        message['timestamp'] is DateTime 
                          ? message['timestamp'] 
                          : DateTime.parse(message['timestamp'].toString()),
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (isRescuer)
              CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.security, color: Colors.white, size: 18),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.request['species'] ?? 'Запрос о помощи',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Чат',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Заголовок запроса
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request['species'] ?? 'Неизвестный вид',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.request['condition'] ?? 'Состояние не указано',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Сообщения
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      'Нет сообщений',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(12),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(widget.messages[index]);
                    },
                  ),
          ),
          
          // Прикрепленные файлы
          if (_attachedFiles.isNotEmpty)
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedFiles.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_file, size: 12),
                        SizedBox(width: 4),
                        Text(
                          _attachedFiles[index].split('/').last,
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Icon(Icons.close, size: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          // Поле ввода
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _attachFiles,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: widget.isRescuerMode 
                        ? 'Введите ответ...' 
                        : 'Введите сообщение...',
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? CircularProgressIndicator(strokeWidth: 2)
                      : Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============== ОСНОВНОЙ ЭКРАН ===============
class BirdIdentifierScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final bool isRescuerMode;
  final VoidCallback onTitleTap;
  final Function(bool) onRescuerModeToggle;

  const BirdIdentifierScreen({
    super.key, 
    required this.onThemeToggle, 
    required this.scaffoldMessengerKey,
    required this.isRescuerMode,
    required this.onTitleTap,
    required this.onRescuerModeToggle,
  });
  
  @override
  State<BirdIdentifierScreen> createState() => _BirdIdentifierScreenState();
}

class _BirdIdentifierScreenState extends State<BirdIdentifierScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  String _result = '';
  bool showRetryButton = false;
  bool _isLoading = false;
  String? _species;
  String? _condition;
  // ignore: unused_field
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
  List<Map<String, dynamic>> _rescueMessages = [];
  Timer? _emailCheckTimer;

  // Исправленная проверка для кнопки вызова спасателей
  bool get _showRescueButton {
    if (_condition == null) return false;
    
    final condition = _condition!.toLowerCase();
    final keywords = ['травм', 'не может', 'рана', 'слаб', 'болен', 'слом', 'плох', 'нуждает', 'помощ', 'кров', 'ушиб', 'тяжел', 'срочн', 'экстрен', 'опасн'];
    
    for (final keyword in keywords) {
      if (condition.contains(keyword)) {
        return true;
      }
    }
    
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadRescueHistory();
    _loadVoiceHistory();
    _loadSaveCameraPhotos();
    _loadRescueMessages();
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
    
    // Запускаем таймер проверки email каждые 30 секунд
    if (widget.isRescuerMode) {
      _startEmailCheckTimer();
    }
  }

  void _startEmailCheckTimer() {
    _emailCheckTimer?.cancel();
    _emailCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkForNewEmails();
    });
  }

  Future<void> _checkForNewEmails() async {
    // В реальном приложении здесь был бы запрос к почтовому API
    // Сейчас имитируем получение новых сообщений
    if (_rescueMessages.isNotEmpty && mounted) {
      // Проверяем, есть ли непрочитанные сообщения от пользователей
      final hasUnread = _rescueMessages.any((msg) => msg['sender'] == 'user' && !msg['read']);
      if (hasUnread) {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Новое сообщение в чате помощи'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant BirdIdentifierScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRescuerMode != oldWidget.isRescuerMode) {
      if (widget.isRescuerMode) {
        _startEmailCheckTimer();
      } else {
        _emailCheckTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rescuePulseController.dispose();
    _imageScaleController.dispose();
    _emailCheckTimer?.cancel();
    super.dispose();
  }

  // =============== EMAIL МЕССЕНДЖЕР ===============
  Future<void> _loadRescueMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('rescue_messages');
    
    if (messagesJson != null) {
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      setState(() {
        _rescueMessages.clear();
        _rescueMessages.addAll(messagesList.map((item) {
          return {
            'id': item['id'],
            'type': item['type'],
            'sender': item['sender'],
            'text': item['text'],
            'timestamp': DateTime.parse(item['timestamp']),
            'requestId': item['requestId'],
            'read': item['read'] ?? false,
            'files': item['files'] ?? [],
          };
        }).toList());
      });
    }
  }

  Future<void> _saveRescueMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = jsonEncode(_rescueMessages.map((item) => {
      'id': item['id'],
      'type': item['type'],
      'sender': item['sender'],
      'text': item['text'],
      'timestamp': item['timestamp'].toIso8601String(),
      'requestId': item['requestId'],
      'read': item['read'],
      'files': item['files'] ?? [],
    }).toList());
    await prefs.setString('rescue_messages', messagesJson);
  }

  Future<void> _sendEmailMessage(String recipientEmail, String recipientPassword, 
                                String subject, String body, String? requestId) async {
    try {
      final smtpServer = gmail(recipientEmail, recipientPassword);
      
      // Находим существующее письмо с этим requestId или создаем новую цепочку
      final message = Message()
        ..from = Address(recipientEmail)
        ..recipients.add('perozhizni@gmail.com') // Основная почта приложения
        ..subject = subject
        ..text = body;

      await send(message, smtpServer);
      
      return;
    } catch (e) {
      print('Ошибка отправки email: $e');
      throw Exception('Не удалось отправить сообщение через email');
    }
  }

  // =============== ЗАПРОС ПОМОЩИ ===============
  Future<void> _requestRescue() async {
  // Проверяем, не в режиме ли спасателя (спасателям не нужен пароль)
  if (!widget.isRescuerMode) {
    // Показываем диалог с извинениями и запросом пароля
    final navContext = context;
    // ignore: unused_local_variable
    String password = '';
    bool passwordCorrect = false;
    bool showError = false;
    final ScrollController _scrollController = ScrollController();

    await showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 16,
            title: Column(
              children: [
                Icon(
                  Icons.construction,
                  size: 50,
                  color: Colors.orange
                ),
                SizedBox(height: 10),
                Text(
                  "Функция в разработке",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Извините за неудобства!\n\n"
                      "Функция вызова спасателей временно находится в разработке "
                      "и доступна только для авторизованных пользователей.\n\n"
                      "Для доступа к этой функции введите пароль:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      child: TextField(
                        onChanged: (value) {
                          password = value;
                          setState(() {
                            passwordCorrect = value == 'birdsave2024'; // Пароль для спасателей
                            showError = value.isNotEmpty && !passwordCorrect;
                            
                            // Мгновенно прокручиваем вниз при ошибке
                            if (showError) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                              });
                            }
                          });
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Пароль доступа',
                          labelStyle: TextStyle(
                            color: showError 
                              ? Colors.red 
                              : Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showError ? Colors.red : Theme.of(context).colorScheme.outline,
                              width: showError ? 2 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showError ? Colors.red : Theme.of(context).colorScheme.outline,
                              width: showError ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showError ? Colors.red : Theme.of(context).colorScheme.primary,
                              width: showError ? 2 : 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          suffixIcon: passwordCorrect ? Icon(Icons.check, color: Colors.green) : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Сообщение об ошибке
                    if (showError)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        margin: EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Неверный пароль. Доступ разрешен только сотрудникам спасательных служб.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            actions: [
              // Основные кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Отмена'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: passwordCorrect
                          ? () {
                              Navigator.pop(context);
                              // После ввода правильного пароля продолжаем обычный запрос
                              _continueRescueRequest();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: passwordCorrect ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Продолжить'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  } else {
    // Для спасателей (уже в режиме спасателя) - сразу продолжаем
    _continueRescueRequest();
  }
}

// Функция продолжения запроса помощи (оригинальная логика)
Future<void> _continueRescueRequest() async {
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
  double? latitude;
  double? longitude;
  
  try {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    latitude = position.latitude;
    longitude = position.longitude;
    
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String city = place.locality ?? 'Неизвестный город';
      String street = place.street?.replaceFirst('ул.', '').trim() ?? 'Неизвестная улица';
      String country = place.country ?? 'Неизвестная страна';
      location = '$country, $city, $street';
    } else {
      location = 'Координаты: ${position.latitude}, ${position.longitude}';
    }
    locationLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
  } catch (e) {
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Ошибка получения местоположения: $e'), duration: Duration(seconds: 3)),
    );
    return;
  }
  
  if (!mounted) return;
  
  // Ищем рекомендации
  String recommendations = '';
  final lines = _result.split('\n');
  for (var line in lines) {
    if (line.contains('💡 Рекомендации:')) {
      recommendations = line.replaceFirst('💡 Рекомендации:', '').trim();
      break;
    }
  }

  await showDialog(
    context: context,
    builder: (context) => EnhancedRescueRequestDialog(
      species: _species!,
      condition: _condition!,
      recommendations: recommendations,
      location: location,
      locationLink: locationLink,
      latitude: latitude,
      longitude: longitude,
      image: _selectedImage,
      scaffoldMessengerKey: widget.scaffoldMessengerKey,
      onSubmit: (message) async {
        await _sendRescueRequest(
          species: _species!,
          condition: _condition!,
          recommendations: recommendations,
          location: location,
          message: message,
          image: _selectedImage,
          locationLink: locationLink,
          latitude: latitude,
          longitude: longitude,
        );
      },
    ),
  );
}

  Future<void> _sendRescueRequest({
    required String species,
    required String condition,
    required String recommendations,
    required String location,
    required String message,
    required File? image,
    required String locationLink,
    required double? latitude,
    required double? longitude,
  }) async {
    setState(() => _isLoading = true);
    String? imagePath;
    if (image != null) {
      imagePath = await _saveImagePermanently(image);
    }
    
    // Создаем уникальный ID для запроса
    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    
    // Формируем тело письма
    final emailBody = '''
ЗАПРОС О ПОМОЩИ - ПРИЛОЖЕНИЕ "ПЕРО ЖИЗНИ"

Вид птицы: $species
Состояние: $condition
Рекомендации: $recommendations
Местоположение: $location
Ссылка на карту: $locationLink
Координаты: ${latitude ?? 'N/A'}, ${longitude ?? 'N/A'}
ID запроса: $requestId

${message.trim().isNotEmpty ? "ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ:\n$message" : ""}

---
Это сообщение отправлено автоматически из приложения "Перо жизни".
Ответьте на это письмо, чтобы продолжить переписку по запросу $requestId
''';

    final emailSubject = 'Запрос помощи: $species ($requestId)';
    
    try {
      // Отправляем email через почту приложения
      await _sendEmailMessage(
        'perozhizni@gmail.com',
        'bmzo ggza nxuv biqc',
        emailSubject,
        emailBody,
        requestId,
      );
      
      // Сохраняем в историю
      setState(() {
        _rescueHistory.add({
          'id': requestId,
          'date': DateTime.now(),
          'species': species,
          'condition': condition,
          'location': location,
          'message': message,
          'imagePath': imagePath,
          'latitude': latitude,
          'longitude': longitude,
          'locationLink': locationLink,
        });
      });
      
      await _saveRescueHistory();
      
      // Добавляем системное сообщение о создании запроса
      final systemMessage = {
        'id': 'sys_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'system',
        'sender': 'system',
        'text': 'Запрос о помощи создан и отправлен в спасательный центр',
        'timestamp': DateTime.now(),
        'requestId': requestId,
        'read': true,
      };
      
      setState(() {
        _rescueMessages.add(systemMessage);
      });
      
      await _saveRescueMessages();
      
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Запрос успешно отправлен в спасательный центр'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Сохраняем локально даже при ошибке
      final localMessage = {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'system',
        'sender': 'system',
        'text': 'Запрос создан локально (ошибка отправки через email)',
        'timestamp': DateTime.now(),
        'requestId': requestId,
        'read': true,
        'error': e.toString(),
      };
      
      setState(() {
        _rescueMessages.add(localMessage);
      });
      
      await _saveRescueMessages();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =============== УЛУЧШЕННЫЙ МЕССЕНДЖЕР ===============
  void _showRescueMessenger() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImprovedRescueMessengerScreen(
          rescueHistory: _rescueHistory,
          rescueMessages: _rescueMessages,
          isRescuerMode: widget.isRescuerMode,
          onRescuerModeToggle: widget.onRescuerModeToggle,
          onSendMessage: (String requestId, String message) async {
            await _sendRescueMessage(requestId, message);
          },
          onSendFiles: (String requestId, List<String> filePaths) async {
            await _sendRescueFiles(requestId, filePaths);
          },
        ),
      ),
    );
  }

  Future<void> _sendRescueMessage(String requestId, String message) async {
    try {
      // Находим запрос
      final request = _rescueHistory.firstWhere(
        (req) => req['id'] == requestId,
        orElse: () => {},
      );
      
      if (request.isEmpty) {
        throw Exception('Запрос не найден');
      }
      
      final species = request['species'] ?? 'Неизвестный вид';
      final subject = widget.isRescuerMode 
        ? 'Ответ спасателя: $species ($requestId)'
        : 'Сообщение от пользователя: $species ($requestId)';
      
      // Формируем тело письма как ответ на существующее письмо
      final emailBody = '''
${widget.isRescuerMode ? 'ОТВЕТ СПАСАТЕЛЯ' : 'СООБЩЕНИЕ ОТ ПОЛЬЗОВАТЕЛЯ'}

ID запроса: $requestId
Вид птицы: $species

Сообщение:
$message

---
Это сообщение отправлено из приложения "Перо жизни"
''';
      
      // Отправляем через почту
      await _sendEmailMessage(
        widget.isRescuerMode ? 'baklan.center@gmail.com' : 'perozhizni@gmail.com',
        widget.isRescuerMode ? 'mouu cxrs gccw webk' : 'bmzo ggza nxuv biqc',
        subject,
        emailBody,
        requestId,
      );
      
      // Сохраняем сообщение локально
      final userMessage = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'text',
        'sender': widget.isRescuerMode ? 'rescuer' : 'user',
        'text': message,
        'timestamp': DateTime.now(),
        'requestId': requestId,
        'read': true,
      };
      
      setState(() {
        _rescueMessages.add(userMessage);
      });
      
      await _saveRescueMessages();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сообщение отправлено'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendRescueFiles(String requestId, List<String> filePaths) async {
    // В реальном приложении здесь была бы отправка файлов
    // Пока сохраняем только информацию о файлах
    final fileMessage = {
      'id': 'file_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'files',
      'sender': widget.isRescuerMode ? 'rescuer' : 'user',
      'text': 'Прикрепленные файлы',
      'timestamp': DateTime.now(),
      'requestId': requestId,
      'read': true,
      'files': filePaths,
    };
    
    setState(() {
      _rescueMessages.add(fileMessage);
    });
    
    await _saveRescueMessages();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Файлы прикреплены'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // =============== ОСТАЛЬНЫЕ МЕТОДЫ ===============
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
        _rescueHistory.clear();
        _rescueHistory.addAll(historyList.map((item) {
          return {
            'id': item['id'] ?? 'req_${DateTime.parse(item['date']).millisecondsSinceEpoch}',
            'date': DateTime.parse(item['date']),
            'species': item['species'],
            'condition': item['condition'],
            'location': item['location'],
            'message': item['message'],
            'imagePath': item['imagePath'],
            'latitude': item['latitude'],
            'longitude': item['longitude'],
            'locationLink': item['locationLink'],
          };
        }).toList());
      });
    }
  }

  Future<void> _saveRescueHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_rescueHistory.map((item) => {
      'id': item['id'],
      'date': item['date'].toIso8601String(),
      'species': item['species'],
      'condition': item['condition'],
      'location': item['location'],
      'message': item['message'],
      'imagePath': item['imagePath'],
      'latitude': item['latitude'],
      'longitude': item['longitude'],
      'locationLink': item['locationLink'],
    }).toList());
    await prefs.setString('rescueHistory', historyJson);
  }

  Future<String?> _saveImagePermanently(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'bird_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${directory.path}/$fileName';
      
      final imageBytes = await image.readAsBytes();
      final newFile = File(newPath);
      await newFile.writeAsBytes(imageBytes);
      
      if (await newFile.exists()) {
        return newPath;
      }
      return null;
    } catch (e) {
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
            bool fileExists = false;
            if (imagePath != null && imagePath is String) {
              try {
                fileExists = File(imagePath).existsSync();
              } catch (e) {
                fileExists = false;
              }
            }
            
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
      } catch (e) {}
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
    return '$day-$month-$year $hour:$minute';
  }

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

  Future<String> _analyzeImage(File image) async {
    const serverUrl = 'https://gemini-proxy-nine-alpha.vercel.app/generate';
    const prompt = '''
Ты — эксперт по орнитологии с навыками компьютерного зрения и по распознаванию птиц. Твоя задача — максимально точно определить вид птицы на изображении, включая даже самых маленьких (например, синиц, крапивников, воробьёв, карликовых и других). Для повышения точности дополнительно проверяй информацию в интернете, используя достоверные источники (например, eBird, Cornell Lab of Ornithology, научные статьи, Красные книги) для подтверждения визуальных признаков. Обязательно найди похожие фотографии в интернете и сравни с ними перед ответом. Не путай птиц Цесарка и Глазчатой индейкой! Отвечай только когда найдешь точное совпадение по визуальным признакам. 

Обращай особое внимание на то что некоторые птицы действительно могут быть очень миниатюрными — это не повод считать их игрушками или скульптурами. Будь особенно внимателен, чтобы не перепутать маленькую живую птицу с искусственным объектом. Обращай внимание на детали:
Перья: текстура, расположение, цвет (естественные градиенты, возможные дефекты).
Клюв/лапы: форма, структура (у живых птиц — естественные неровности, у арт-объектов — идеализированные линии).
Поведение/поза: динамика (например, напряжение лап на ветке) или статичность (как у чучел).
Фон: согласованность с естественной средой обитания вида.
Если видишь перья, натуральную текстуру, реалистичное поведение (например, птица сидит на пальце) — не пиши, что это скульптура или фейк. Скульптуры обычно имеют неестественные пропорции или материалы (металл, камень). 

Отвечай только при 100% уверенности, исключая слова "наверное", "возможно", "скорее всего". Избегай предположений. Если на изображении птица (включая живых птиц, рисунки, мультяшных персонажей, другие изображения птиц):
Проверь, нет ли ошибки в предоставленных данных (например, неверное название вида). Если предоставленные данные содержат ошибку, укажи это в примечании. Ошибки в данных: если предоставленное название не совпадает с визуальным признакам, укажи это. Сравни визуальные признаки с данными из интернете (например, фотографии видов на eBird или в научных базах) для подтверждения идентификации.

Следуй строгой инструкции:
1. Если это птица (ТОЛЬКО живая птица, не рисунок, не статуя и др.), ответь строго по пунктам:
1. Вид: [название на русском и на английском языке]
2. Описание: [3–5 коротких факта, но информация должна быть точной о виде, включая по желанию среду обитания, особенности оперения, поведения или отличия от похожих видов. Главное текста должно быть не слишком много!]
3. Состояние: оцени визуальное состояние организма по фото, всё ли хорошо или нет. [оценка здоровья при необходимости]
4. Рекомендации: [Если состояние плохое - дай базовые рекомендации по уходу/помощи. Укажи что нужно сделать для помощи до прихода спасателей ( как защитить птицу и др. ) - если это необходимо. Если отличное - напиши "Птица не требуется в рекомендациях"]
5. Статус птицы: укажи, включён ли вид в Красную книгу России или международные списки охраны природы, выбрав одну из формулировок — «Не занесён в Красную книгу» (поясни, что вид распространён и не является редким), «Редкий вид» (уточни, где имеет охранный статус, например в региональной Красной книге), «Находится под угрозой исчезновения» (уточни, в какой именно Красной книге и какие меры применяются) или «Охраняется международными соглашениями» (кратко объясни значение договора для широкой аудитории), обязательно сохранив прямое упоминание Красной книги в ответе - то есть слова 'Красная книга' должны упоминаться хотя бы 1 раз!.
6. Сортировка (триаж) - дай птице сортировку согласно методическим рекомендациям ВНИИ экология (написать к какой группе относится: "Зелёная группа" "Жёлтая группа" "Красная группа") и немного информации о ней.
7. Если изображение НЕ было сделано в реальных условиях (например, это снимок экрана, фотографии с бумаги, монитора и т.п.), и также если оно было сделано в реальной жизни укажи это. Обязательно укажи это в новой строке, начинающейся с:
🌐 Источник: [укажи откуда]
2. Если это НЕ птица (абсолютно другой объект), напиши используя тут маркерные точки[•]:
- Что изображено: [описание]
- Сообщение: На изображении нет птицы. Анализ невозможен. Пожалуйста, загрузите фото птицы.
''';
    try {
      final compressedImage = await _compressImage(image);
      if (compressedImage == null) {
        return '⚠️ Ошибка: Не удалось сжать изображение.';
      }

      final imageBytes = await compressedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      if (base64Image.length > 4_000_000) {
        return '⚠️ Ошибка: Размер изображения превышает 4 МБ.';
      }

      final response = await http
          .post(
            Uri.parse(serverUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': prompt,
              'image_base64': base64Image,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['response'] ?? 'Не удалось получить результат.';

        setState(() {
          showRetryButton = result.contains('⚠️') ||
                           result.contains('Ошибка') ||
                           result.contains('ошибка') ||
                           result.contains('таймаут') ||
                           result.contains('интернет') ||
                           result.contains('соединение') ||
                           result.isEmpty;
        });

        return result;
      }

      String errorMessage;
      switch (response.statusCode) {
        case 400: errorMessage = '⚠️ Ошибка 400: Некорректный запрос.'; break;
        case 401: errorMessage = '⚠️ Ошибка 401: Доступ запрещён. Проверьте ключ API.'; break;
        case 403: errorMessage = '⚠️ Ошибка 403: Недостаточно прав для выполнения запроса.'; break;
        case 404: errorMessage = '⚠️ Ошибка 404: Сервер не найден.'; break;
        case 413: errorMessage = '⚠️ Ошибка 413: Изображение слишком большое.'; break;
        case 429: errorMessage = '⚠️ Ошибка 429: Слишком много запросов. Подождите немного.'; break;
        case 500: errorMessage = '⚠️ Ошибка 500: Внутренняя ошибка сервера.'; break;
        case 502: errorMessage = '⚠️ Ошибка 502: Ошибка шлюза. Попробуйте позже.'; break;
        case 503: errorMessage = '⚠️ Ошибка 503: Сервер временно недоступен.'; break;
        case 504: errorMessage = '⚠️ Ошибка 504: Превышено время ожидания сервера.'; break;
        default: errorMessage = '⚠️ Ошибка сервера: ${response.statusCode}'; break;
      }

      setState(() => showRetryButton = true);
      return errorMessage;
    } on SocketException {
      setState(() => showRetryButton = true);
      return '⚠️ Ошибка: Отсутствует подключение к интернету.';
    } on TimeoutException {
      setState(() => showRetryButton = true);
      return '⚠️ Ошибка: Время ожидания запроса истекло.';
    } on http.ClientException {
      setState(() => showRetryButton = true);
      return '⚠️ Ошибка сети: Интернет был отключён или нестабилен.';
    } on FormatException {
      setState(() => showRetryButton = true);
      return '⚠️ Ошибка формата: Некорректный ответ от сервера.';
    } catch (e) {
      setState(() => showRetryButton = true);
      return '⚠️ Неизвестная ошибка: $e';
    }
  }

  String _processResponse(String text) {
    text = text.trim();
    if (text.isEmpty) return '⚠️ Пустой ответ';
    text = text.replaceAll(RegExp(r'^\d\.\s*', multiLine: true), '');
    text = text.replaceAllMapped(RegExp(r'^Вид:(.*)', multiLine: true), (match) => '🦜 Вид:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^Описание:(.*)', multiLine: true), (match) => '📘 Описание:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^(Состояние|Уверенность):(.*)', multiLine: true), (match) => '❤️ ${match.group(1)}:${match.group(2)}');
    text = text.replaceAllMapped(RegExp(r'^Рекомендации:(.*)', multiLine: true), (match) => '💡 Рекомендации:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^Статус птицы:(.*)', multiLine: true), (match) => '📊 Статус птицы:${match.group(1)}');
    text = text.replaceAllMapped(RegExp(r'^Сортировка \(триаж\):(.*)', multiLine: true), (match) => '🏷️ Сортировка (триаж):${match.group(1)}');
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

        XFile? picked;
        try {
          picked = await ImagePicker().pickImage(source: ImageSource.camera);
        } catch (e) {
          picked = null;
        }

        if (picked == null) {
          if (Platform.isAndroid) {
            final intent = AndroidIntent(action: 'android.media.action.IMAGE_CAPTURE');
            if (await intent.canResolveActivity() == true) {
              await intent.launchChooser('Выберите приложение камеры');
              setState(() => _result = '📸 Ожидание изображения из камеры...');
            } else {
              setState(() => _result = '⚠️ Камера не найдена');
            }
          } else {
            setState(() => _result = '⚠️ Камера не поддерживается на этой платформе');
          }
          return;
        }

        final tempFile = File(picked.path);

        if (_saveCameraPhotos) {
          const channel = MethodChannel('com.example.bird_identifier/media');
          try {
            final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
            await channel.invokeMethod('saveToGallery', {'path': tempFile.path, 'name': fileName});
          } catch (_) {}
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
              if (path.isAll || path.name.toLowerCase() == 'recent') {
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

        final lines = response.split('\n');
        bool isFakeSource = false;
        bool isError = response.contains('⚠️ Ошибка') || 
                       response.contains('Ошибка:') || 
                       response.contains('ошибка') ||
                       response.isEmpty;

        if (!isError) {
          for (var line in lines) {
            if (line.startsWith('1. Вид:') || line.startsWith('🦜 Вид:')) {
              _species = line.replaceAll('1. Вид:', '').replaceAll('🦜 Вид:', '').trim();
            } else if (line.startsWith('3. Состояние:') || line.startsWith('❤️ Состояние:')) {
              _condition = line.replaceAll('3. Состояние:', '').replaceAll('❤️ Состояние:', '').trim();
            } else if (line.startsWith('🌐 Источник:')) {
              isFakeSource = true;
            } else if (line.contains('На изображении нет птицы')) {
              _species = 'Не птица';
            }
          }
          
          if (_species == null && !isError) {
            _species = 'Не птица';
          }
        }

        if (isFakeSource) _isCameraSource = false;

        if (!isError && _species != null && _species!.isNotEmpty) {
          final now = DateTime.now();
          final newEntry = {
            'date': now,
            'species': _species,
            'condition': _condition ?? 'Не указано',
            'result': _result,
            'imagePath': savedImagePath,
          };

          bool isDuplicate = _analysisHistory.any((entry) {
            final entryDate = entry['date'] is DateTime ? entry['date'] : DateTime.parse(entry['date'].toString());
            return entryDate.difference(now).inMinutes.abs() < 5 && entry['species'] == _species;
          });

          if (!isDuplicate) {
            _analysisHistory.add(newEntry);
            await _saveHistory();
            widget.scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Анализ сохранен в историю'), duration: Duration(seconds: 2)),
            );
          }
        }
      });

    } catch (e) {
      setState(() => _result = '⚠️ Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
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
        borderRadius: BorderRadius.circular(25),
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
          borderRadius: BorderRadius.circular(25),
          onTap: () async {
            const tgUrl = 'tg://resolve?domain=PeroZhizni';
            const webUrl = 'https://t.me/PeroZhizni';

            try {
              final tgUri = Uri.parse(tgUrl);
              final webUri = Uri.parse(webUrl);

              if (Platform.isAndroid) {
                try {
                  final intent = AndroidIntent(
                    action: 'action_view',
                    data: webUrl,
                  );
                  await intent.launchChooser('Открыть ссылку с помощью');
                  return;
                } catch (e) {}
              }

              if (await canLaunchUrl(tgUri)) {
                await launchUrl(tgUri, mode: LaunchMode.externalApplication);
                return;
              }

              if (await canLaunchUrl(webUri)) {
                await launchUrl(webUri, mode: LaunchMode.externalApplication);
                return;
              }

              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(content: Text('Не удалось открыть ссылку')),
              );
            } catch (e) {
              widget.scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text('Ошибка: $e')),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    ).animate(effects: [ScaleEffect(duration: 300.ms, curve: Curves.easeInOut)]);
  }

  // =============== БОКОВОЕ МЕНЮ ===============
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
                        'Приложение для определения видов птиц и их состояния. Помогаем сохранить пернатых друзей и заботимся об их благополучии',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(effects: [ScaleEffect(duration: 600.ms)]),

            Expanded(
              child: ListView(
                padding: EdgeInsets.only(top: 8),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      size: 28,
                    ),
                    title: Text(
                      'История анализов',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showHistoryDialog();
                    },
                  ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1, end: 0),

                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.music_note_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      size: 28,
                    ),
                    title: Text(
                      'История записи голосов',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showVoiceHistoryDialog();
                    },
                  ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1, end: 0),

                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      size: 28,
                    ),
                    title: Text(
                      'Запросы о помощи',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showRescueMessenger();
                    },
                  ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1, end: 0),
                ],
              ),
            ),

            _buildTelegramButton(),

            SizedBox(height: 8),

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
      title: GestureDetector(
        onTap: widget.onTitleTap,
        child: Text(
          'Определитель птиц',
          style: TextStyle(
            fontFamily: 'ComicSans',
            fontWeight: FontWeight.w800,
            shadows: [Shadow(blurRadius: 10, color: Colors.blue.withOpacity(0.3), offset: Offset(0, 2))],
          ),
        ),
      ).animate(effects: [FadeEffect(duration: 800.ms), SlideEffect(begin: Offset(0, -0.5), curve: Curves.easeOut)]),
      leading: IconButton(
        icon: Icon(Icons.menu_rounded), 
        onPressed: () => _scaffoldKey.currentState?.openDrawer()
      ),
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

  // =============== ОСТАЛЬНЫЕ ВИДЖЕТЫ ===============
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

  Widget _buildAnimatedImageContainer(bool isDarkMode, ColorScheme colorScheme) {
    return _hasSelectedImage
        ? GestureDetector(
            onLongPress: () {
              if (_hasSelectedImage || _result.isNotEmpty) {
                _resetAnalysis();
                widget.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text('Анализ очищен'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                Container(
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
                ),
              ],
            ),
          )
        : GestureDetector(
            onLongPress: () {
              if (_hasSelectedImage || _result.isNotEmpty) {
                _resetAnalysis();
                widget.scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text('Анализ очищен'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: ScaleTransition(
              scale: _imageScaleAnimation,
              child: Stack(
                children: [
                  Container(
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
                ],
              ),
            ).animate(effects: [ScaleEffect(duration: 600.ms, curve: Curves.elasticOut), FadeEffect(duration: 800.ms)]),
          );
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
    bool showRetryButton = _result.contains('⚠️') || 
                          _result.contains('Ошибка') ||
                          _result.contains('ошибка') ||
                          _result.contains('таймаут') ||
                          _result.contains('интернет') ||
                          _result.contains('соединение');

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
                width: 250,
                height: 250,
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
                
                if (showRetryButton && _selectedImage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () async {
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
                            
                            if (!response.contains('⚠️') && !response.contains('Ошибка')) {
                              final lines = response.split('\n');
                              String? species;
                              String? condition;

                              for (var line in lines) {
                                if (line.startsWith('1. Вид:') || line.startsWith('🦜 Вид:')) {
                                  species = line
                                      .replaceAll('1. Вид:', '')
                                      .replaceAll('🦜 Вид:', '')
                                      .trim();
                                } else if (line.startsWith('3. Состояние:') || line.startsWith('❤️ Состояние:')) {
                                  condition = line
                                      .replaceAll('3. Состояние:', '')
                                      .replaceAll('❤️ Состояние:', '')
                                      .trim();
                                } else if (line.contains('На изображении нет птицы')) {
                                  species = 'Не птица';
                                }
                              }
                              
                              if (species == null && !response.contains('⚠️') && !response.contains('Ошибка')) {
                                species = 'Не птица';
                              }

                              if (species != null && species.isNotEmpty) {
                                final now = DateTime.now();
                                final newEntry = {
                                  'date': now,
                                  'species': species,
                                  'condition': condition ?? 'Не указано',
                                  'result': _result,
                                  'imagePath': savedImagePath,
                                };

                                _analysisHistory.add(newEntry);
                                _saveHistory();

                                widget.scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(
                                    content: Text('Повторный анализ сохранен в историю'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Повторный анализ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emergency_rounded, size: 24), SizedBox(width: 12), Text('Вызвать спасателей', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
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

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _result = '';
      _hasSelectedImage = false;
      _imageScaleController.repeat(reverse: true);
    });
  }

  // Методы для истории голосов
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

  // Методы для отображения диалогов истории
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
                                          _hasSelectedImage = _selectedImage != null;
                                          if (_hasSelectedImage) {
                                            _imageScaleController.stop();
                                          }
                                        });
                                      },
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Column(
                                        children: [
                                          GestureDetector(
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
                                          SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () => _shareAnalysisResult(item),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.share, size: 16, color: Colors.white),
                                            ),
                                          ),
                                        ],
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
                              height: 100,
                              child: Stack(
                                children: [
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
                                      padding: const EdgeInsets.only(left: 16, right: 80),
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
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Column(
                                      children: [
                                        GestureDetector(
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
                                        SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () => _shareVoiceAnalysisResult(item),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.share, size: 16, color: Colors.white),
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

  String _formatSpeciesText(String text) {
    final words = text.split(' ');
    return words.join('\n');
  }

  String _formatVoiceHistoryDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day-$month-$year\n$hour:$minute';
  }

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
      await _stopHistoryAudio();

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
      
      _currentPlayingPath = filePath;
      
      setDialogState(() {
        _isHistoryPlaying = true;
      });

      _historyPlayerController!.onPlayerStateChanged.listen((state) async {
        if (state == PlayerState.stopped && mounted) {
          _stopHistoryAudio();
          setDialogState(() {
            _isHistoryPlaying = false;
          });
        }
      });

    } catch (e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка воспроизведения: $e'), duration: const Duration(seconds: 3)),
      );
    }
  }

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

  void _removeFromVoiceHistory(int index) {
    setState(() {
      _voiceHistory.removeAt(index);
    });
    _saveVoiceHistory();
    widget.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Аудио-анализ удален'), duration: Duration(seconds: 2)),
    );
  }

  void _clearVoiceHistory() {
    setState(() {
      _voiceHistory.clear();
    });
    _saveVoiceHistory();
  }

  void _shareAnalysisResult(Map<String, dynamic> item) async {
    try {
      final String species = item['species'] ?? 'Неизвестный вид';
      final String result = item['result'] ?? '';
      final String? imagePath = item['imagePath'];
      
      String shareText = '''
$species

Результат анализа:
$result

📱 Сделано с помощью приложения "Перо жизни"
''';
      
      List<XFile> files = [];
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          files.add(XFile(file.path));
        }
      }
      
      await Share.shareXFiles(
        files,
        text: shareText,
        subject: 'Результат анализа: $species',
      );
    } catch (e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка при отправке: $e'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _shareVoiceAnalysisResult(Map<String, dynamic> item) async {
    try {
      final String species = item['species'] ?? 'Неизвестный вид';
      final String result = item['result'] ?? '';
      
      String shareText = '''
$species

Результат аудио-анализа:
$result

📱 Сделано с помощью приложения "Перо жизни"
''';
      
      await Share.share(
        shareText,
        subject: 'Результат аудио-анализа: $species',
      );
    } catch (e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка при отправке: $e'), duration: Duration(seconds: 2)),
      );
    }
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
}

// =============== НАСТРОЙКИ ===============
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
  // ignore: unused_field
  bool _isLoadingImage = true;
  late ImageProvider _kubguImage;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkMode;
    _savePhotos = widget.saveCameraPhotos;
    
    // Инициализируем изображение
    _kubguImage = const AssetImage('assets/icons/app_kubgu.jpg');
    
    // Предзагружаем изображение
    _precacheImage();
  }

  Future<void> _precacheImage() async {
    try {
      await precacheImage(_kubguImage, context);
      setState(() {
        _isLoadingImage = false;
      });
    } catch (e) {
      print('⚠️ Ошибка загрузки изображения КубГУ: $e');
      setState(() {
        _isLoadingImage = false;
      });
    }
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'ComicSans'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                _buildHelpSection('🎯 Краткая цель', '«Перо жизни» — это мобильное приложение, созданное для того, чтобы каждый мог помочь птицам. Приложение подходит как для любителей природы, так и для волонтёров и работников реабилитационных центров.', subTextColor),
                _buildHelpSection('📱 Как это работает — пошагово', '• Сделайте фотографию птицы с камеры или загрузите из галереи\n• Или запишите голос птицы для аудиоанализа через встроенный диктофон\n• Изображение или аудио обрабатывается нейросетью — определяется вид, особенности и признаки возможных травм или болезней\n• Вы получаете развернутую карточку с результатом: название вида (рус./англ.), ключевые признаки, оценка состояния и краткие рекомендации\n• Если птица нуждается в помощи, вы можете отправить запрос в реабилитационный центр прямо из приложения — с фотографией и геолокацией', subTextColor),
                _buildHelpSection('🔍 Что именно анализируется', '• Оперение: нарушение структуры, проплешины, нехарактерные пятна\n• Поведение/поза: заторможенность, повреждение лап/клюва, нестабильная поза\n• Наличие ран, кровотечения, следов удара, деформаций\n• Голос: особенности пения, виды птиц по аудиозаписи', subTextColor),
                _buildHelpSection('📤 Отправка запроса о помощи', 'При отправке запроса приложение предложит добавить комментарий и автоматически приложит координаты места. Перед отправкой потребуется разрешение на доступ к геолокации. Центр получит фото, описание и ссылку на карту — это ускорит помощь.', subTextColor),
                _buildHelpSection('📊 История и приватность', 'Все результаты анализов и отправленные запросы сохраняются локально на устройстве (история доступна в разделе «История анализов»). Данные не передаются третьим лицам без вашего запроса. Для отправки в центр используются только поля, которые вы подтверждаете: фото, комментарий и геолокация.', subTextColor),
                _buildHelpSection('🛡️ Фильтрация подделок', 'Приложение включает алгоритм, который помогает отличать реальные фотографии птиц от рисунков, скульптур или фотографий на экране. Это снижает ложные срабатывания и направляет ресурсы на реальные случаи помощи.', subTextColor),
                _buildHelpSection('💡 Советы для хорошего анализа', '• Сфотографируйте птицу крупно, в фокусе и при хорошем освещении\n• Сделайте несколько кадров с разных ракурсов, если возможно\n• Для аудиоанализа: запишите пение птицы в тихом месте без фоновых шумов\n• Не обесценивайте маленькую птицу — часто даже мелкие виды важны для экосистемы', subTextColor),
                _buildHelpSection('⚠️ Частые проблемы и решения', '• Если приложение не распознаёт вид — попробуйте другое фото с чётким ракурсом\n• Если аудиоанализ не работает — проверьте качество записи и отсутствие шумов\n• Если отправка запроса не проходит — проверьте интернет и разрешения геолокации\n• Если вы видите ложные детекции — напишите в Поддержку с примером', subTextColor),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Спасибо, что помогаете птицам — вместе мы сильнее! 🐦',
                    style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontFamily: 'ComicSans', fontStyle: FontStyle.italic),
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
          child: Text(
            title, 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: _isDark ? Colors.white : Colors.black,
              fontFamily: 'ComicSans',
            ), 
            textAlign: TextAlign.left
          ),
        ),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(color: textColor, height: 1.4, fontFamily: 'ComicSans')),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final accentColor = Colors.green.shade700;
    final accentColor1 = Colors.blue.shade700;
    final cardColor = isDark ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade50;
    
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final padding = screenWidth < 400 ? 16.0 : 24.0;
        final titleFontSize = screenWidth < 400 ? 20.0 : 24.0;
        final normalFontSize = screenWidth < 400 ? 13.0 : 14.0;
        
        return Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentColor.withOpacity(0.3), width: 2),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: EdgeInsets.all(padding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Заголовок - ЗЕЛЕНЫЙ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade800, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'О приложении',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'ComicSans',
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Изображение филиала КубГУ
                  FutureBuilder<ImageInfo>(
                    future: _getImageInfo(_kubguImage),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
                            color: cardColor,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                            ),
                          ),
                        );
                      }
                      
                      if (snapshot.hasError || snapshot.data == null) {
                        return Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
                            color: cardColor,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school,
                                size: 60,
                                color: accentColor,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'КубГУ в Геленджике',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontFamily: 'ComicSans',
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final imageInfo = snapshot.data!;
                      final imageWidth = imageInfo.image.width.toDouble();
                      final imageHeight = imageInfo.image.height.toDouble();
                      final aspectRatio = imageWidth / imageHeight;
                      
                      // Определяем максимальные размеры
                      final maxWidth = screenWidth * 0.85;
                      final maxHeight = 200.0;
                      
                      // Рассчитываем размеры с сохранением пропорций
                      double containerWidth;
                      double containerHeight;
                      
                      if (imageWidth > imageHeight) {
                        // Горизонтальное изображение
                        containerWidth = maxWidth;
                        containerHeight = containerWidth / aspectRatio;
                        if (containerHeight > maxHeight) {
                          containerHeight = maxHeight;
                          containerWidth = containerHeight * aspectRatio;
                        }
                      } else {
                        // Вертикальное изображение
                        containerHeight = maxHeight;
                        containerWidth = containerHeight * aspectRatio;
                        if (containerWidth > maxWidth) {
                          containerWidth = maxWidth;
                          containerHeight = containerWidth / aspectRatio;
                        }
                      }
                      
                      // Убедимся, что размеры не меньше минимальных
                      containerWidth = containerWidth.clamp(100.0, maxWidth);
                      containerHeight = containerHeight.clamp(100.0, maxHeight);
                      
                      return Container(
                        width: containerWidth,
                        height: containerHeight,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image(
                            image: _kubguImage,
                            width: containerWidth,
                            height: containerHeight,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: containerWidth,
                                height: containerHeight,
                                color: cardColor,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 60,
                                      color: accentColor,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'КубГУ в Геленджике',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                        fontFamily: 'ComicSans',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Название под изображением
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Разработано в филиале:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 18.0 : 20.0,
                            fontWeight: FontWeight.w600,
                            color: subTextColor.withOpacity(0.9),
                            fontFamily: 'ComicSans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"Кубанский Государственный Университет"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 15.0 : 17.0,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontFamily: 'ComicSans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'в г. Геленджике',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 13.0 : 15.0,
                            color: subTextColor,
                            fontFamily: 'ComicSans',
                            fontStyle: FontStyle.italic
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(КубГУ в г. Геленджике)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 12.0 : 14.0,
                            color: subTextColor.withOpacity(0.8),
                            fontFamily: 'ComicSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Описание
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school, color: accentColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'О филиале "Кубанский Государственный Университет" в г. Геленджике:',
                                style: TextStyle(
                                  fontSize: screenWidth < 400 ? 14.0 : 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'ComicSans',
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Филиал "Кубанский Государственный Университет" в г. Геленджике (КубГУ в г. Геленджике) — это современный филиал одного из ведущих вузов юга России, '
                          'который сочетает академические традиции и инновационные подходы к образованию. '
                          'Филиал готовит высококвалифицированных специалистов для наукоёмких отраслей экономики, '
                          'внедряет передовые образовательные технологии и активно развивает научно-исследовательскую деятельность.',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: normalFontSize,
                            fontFamily: 'ComicSans',
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Команда разработчиков - СИНИЕ цвета
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_alt, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'От студентов КубГУ:',
                              style: TextStyle(
                                fontSize: screenWidth < 400 ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontFamily: 'ComicSans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTeamMember('Кривошеенко Данил Дмитриевич', 'Автор идеи программы, студент КубГУ', screenWidth, accentColor1),
                        const SizedBox(height: 8),
                        _buildTeamMember('Панов Максим Романович', 'Разработчик UI/UX, студент КубГУ', screenWidth, accentColor1),
                        const SizedBox(height: 8),
                        _buildTeamMember('Полежаев Дмитрий Дмитриевич', 'Ведущий разработчик, студент КубГУ', screenWidth, accentColor1),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Руководитель - ФИОЛЕТОВЫЕ цвета
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.supervised_user_circle, color: Colors.purple.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Руководитель проекта:',
                              style: TextStyle(
                                fontSize: screenWidth < 400 ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                                fontFamily: 'ComicSans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.person, color: Colors.purple.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Кривошеенко Татьяна Петровна',
                                    style: TextStyle(
                                      fontSize: screenWidth < 400 ? 13.0 : 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                      fontFamily: 'ComicSans',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Преподаватель Кубанского Государственного Университета в г. Геленджике, научный руководитель проекта',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: screenWidth < 400 ? 11.0 : 13.0,
                                      fontFamily: 'ComicSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Контакты - ОРАНЖЕВЫЕ цвета
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.mail, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Контакты:',
                              style: TextStyle(
                                fontSize: screenWidth < 400 ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontFamily: 'ComicSans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, color: Colors.orange.shade600, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                'perozhizni@gmail.com',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: screenWidth < 400 ? 13.0 : 15.0,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'ComicSans',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Официальная почта для связи по вопросам приложения',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: screenWidth < 400 ? 11.0 : 13.0,
                            fontFamily: 'ComicSans',
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Кнопка закрытия - ЗЕЛЕНАЯ
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade600, Colors.green.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Закрыть',
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 14.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ComicSans',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate(
          effects: [
            ScaleEffect(
              duration: 500.ms,
              curve: Curves.elasticOut,
              begin: Offset(0.8, 0.8),
              end: Offset(1.0, 1.0),
            ),
            FadeEffect(duration: 400.ms),
          ],
        );
      },
    );
  }

  Future<ImageInfo> _getImageInfo(ImageProvider imageProvider) async {
    final completer = Completer<ImageInfo>();
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      if (!completer.isCompleted) {
        completer.complete(info);
      }
    });
    
    imageStream.addListener(listener);
    
    // Таймаут на случай, если изображение не загрузится
    Future.delayed(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Image loading timeout'));
      }
    });
    
    try {
      return await completer.future;
    } finally {
      imageStream.removeListener(listener);
    }
  }

  // Вспомогательный метод для отображения члена команды
  Widget _buildTeamMember(String name, String role, double screenWidth, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_outline, size: 18, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: screenWidth < 400 ? 13.0 : 15.0,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: 'ComicSans',
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: screenWidth < 400 ? 11.0 : 13.0,
                  fontFamily: 'ComicSans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isDark ? Colors.white : Colors.black;
    final subTextColor = _isDark ? Colors.white70 : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ComicSans')),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6, color: subTextColor),
              title: Text('Тема', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'ComicSans')),
              subtitle: Text(_isDark ? 'Тёмная' : 'Светлая', style: TextStyle(color: subTextColor, fontFamily: 'ComicSans')),
              trailing: Switch(value: _isDark, onChanged: _onThemeChanged, activeColor: Colors.blue), // СИНИЙ
            ),
            CheckboxListTile(
              value: _savePhotos,
              onChanged: (value) => _onSavePhotosChanged(value!),
              title: Text('Сохранять фотографии, сделанные через камеру', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'ComicSans')),
              secondary: Icon(Icons.camera_alt, color: subTextColor),
            ),
            const SizedBox(height: 20),
            
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDark 
                        ? [Colors.blue.shade800, Colors.blue.shade600] // СИНИЙ
                        : [Colors.blue.shade700, Colors.blue.shade500], // СИНИЙ
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(_isDark ? 0.4 : 0.3), // СИНИЙ
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 140),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.support_agent, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        "Поддержка", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'ComicSans'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Center(
              child: FittedBox(
                child: ElevatedButton.icon(
                  onPressed: () => _showHelpDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // СИНИЙ
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  icon: const Icon(Icons.article_outlined, size: 30),
                  label: const Text('Подробная справка по приложению', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'ComicSans')),
                ),
              ),
            ),
            const Spacer(),
            
            // Кнопка "О нас" - ЗЕЛЕНАЯ
            Center(
              child: GestureDetector(
                onTap: () => _showAboutDialog(context),
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDark 
                          ? [Colors.green.shade800, Colors.green.shade600] // ЗЕЛЕНЫЙ
                          : [Colors.green.shade700, Colors.green.shade500], // ЗЕЛЕНЫЙ
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(_isDark ? 0.5 : 0.4), // ЗЕЛЕНЫЙ
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'О нас',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ComicSans',
                        shadows: [
                          Shadow(
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate(
                  effects: [
                    ScaleEffect(
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                      begin: Offset(0.9, 0.9),
                      end: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Версия приложения
            Text(
              'Версия приложения: 2.8.0', 
              style: TextStyle(
                color: subTextColor, 
                fontSize: 14, 
                fontFamily: 'ComicSans',
                fontStyle: FontStyle.italic
              )
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// =============== ВСПОМОГАТЕЛЬНЫЕ ЭКРАНЫ ===============
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
        maxAssets: remaining,
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

            TextField(
              controller: _messageController,
              maxLines: 4,
              cursorColor: Colors.blue,
              textAlign: TextAlign.start,
              decoration: InputDecoration(
                hintText: isEmpty ? "Ваше сообщение" : null,
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.blue[300]!.withOpacity(0.6) : Colors.blue.withOpacity(0.6),
                  fontSize: 16,
                ),
                labelText: isEmpty ? null : "Ваше сообщение",
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.blue[300] : Colors.blue,
                  fontSize: 16,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                floatingLabelAlignment: FloatingLabelAlignment.center,
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
                      Navigator.pop(context);
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

                      _buildControlButtons(blue),

                      const SizedBox(height: 20),
                      _formatInfo(blue),
                      const SizedBox(height: 20),

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
    final duration = _waveController.length;
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