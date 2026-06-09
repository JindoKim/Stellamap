import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

// ==========================================
// 🌐 전역 상태 관리
// ==========================================
String? globalToken;
String? globalUsername;
// 💡 API 경로를 localhost로 변경했습니다.
const String baseUrl = 'http://localhost:8080/api/v1';

final ValueNotifier<int> globalThemeIndex = ValueNotifier(0);

// ==========================================
// 🎨 감성 UI 페이드 라우트
// ==========================================
class FadePageRoute extends PageRouteBuilder {
  final Widget page;
  FadePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      );
}

// ==========================================
// 📱 메인 앱 테마 설정
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stellamap',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: const Color(0xFFE0E0E0),
        textTheme: GoogleFonts.nanumMyeongjoTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white70),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        dividerColor: Colors.white10,
      ),
      builder: (context, child) => NightSkyBackground(child: child!),
      home: const SplashScreen(),
    );
  }
}

Future<void> performLogout(BuildContext context) async {
  if (globalToken != null) {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
    } catch (_) {}
  }
  globalToken = null;
  globalUsername = null;
  globalThemeIndex.value = 0;
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    FadePageRoute(page: const AuthScreen()),
    (route) => false,
  );
}

// ==========================================
// ✨ 밤하늘 배경 (🌟 부드러운 보라 및 확연한 전환 색상 적용)
// ==========================================
class NightSkyBackground extends StatefulWidget {
  final Widget child;
  const NightSkyBackground({super.key, required this.child});
  @override
  State<NightSkyBackground> createState() => _NightSkyBackgroundState();
}

class Star {
  double x, y, speed, size, opacity;
  Star({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _NightSkyBackgroundState extends State<NightSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _starCtrl;
  final List<Star> _stars = [];

  // 🌟 화면 전환 시 확연하게 눈에 띄는 감성적인 컬러 팔레트 구성
  final List<List<Color>> _themeColors = const [
    // 1. Star Map: 부드럽고 차분한 보라 (Soft Violet)
    [Color(0xFF4B385D), Color(0xFF281C35), Color(0xFF100918)],
    // 2. Diaries: 자정의 깊은 푸른 보라 (Midnight Blue-Purple)
    [Color(0xFF334366), Color(0xFF1B253D), Color(0xFF0A0F1A)],
    // 3. Profile: 우아한 딥 로즈 퍼플 (Dusky Rose Purple)
    [Color(0xFF5A3C4D), Color(0xFF301E28), Color(0xFF150A11)],
    // 4. Melody: 신비로운 오로라 인디고 (Mystic Indigo)
    [Color(0xFF313B5E), Color(0xFF181E33), Color(0xFF090D1A)],
    // 5. Calendar: 짙은 황혼의 딥 퍼플 (Deep Twilight Purple)
    [Color(0xFF452C54), Color(0xFF24152E), Color(0xFF0E0714)],
  ];

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stars.isEmpty) {
      final size = MediaQuery.of(context).size;
      final rand = math.Random();
      for (int i = 0; i < 50; i++) {
        _stars.add(
          Star(
            x: rand.nextDouble() * size.width,
            y: rand.nextDouble() * size.height,
            speed: 0.1 + rand.nextDouble() * 0.4,
            size: 0.5 + rand.nextDouble() * 1.5,
            opacity: 0.2 + rand.nextDouble() * 0.6,
          ),
        );
      }
      _starCtrl.addListener(() {
        for (var star in _stars) {
          star.y += star.speed;
          star.x -= star.speed * 0.2;
          if (star.y > size.height) {
            star.y = 0;
            star.x = rand.nextDouble() * size.width;
          }
          if (star.x < 0) {
            star.x = size.width;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: globalThemeIndex,
      builder: (context, themeIndex, child) {
        return AnimatedContainer(
          duration: const Duration(
            milliseconds: 700,
          ), // 색상이 부드럽지만 확실하게 스며들며 변합니다.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _themeColors[themeIndex],
            ),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _starCtrl,
                builder: (context, _) => CustomPaint(
                  painter: StarPainter(_stars),
                  size: Size.infinite,
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  StarPainter(this.stars);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var star in stars) {
      paint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 0. 💎 스플래시 화면
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pathAnim;
  late Animation<double> _textAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pathAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _textAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted)
          Navigator.pushReplacement(
            context,
            FadePageRoute(page: const AuthScreen()),
          );
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pathAnim,
              builder: (context, child) => CustomPaint(
                size: const Size(70, 70),
                painter: DiamondPainter(_pathAnim.value),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _textAnim,
              child: const Text(
                '우리의 작은 피그먼트',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiamondPainter extends CustomPainter {
  final double progress;
  DiamondPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    final metrics = path.computeMetrics();
    final extractPath = Path();
    for (var metric in metrics)
      extractPath.addPath(
        metric.extractPath(0.0, metric.length * progress),
        Offset.zero,
      );
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 1. 로그인 화면
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  double _opacity = 0.0;
  double _scale = 0.90;
  double _translateY = 40.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
        _translateY = 0.0;
      });
    });
  }

  Future<void> _submit() async {
    final url = Uri.parse('$baseUrl/auth/${isLoginMode ? 'login' : 'signup'}');
    final body = isLoginMode
        ? {'username': _usernameCtrl.text, 'password': _passwordCtrl.text}
        : {
            'username': _usernameCtrl.text,
            'name': _nameCtrl.text,
            'nickname': _nicknameCtrl.text,
            'email': _emailCtrl.text,
            'password': _passwordCtrl.text,
          };
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isLoginMode) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          globalToken = data['data']['accessToken'];
          globalUsername = _usernameCtrl.text;
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            FadePageRoute(page: const MainDashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '가입이 완료되었습니다. 로그인해주세요.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
          setState(() => isLoginMode = true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '오류: ${jsonDecode(utf8.decode(response.bodyBytes))['message']}',
            ),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          opacity: _opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _translateY, 0)
              ..scale(_scale),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stellamap.',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                      height: 1.2,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildInput(_usernameCtrl, '아이디'),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: isLoginMode ? 0 : 210,
                    curve: Curves.easeInOut,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildInput(_nameCtrl, '이름'),
                          const SizedBox(height: 20),
                          _buildInput(_nicknameCtrl, '닉네임'),
                          const SizedBox(height: 20),
                          _buildInput(_emailCtrl, '이메일'),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  _buildInput(_passwordCtrl, '비밀번호', isObscure: true),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        isLoginMode ? '로그인' : '회원가입',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => isLoginMode = !isLoginMode),
                      child: Text(
                        isLoginMode ? '처음이신가요? 가입하기' : '이미 계정이 있습니다',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white30,
          fontWeight: FontWeight.w300,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 메인 대시보드
// ==========================================
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});
  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  late PageController _pageCtrl;
  final int _initialPage = 5000;
  double _pageOffset = 5000.0;

  final List<String> _titles = [
    'Starry Map',
    'Night Diaries',
    'My Profile',
    'Melodies',
    'Calendar',
  ];
  final List<IconData> _navIcons = [
    Icons.auto_awesome,
    Icons.menu_book_outlined,
    Icons.person_outline,
    Icons.headphones_outlined,
    Icons.calendar_month_outlined,
  ];
  final List<String> _navLabels = [
    'Map',
    'Diaries',
    'Profile',
    'Melody',
    'Calendar',
  ];

  final List<Widget> _pages = const [
    StarMapTab(),
    DiariesTab(),
    ProfileTab(),
    DummyMusicTab(),
    CalendarTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: _initialPage);
    _pageCtrl.addListener(() {
      setState(() => _pageOffset = _pageCtrl.page ?? _initialPage.toDouble());
      int currentRealIndex = _pageOffset.round() % 5;
      if (globalThemeIndex.value != currentRealIndex)
        globalThemeIndex.value = currentRealIndex;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int currentRealIndex = _pageOffset.round() % 5;

    return Scaffold(
      appBar: AppBar(title: Text(_titles[currentRealIndex])),
      body: PageView.builder(
        controller: _pageCtrl,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          int realIndex = index % 5;
          double rawDiff = index - _pageOffset;
          double opacity = (1 - rawDiff.abs()).clamp(0.0, 1.0);
          double slideAmount =
              (-rawDiff * MediaQuery.of(context).size.width) + (rawDiff * 80);

          return Transform.translate(
            offset: Offset(slideAmount, 0),
            child: Opacity(opacity: opacity, child: _pages[realIndex]),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: List.generate(5, (i) {
              double wrappedOffset = _pageOffset % 5.0;
              double diff = i - wrappedOffset;
              if (diff > 2.5) diff -= 5.0;
              if (diff < -2.5) diff += 5.0;

              double angle = diff * 0.45;
              double radius = 160.0;
              double xPos = radius * math.sin(angle);
              double yPos = radius - radius * math.cos(angle);

              double scale = 1.0 - (diff.abs() * 0.15).clamp(0.0, 0.4);
              double opacity = 1.0 - (diff.abs() * 0.4).clamp(0.0, 0.8);

              return Transform.translate(
                offset: Offset(xPos, yPos + 15),
                child: Transform.rotate(
                  angle: angle * 0.8,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          int currentPage = _pageOffset.round();
                          int currentReal = currentPage % 5;
                          int targetDiff = i - currentReal;
                          if (targetDiff > 2) targetDiff -= 5;
                          if (targetDiff < -2) targetDiff += 5;
                          _pageCtrl.animateToPage(
                            currentPage + targetDiff,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_navIcons[i], color: Colors.white, size: 28),
                            const SizedBox(height: 6),
                            Opacity(
                              opacity: (1 - (diff.abs() * 2)).clamp(0.0, 1.0),
                              child: Text(
                                _navLabels[i],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. 캔버스 별자리 지도 (Star Map Tab)
// ==========================================
class StarMapTab extends StatefulWidget {
  const StarMapTab({super.key});
  @override
  State<StarMapTab> createState() => _StarMapTabState();
}

class _StarMapTabState extends State<StarMapTab> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _stars = [];
  final math.Random _rnd = math.Random();

  final TransformationController _transCtrl = TransformationController();
  late AnimationController _cameraAnimCtrl;
  Animation<Matrix4>? _cameraAnim;

  @override
  void initState() {
    super.initState();
    _cameraAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cameraAnimCtrl.addListener(() {
      if (_cameraAnim != null) _transCtrl.value = _cameraAnim!.value;
    });
    _fetchStars();
  }

  @override
  void dispose() {
    _cameraAnimCtrl.dispose();
    _transCtrl.dispose();
    super.dispose();
  }

  void _focusOnStars() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      double targetX = 1000.0, targetY = 1000.0;
      if (_stars.isNotEmpty) {
        double sumX = 0, sumY = 0;
        for (var star in _stars) {
          sumX += star['x'];
          sumY += star['y'];
        }
        targetX = sumX / _stars.length;
        targetY = sumY / _stars.length;
      }
      final x = targetX - (size.width / 2);
      final y = targetY - (size.height / 2);
      final targetMatrix = Matrix4.identity()..translate(-x, -y);

      _cameraAnim = Matrix4Tween(begin: _transCtrl.value, end: targetMatrix)
          .animate(
            CurvedAnimation(
              parent: _cameraAnimCtrl,
              curve: Curves.easeInOutCubic,
            ),
          );
      _cameraAnimCtrl.forward(from: 0.0);
    });
  }

  Future<void> _fetchStars() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stars'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        List<Map<String, dynamic>> parsedStars = [];
        for (var s in (data['data'] ?? [])) {
          parsedStars.add({
            ...s,
            'x': _rnd.nextDouble() * 1500 + 250,
            'y': _rnd.nextDouble() * 1500 + 250,
          });
        }
        setState(() => _stars = parsedStars);
        _focusOnStars();
      }
    } catch (e) {}
  }

  void _showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: NoteWriteSheet(onSaved: _fetchStars),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transCtrl,
            boundaryMargin: const EdgeInsets.all(2000),
            minScale: 0.1,
            maxScale: 4.0,
            child: SizedBox(
              width: 2000,
              height: 2000,
              child: CustomPaint(
                key: ValueKey(_stars.length),
                painter: EmotionMapPainter(stars: _stars),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white54),
              onPressed: _focusOnStars,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: _showAddNoteSheet,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class EmotionMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> stars;
  EmotionMapPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = const Color(0xFFB39DDB).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

    for (var star in stars) {
      double x = star['x'];
      double y = star['y'];
      canvas.drawCircle(Offset(x, y), 16.0, glowPaint);
      canvas.drawCircle(Offset(x, y), 3.5, paint);

      final textSpan = TextSpan(
        text: star['text'],
        style: GoogleFonts.nanumMyeongjo(
          color: Colors.white70,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + 12, y - 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NoteWriteSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const NoteWriteSheet({super.key, required this.onSaved});
  @override
  State<NoteWriteSheet> createState() => _NoteWriteSheetState();
}

class _NoteWriteSheetState extends State<NoteWriteSheet> {
  final _ctrl = TextEditingController();
  Future<void> _submit() async {
    if (_ctrl.text.isEmpty) return;
    final res = await http.post(
      Uri.parse('$baseUrl/stars'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $globalToken',
      },
      body: jsonEncode({'text': _ctrl.text}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '우주에 띄울 조각',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _submit,
              ),
            ],
          ),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 5,
            maxLength: 255,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w300,
            ),
            decoration: const InputDecoration(
              hintText: '당신의 밤을 기록하세요.',
              hintStyle: TextStyle(color: Colors.white30),
              border: InputBorder.none,
              counterStyle: TextStyle(color: Colors.white30),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. 긴 글 (Diaries) 탭
// ==========================================
class DiariesTab extends StatefulWidget {
  const DiariesTab({super.key});
  @override
  State<DiariesTab> createState() => _DiariesTabState();
}

class _DiariesTabState extends State<DiariesTab> {
  List<dynamic> _diaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiaries();
  }

  Future<void> _fetchDiaries() async {
    final res = await http.get(
      Uri.parse('$baseUrl/diaries'),
      headers: {'Authorization': 'Bearer $globalToken'},
    );
    if (res.statusCode == 200 && mounted) {
      setState(() {
        _diaries = jsonDecode(utf8.decode(res.bodyBytes))['data'] ?? [];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _diaries.isEmpty
          ? const Center(
              child: Text(
                "밤을 채울 첫 일기를 작성해보세요.",
                style: TextStyle(color: Colors.white30),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final diary = _diaries[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      FadePageRoute(
                        page: DiaryDetailScreen(diaryId: diary['id']),
                      ),
                    );
                    _fetchDiaries();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diary['createdAt']
                                  ?.toString()
                                  .substring(0, 10)
                                  .replaceAll('-', '. ') ??
                              '',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 11,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Hero(
                          tag: 'diary_title_${diary['id']}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              diary['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          diary['content'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () async {
          final res = await Navigator.push(
            context,
            FadePageRoute(page: const DiaryWriteScreen()),
          );
          if (res == true) _fetchDiaries();
        },
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

// ==========================================
// 5. 프로필 탭
// ==========================================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Text(
              globalUsername ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Sign Out',
                style: TextStyle(letterSpacing: 1.5),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF281C35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      '로그아웃',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      '우주 탐색을 종료하시겠습니까?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          '취소',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          performLogout(context);
                        },
                        child: const Text(
                          '로그아웃',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. 더미 탭 (Melody, Calendar)
// ==========================================
class DummyMusicTab extends StatelessWidget {
  const DummyMusicTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          "Melody Player\n(Coming Soon)",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white30,
            fontSize: 16,
            height: 1.5,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    int firstDayWeekday = DateTime(now.year, now.month, 1).weekday;
    int offset = firstDayWeekday == 7 ? 0 : firstDayWeekday;
    List<int> attendedDays = [1, 3, 4, 8, 12, 15, 16, 21, now.day];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${now.year}. ${now.month.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Text(
                      d,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                if (index < offset || index >= offset + daysInMonth)
                  return const SizedBox();
                int day = index - offset + 1;
                bool isAttended = attendedDays.contains(day);
                bool isToday = day == now.day;
                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? Colors.white24 : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: isAttended
                        ? const Icon(
                            Icons.star,
                            color: Color(0xFFF3E5F5),
                            size: 18,
                          )
                        : Text(
                            '$day',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. 일기 상세 화면 및 작성 화면
// ==========================================
class DiaryDetailScreen extends StatefulWidget {
  final int diaryId;
  const DiaryDetailScreen({super.key, required this.diaryId});
  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  Map<String, dynamic>? _diary;
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final res = await http.get(
      Uri.parse('$baseUrl/diaries/${widget.diaryId}'),
      headers: {'Authorization': 'Bearer $globalToken'},
    );
    if (res.statusCode == 200)
      setState(() => _diary = jsonDecode(utf8.decode(res.bodyBytes))['data']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _diary == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white24),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _diary!['createdAt']
                            ?.toString()
                            .substring(0, 10)
                            .replaceAll('-', '. ') ??
                        '',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'diary_title_${_diary!['id']}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        _diary!['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _diary!['content'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.8,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class DiaryWriteScreen extends StatefulWidget {
  final Map<String, dynamic>? diary;
  const DiaryWriteScreen({super.key, this.diary});
  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.diary?['title'] ?? '');
    _contentCtrl = TextEditingController(text: widget.diary?['content'] ?? '');
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) return;
    final url = Uri.parse(
      widget.diary != null
          ? '$baseUrl/diaries/${widget.diary!['id']}'
          : '$baseUrl/diaries',
    );
    final response = await (widget.diary != null ? http.put : http.post)(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $globalToken',
      },
      body: jsonEncode({
        'title': _titleCtrl.text,
        'content': _contentCtrl.text,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201)
      if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
            Container(width: 40, height: 1, color: Colors.white30),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.8,
                ),
                decoration: const InputDecoration(
                  hintText: 'Write your story...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
