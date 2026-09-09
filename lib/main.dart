import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// 1. المتغير العالمي للتحكم في الوضع الليلي (يحل مشكلة عدم استجابة الزر)
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تحميل إعدادات الوضع الليلي عند بدء التطبيق
  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('is_dark_mode') ?? false;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. استخدام ValueListenableBuilder لتغيير الثيم فوراً دون إعادة تشغيل
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'مواقيت الصلاة - المغرب',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00695C),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const PrayerTimesScreen(),
        );
      },
    );
  }
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final List<Map<String, String>> allCities = [
    {'name': 'Rabat', 'ar': 'الرباط'}, {'name': 'Casablanca', 'ar': 'الدار البيضاء'},
    {'name': 'Fes', 'ar': 'فاس'}, {'name': 'Marrakech', 'ar': 'مراكش'},
    {'name': 'Tangier', 'ar': 'طنجة'}, {'name': 'Agadir', 'ar': 'أكادير'},
    {'name': 'Oujda', 'ar': 'وجدة'}, {'name': 'Meknes', 'ar': 'مكناس'},
    {'name': 'Laayoune', 'ar': 'العيون'}, {'name': 'Dakhla', 'ar': 'الداخلة'},
    {'name': 'Tetouan', 'ar': 'تطوان'}, {'name': 'Kenitra', 'ar': 'القنيطرة'},
    {'name': 'Nador', 'ar': 'الناظور'}, {'name': 'Beni Mellal', 'ar': 'بني ملال'},
    {'name': 'El Jadida', 'ar': 'الجديدة'}, {'name': 'Khouribga', 'ar': 'خريبكة'},
    {'name': 'Safi', 'ar': 'آسفي'}, {'name': 'Khemisset', 'ar': 'الخميسات'},
    {'name': 'Taza', 'ar': 'تازة'}, {'name': 'Settat', 'ar': 'سطات'},
    {'name': 'Larache', 'ar': 'العرائش'}, {'name': 'Guelmim', 'ar': 'كلميم'},
    {'name': 'Berrechid', 'ar': 'برشيد'}, {'name': 'Ksar El Kebir', 'ar': 'القصر الكبير'},
    {'name': 'Taourirt', 'ar': 'تاوريرت'}, {'name': 'Errachidia', 'ar': 'الرشيدية'},
    {'name': 'Ouarzazate', 'ar': 'ورزازات'}, {'name': 'Taroudant', 'ar': 'تارودانت'},
    {'name': 'Tiznit', 'ar': 'تزنيت'}, {'name': 'Essaouira', 'ar': 'الصويرة'},
    {'name': 'Al Hoceima', 'ar': 'الحسيمة'}, {'name': 'Sidi Kacem', 'ar': 'سيدي قاسم'},
    {'name': 'Sidi Slimane', 'ar': 'سيدي سليمان'}, {'name': 'Mohammedia', 'ar': 'المحمدية'},
    {'name': 'Khenifra', 'ar': 'خنيفرة'}, {'name': 'Azrou', 'ar': 'آزرو'},
    {'name': 'Ifrane', 'ar': 'إفران'}, {'name': 'Midelt', 'ar': 'ميدلت'},
    {'name': 'Zagora', 'ar': 'زاكورة'}, {'name': 'Tan-Tan', 'ar': 'طانطان'},
    {'name': 'Sidi Ifni', 'ar': 'سيدي إفني'}, {'name': 'Tinghir', 'ar': 'تنغير'},
    {'name': 'Tarfaya', 'ar': 'طرفاية'}, {'name': 'Smara', 'ar': 'السمارة'},
    {'name': 'Boujdour', 'ar': 'بوجدور'}, {'name': 'Chefchaouen', 'ar': 'شفشاون'},
    {'name': 'Asilah', 'ar': 'أصيلة'}, {'name': 'Martil', 'ar': 'مرتيل'},
    {'name': 'Fnideq', 'ar': 'الفنيدق'}, {'name': 'Ouezzane', 'ar': 'وزان'},
    {'name': 'Sefrou', 'ar': 'صفرو'}, {'name': 'Berkane', 'ar': 'بركان'},
    {'name': 'Figuig', 'ar': 'فكيك'}, {'name': 'Jerada', 'ar': 'جرادة'},
    {'name': 'Boulemane', 'ar': 'بولمان'}, {'name': 'Hajeb', 'ar': 'الحاجب'},
    {'name': 'Tata', 'ar': 'طاطا'}, {'name': 'Aousserd', 'ar': 'أوسرد'},
  ];

  String selectedCity = 'Rabat';
  String selectedCityArabic = 'الرباط';
  Map<String, String> timings = {};
  String hijriDate = '';
  String gregorianDate = '';
  bool isLoading = true;
  String errorMessage = '';
  String nextPrayer = '';
  String nextPrayerTime = '';
  String timeRemaining = '00:00:00';
  Timer? countdownTimer;
  DateTime? _nextPrayerDateTime; // متغير داخلي لحساب الوقت بدقة

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCity = prefs.getString('selected_city') ?? 'Rabat';
      selectedCityArabic = prefs.getString('selected_city_arabic') ?? 'الرباط';
    });
    await fetchPrayerTimes();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_city', selectedCity);
    await prefs.setString('selected_city_arabic', selectedCityArabic);
  }

  // 3. منطق الجلب مع دعم العمل بدون إنترنت (Offline Mode)
  Future<void> fetchPrayerTimes() async {
    setState(() { isLoading = true; errorMessage = ''; });

    try {
      final url = Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=$selectedCity&country=Morocco&method=21');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['code'] == 200 && jsonResponse['data'] != null) {
          // حفظ البيانات في الذاكرة المحلية للعمل بدون نت
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cache_$selectedCity', response.body);
          
          _processData(response.body);
        } else {
          _loadFromCache();
        }
      } else {
        _loadFromCache();
      }
    } catch (e) {
      _loadFromCache();
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cache_$selectedCity');
    if (cached != null) {
      _processData(cached, isOffline: true);
    } else {
      setState(() { 
        errorMessage = 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة مسبقاً لهذه المدينة.'; 
        isLoading = false; 
      });
    }
  }

  void _processData(String jsonString, {bool isOffline = false}) {
    final jsonResponse = jsonDecode(jsonString);
    final data = jsonResponse['data'];
    final times = data['timings'];
    final hijri = data['date']['hijri'];
    final gregorian = data['date']['gregorian'];

    setState(() {
      timings = {
        'الفجر': times['Fajr'] ?? '--:--',
        'الشروق': times['Sunrise'] ?? '--:--',
        'الظهر': times['Dhuhr'] ?? '--:--',
        'العصر': times['Asr'] ?? '--:--',
        'المغرب': times['Maghrib'] ?? '--:--',
        'العشاء': times['Isha'] ?? '--:--',
      };
      hijriDate = '${hijri['weekday']['ar']} ${hijri['day']} ${hijri['month']['ar']} ${hijri['year']}';
      gregorianDate = '${gregorian['weekday']['en']} ${gregorian['day']} ${gregorian['month']['en']} ${gregorian['year']}';
      isLoading = false;
      if (isOffline) errorMessage = 'أنت بدون إنترنت. يتم عرض آخر مواقيت محفوظة.';
    });

    _calculateNextPrayer();
    _saveSettings();
  }

  // 4. الخوارزمية الذكية لحساب الصلاة القادمة (تتعامل مع منتصف الليل وتغيير اليوم)
  void _calculateNextPrayer() {
    final now = DateTime.now();
    final prayerOrder = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    
    DateTime? nextPrayerDateTime;
    String? nextPrayerName;

    for (var prayer in prayerOrder) {
      if (timings.containsKey(prayer)) {
        final parts = timings[prayer]!.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        DateTime prayerTimeToday = DateTime(now.year, now.month, now.day, hour, minute);
        
        if (prayerTimeToday.isAfter(now)) {
          nextPrayerDateTime = prayerTimeToday;
          nextPrayerName = prayer;
          break;
        }
      }
    }

    // إذا انتهت صلوات اليوم، الصلاة القادمة هي فجر الغد
    if (nextPrayerDateTime == null) {
      final fajrParts = timings['الفجر']!.split(':');
      int hour = int.parse(fajrParts[0]);
      int minute = int.parse(fajrParts[1]);
      nextPrayerDateTime = DateTime(now.year, now.month, now.day + 1, hour, minute);
      nextPrayerName = 'الفجر';
    }

    setState(() {
      this.nextPrayer = nextPrayerName!;
      this.nextPrayerTime = timings[nextPrayerName]!;
      this._nextPrayerDateTime = nextPrayerDateTime!;
    });
    
    _startCountdown();
  }

  void _startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_nextPrayerDateTime!.isBefore(now) || _nextPrayerDateTime!.isAtSameMomentAs(now)) {
        timer.cancel();
        setState(() {
          timeRemaining = "00:00:00";
          nextPrayer = "حان الوقت";
        });
        return;
      }

      final difference = _nextPrayerDateTime!.difference(now);
      setState(() {
        timeRemaining = '${difference.inHours.toString().padLeft(2, '0')}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 5. الشريط الجانبي الاحترافي
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00695C)))
          : errorMessage.isNotEmpty && timings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: fetchPrayerTimes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), foregroundColor: Colors.white),
                        )
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchPrayerTimes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (errorMessage.isNotEmpty && timings.isNotEmpty) 
                            Container(padding: const EdgeInsets.all(8), color: Colors.orange.withOpacity(0.2), child: Text(errorMessage, style: const TextStyle(color: Colors.orange))),
                          _buildNextPrayerCard(),
                          const SizedBox(height: 16),
                          _buildCitySelector(),
                          const SizedBox(height: 16),
                          _buildDateCard(),
                          const SizedBox(height: 16),
                          _buildPrayerTimesList(),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text('حسب توقيت وزارة الأوقاف والشؤون الإسلامية', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF00695C)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.mosque, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(selectedCityArabic, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(hijriDate, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF00695C)),
            title: const Text('الرئيسية'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.sort, color: Color(0xFF00695C)),
            title: const Text('المسبحة الإلكترونية'),
            subtitle: const Text('عداد التسبيح والذكر', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _showTasbeehDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: Color(0xFF00695C)),
            title: const Text('الأذكار'),
            subtitle: const Text('أذكار الصباح والمساء', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _showAdhkarDialog();
            },
          ),
          const Divider(),
          ValueListenableBuilder<bool>(
            valueListenable: isDarkModeNotifier,
            builder: (context, isDark, child) {
              return SwitchListTile(
                secondary: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: const Color(0xFF00695C)),
                title: const Text('الوضع الليلي'),
                value: isDark,
                onChanged: (value) async {
                  isDarkModeNotifier.value = value;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_dark_mode', value);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF00695C)),
            title: const Text('حول التطبيق'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'مواقيت الصلاة - المغرب',
                applicationVersion: '3.0.0',
                children: [
                  const Text('تطبيق شامل لعرض مواقيت الصلاة حسب مدن المملكة المغربية.'),
                  const SizedBox(height: 8),
                  const Text('المصدر: وزارة الأوقاف والشؤون الإسلامية المغربية (طريقة الحساب 21).'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 6. ميزة المسبحة الإلكترونية (بدون أي أذونات خارجية)
  void _showTasbeehDialog() {
    int count = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('المسبحة الإلكترونية', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$count', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => count++);
                      HapticFeedback.lightImpact(); // اهتزاز خفيف مدمج في Flutter
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(24),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.touch_app, size: 48),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => count = 0),
                    child: const Text('تصفير العداد', style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
            );
          },
        );
      },
    );
  }

  // 7. ميزة الأذكار
  void _showAdhkarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('من الأذكار', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('• سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ.', style: TextStyle(fontSize: 18, height: 1.5)),
                SizedBox(height: 16),
                Text('• لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.', style: TextStyle(fontSize: 18, height: 1.5)),
                SizedBox(height: 16),
                Text('• اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ.', style: TextStyle(fontSize: 18, height: 1.5)),
                SizedBox(height: 16),
                Text('• أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ، الْحَيُّ الْقَيُّومُ، وَأَتُوبُ إِلَيْهِ.', style: TextStyle(fontSize: 18, height: 1.5)),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
        );
      },
    );
  }

  Widget _buildNextPrayerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00897B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF00695C).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('الصلاة القادمة', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(nextPrayer, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(nextPrayerTime, style: const TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(timeRemaining, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر المدينة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              items: allCities.map((city) {
                return DropdownMenuItem<String>(value: city['name'], child: Text(city['ar']!, style: const TextStyle(fontSize: 16)));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  final city = allCities.firstWhere((c) => c['name'] == newValue);
                  setState(() { selectedCity = newValue; selectedCityArabic = city['ar']!; });
                  fetchPrayerTimes();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: Column(children: [const Icon(Icons.calendar_today, color: Color(0xFF00695C), size: 32), const SizedBox(height: 8), const Text('التاريخ الهجري', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text(hijriDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])),
            Container(width: 1, height: 50, color: Colors.grey.shade300),
            Expanded(child: Column(children: [const Icon(Icons.calendar_month, color: Color(0xFF00695C), size: 32), const SizedBox(height: 8), const Text('التاريخ الميلادي', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text(gregorianDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center)])),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مواقيت الصلاة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...timings.entries.map((entry) => _buildPrayerCard(entry.key, entry.value)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(String name, String time) {
    IconData icon;
    Color color;
    switch (name) {
      case 'الفجر': icon = Icons.nightlight_round; color = Colors.indigo; break;
      case 'الشروق': icon = Icons.wb_sunny; color = Colors.orange; break;
      case 'الظهر': icon = Icons.sunny; color = Colors.amber; break;
      case 'العصر': icon = Icons.wb_cloudy; color = Colors.cyan; break;
      case 'المغرب': icon = Icons.nights_stay; color = Colors.deepOrange; break;
      case 'العشاء': icon = Icons.nightlight; color = Colors.deepPurple; break;
      default: icon = Icons.access_time; color = Colors.grey;
    }

    final isNextPrayer = name == nextPrayer && timeRemaining != "00:00:00";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNextPrayer ? color.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
        border: isNextPrayer ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: TextStyle(fontSize: 18, fontWeight: isNextPrayer ? FontWeight.bold : FontWeight.normal))),
          Text(time, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isNextPrayer ? color : null)),
        ],
      ),
    );
  }
}
