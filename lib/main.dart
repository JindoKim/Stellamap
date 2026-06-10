import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

// ==========================================
// 🌐 전역 상태 관리 및 API 설정
// ==========================================
String? globalToken;
String? globalUsername;
const String baseUrl = 'http://10.0.2.2:9000/api/v1';

final ValueNotifier<int> globalThemeIndex = ValueNotifier(0);

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.white24,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

String? getUserIdFromToken(String? token) {
  if (token == null) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    String payload = parts[1];
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final decodedBytes = base64Url.decode(payload);
    final decodedString = utf8.decode(decodedBytes);
    final map = jsonDecode(decodedString);
    return map['sub']?.toString();
  } catch (_) {
    return null;
  }
}

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
// ✨ 밤하늘 배경
// ==========================================
class NightSkyBackground extends StatefulWidget {
  final Widget child;
  const NightSkyBackground({super.key, required this.child});
  @override
  State<NightSkyBackground> createState() => _NightSkyBackgroundState();
}

class StarParticle {
  double x, y, speed, size, opacity;
  StarParticle({
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
  final List<StarParticle> _stars = [];

  final List<List<Color>> _themeColors = const [
    [Color(0xFF2C2C2C), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
    [Color(0xFF333333), Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
    [Color(0xFF2A2A2A), Color(0xFF151515), Color(0xFF000000)],
    [Color(0xFF303030), Color(0xFF1C1C1C), Color(0xFF080808)],
    [Color(0xFF252525), Color(0xFF121212), Color(0xFF050505)],
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
          StarParticle(
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
          duration: const Duration(milliseconds: 700),
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
  final List<StarParticle> stars;
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
// 0. 스플래시 화면
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
  double _opacity = 0.0, _scale = 0.90, _translateY = 40.0;
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
      final resData = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isLoginMode) {
          globalToken = resData['data']['accessToken'];
          globalUsername = _usernameCtrl.text;
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            FadePageRoute(page: const MainDashboardScreen()),
          );
        } else {
          showToast(context, '가입이 완료되었습니다. 로그인해주세요.');
          setState(() => isLoginMode = true);
        }
      } else {
        showToast(context, resData['message'] ?? '오류 발생');
      }
    } catch (e) {
      showToast(context, '서버와 연결할 수 없습니다.');
    }
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
  bool _canScrollPageView = true;
  final List<String> _titles = [
    'Starry Map',
    'Night Diaries',
    'My Profile',
    'My Wishes',
    'Stardust Shop',
  ];
  final List<IconData> _navIcons = [
    Icons.auto_awesome,
    Icons.menu_book_outlined,
    Icons.person_outline,
    Icons.favorite_border,
    Icons.palette_outlined,
  ];
  final List<String> _navLabels = [
    'Map',
    'Diaries',
    'Profile',
    'Wishes',
    'Shop',
  ];
  final List<Widget> _pages = const [
    StarMapTab(),
    DiariesTab(),
    ProfileTab(),
    WishedStarsTab(),
    SkinShopTab(),
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

      // ✨ Listener를 추가하여 터치 시작 위치를 감지합니다.
      body: Listener(
        onPointerDown: (event) {
          // 첫 번째 탭(별자리 지도)일 때만 동작 제어
          if (currentRealIndex == 0) {
            final screenWidth = MediaQuery.of(context).size.width;
            final dx = event.position.dx;

            // 좌우 40px 가장자리 터치 시에만 다음 화면으로 넘어가는 스와이프 허용
            if (dx < 40 || dx > screenWidth - 40) {
              if (!_canScrollPageView)
                setState(() => _canScrollPageView = true);
            } else {
              // 중앙 터치 시 PageView 스크롤을 막아 InteractiveViewer가 드래그를 차지하게 함
              if (_canScrollPageView)
                setState(() => _canScrollPageView = false);
            }
          } else {
            // 다른 탭에서는 어디서든 스와이프 허용
            if (!_canScrollPageView) setState(() => _canScrollPageView = true);
          }
        },
        child: PageView.builder(
          controller: _pageCtrl,
          // ✨ _canScrollPageView 상태에 따라 스크롤 동작을 변경합니다.
          physics: _canScrollPageView
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
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
      ),
      bottomNavigationBar: SafeArea(
        // ... 하단 네비게이션 바 코드는 기존과 동일 ...
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
// 3. 🌌 캔버스 별자리 지도 (터치감 및 상시 색상 완벽 개선)
// ==========================================
class StarMapTab extends StatefulWidget {
  const StarMapTab({super.key});
  @override
  State<StarMapTab> createState() => _StarMapTabState();
}

class _StarMapTabState extends State<StarMapTab> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _stars = [];
  List<List<Map<String, dynamic>>> _starPairs = [];
  Map<String, dynamic>? _selectedStar;

  final TransformationController _transCtrl = TransformationController();
  late AnimationController _cameraAnimCtrl;
  late AnimationController _floatAnimCtrl;
  Animation<Matrix4>? _cameraAnim;
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _cameraAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cameraAnimCtrl.addListener(() {
      if (_cameraAnim != null) _transCtrl.value = _cameraAnim!.value;
    });
    _floatAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fetchStars();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusTo(1000, 1000, 1.2);
    });
  }

  @override
  void dispose() {
    _cameraAnimCtrl.dispose();
    _floatAnimCtrl.dispose();
    _transCtrl.dispose();
    super.dispose();
  }

  void _focusTo(double targetX, double targetY, double targetScale) {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final x = targetX * targetScale - (size.width / 2);
    final y = targetY * targetScale - (size.height / 2);
    final targetMatrix = Matrix4.identity()
      ..translate(-x, -y)
      ..scale(targetScale);
    _cameraAnim = Matrix4Tween(begin: _transCtrl.value, end: targetMatrix)
        .animate(
          CurvedAnimation(
            parent: _cameraAnimCtrl,
            curve: Curves.easeInOutCubic,
          ),
        );
    _cameraAnimCtrl.forward(from: 0.0);
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
            'x': _rnd.nextDouble() * 700 + 650,
            'y': _rnd.nextDouble() * 700 + 650,
            'phase': _rnd.nextDouble() * math.pi * 2,
          });
        }

        // 최소 신장 트리(MST) 단일 성단 연결 알고리즘
        List<List<Map<String, dynamic>>> pairs = [];
        if (parsedStars.isNotEmpty) {
          List<Map<String, dynamic>> connected = [parsedStars[0]];
          List<Map<String, dynamic>> unconnected = List.from(parsedStars)
            ..removeAt(0);

          while (unconnected.isNotEmpty) {
            double minDist = double.infinity;
            Map<String, dynamic>? bestConnected;
            Map<String, dynamic>? bestUnconnected;
            int bestUnconnectedIndex = -1;

            for (var cNode in connected) {
              for (int i = 0; i < unconnected.length; i++) {
                var uNode = unconnected[i];
                double dx = cNode['x'] - uNode['x'];
                double dy = cNode['y'] - uNode['y'];
                double dist = dx * dx + dy * dy;
                if (dist < minDist) {
                  minDist = dist;
                  bestConnected = cNode;
                  bestUnconnected = uNode;
                  bestUnconnectedIndex = i;
                }
              }
            }

            if (bestConnected != null && bestUnconnected != null) {
              pairs.add([bestConnected, bestUnconnected]);
              connected.add(bestUnconnected);
              unconnected.removeAt(bestUnconnectedIndex);
            } else {
              break;
            }
          }
        }

        setState(() {
          _stars = parsedStars;
          _starPairs = pairs;
        });
      }
    } catch (e) {}
  }

  void _onStarTap(Map<String, dynamic> star) {
    setState(() => _selectedStar = star);
    _focusTo(star['x'], star['y'], 2.5);
  }

  void _onBackgroundTap() {
    if (_selectedStar != null) {
      setState(() => _selectedStar = null);
      _focusTo(1000, 1000, 1.2);
    }
  }

  Future<void> _sendWish() async {
    if (_selectedStar == null) return;
    final starId = _selectedStar!['id'];
    setState(() => _selectedStar = null);
    _focusTo(1000, 1000, 1.2);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/stars/$starId/wishes'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
      final resData = jsonDecode(utf8.decode(res.bodyBytes));
      showToast(context, resData['message']);
      if (res.statusCode == 200) _fetchStars();
    } catch (_) {}
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
    String? myId = getUserIdFromToken(globalToken);
    bool isMyStar =
        _selectedStar != null && _selectedStar!['userId']?.toString() == myId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transCtrl,
            boundaryMargin: const EdgeInsets.all(2000),
            minScale: 0.1,
            maxScale: 4.0,
            constrained: false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onBackgroundTap,
              child: SizedBox(
                width: 2000,
                height: 2000,
                child: AnimatedBuilder(
                  animation: _floatAnimCtrl,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        CustomPaint(
                          size: const Size(2000, 2000),
                          painter: ConstellationLinePainter(
                            pairs: _starPairs,
                            animValue: _floatAnimCtrl.value,
                          ),
                        ),
                        ..._stars.map((star) {
                          bool isSelected =
                              _selectedStar != null &&
                              _selectedStar!['id'] == star['id'];
                          Color starColor = Color(
                            int.parse("0xFF${star['color'] ?? 'FFFFFF'}"),
                          );
                          double bobY =
                              math.sin(
                                _floatAnimCtrl.value * math.pi * 2 +
                                    star['phase'],
                              ) *
                              4.0;

                          return Positioned(
                            // 🌟 히트박스 범위를 대폭 축소 (100 -> 40 오프셋 변경, 가로세로 80정밀 크기화)
                            left: star['x'] - 40,
                            top: star['y'] - 40 + bobY,
                            width: 80,
                            height: 80,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => _onStarTap(star),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 🌟 스킨 색상이 상시 노출되도록 컬러 연동 및 하이라이트 핵 추가
                                  Container(
                                    width: isSelected ? 16 : 8,
                                    height: isSelected ? 16 : 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: starColor, // 안 눌렸을 때도 상시 적용되게 수정됨
                                      boxShadow: [
                                        BoxShadow(
                                          color: starColor.withOpacity(
                                            isSelected ? 0.9 : 0.5,
                                          ),
                                          blurRadius: isSelected ? 12 : 6,
                                          spreadRadius: isSelected ? 2 : 1,
                                        ),
                                      ],
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 4,
                                              height: 4,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  // 🌟 작아진 히트박스 영역에 맞춰 글자 오프셋 위치 재조정
                                  Positioned(
                                    top: 52,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          star['text'],
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (star['wishCount'] > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              '★ ${star['wishCount']}',
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            bottom: _selectedStar != null ? 30 : -200,
            left: 24,
            right: 24,
            child: _selectedStar != null
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '별자리에 담긴 기억',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 11,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '"${_selectedStar!['text']}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isMyStar
                                ? Colors.white24
                                : Colors.white,
                            side: BorderSide(
                              color: isMyStar ? Colors.white10 : Colors.white24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: isMyStar ? null : _sendWish,
                          icon: Icon(
                            isMyStar
                                ? Icons.person_outline
                                : Icons.favorite_border,
                            size: 18,
                          ),
                          label: Text(
                            isMyStar ? '내가 만든 별' : '염원 보내기',
                            style: const TextStyle(letterSpacing: 1.0),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
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

class ConstellationLinePainter extends CustomPainter {
  final List<List<Map<String, dynamic>>> pairs;
  final double animValue;

  ConstellationLinePainter({required this.pairs, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 0.8;

    for (var pair in pairs) {
      var s1 = pair[0];
      var s2 = pair[1];
      double bobY1 = math.sin(animValue * math.pi * 2 + s1['phase']) * 4.0;
      double bobY2 = math.sin(animValue * math.pi * 2 + s2['phase']) * 4.0;

      canvas.drawLine(
        Offset(s1['x'], s1['y'] + bobY1),
        Offset(s2['x'], s2['y'] + bobY2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationLinePainter oldDelegate) => true;
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
// 4. 일기장 (Diaries)
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
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/diaries'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
      if (res.statusCode == 200)
        setState(() {
          _diaries = jsonDecode(utf8.decode(res.bodyBytes))['data'] ?? [];
          _isLoading = false;
        });
      else
        setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
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

// ==========================================
// 5. 내 프로필
// ==========================================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userProfile;
  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
      if (res.statusCode == 200)
        setState(
          () => _userProfile = jsonDecode(utf8.decode(res.bodyBytes))['data'],
        );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    bool isPremium = _userProfile!['isPremium'] == true;
    String equippedColor = _userProfile!['equippedStarColor'] ?? 'FFFFFF';
    int point = _userProfile!['point'] ?? 0;
    int dailyWishCount = _userProfile!['dailyWishCount'] ?? 0;
    String nickname = _userProfile!['nickname'] ?? 'User';
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
                color: Color(int.parse("0xFF$equippedColor")).withOpacity(0.3),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 2.0,
                  ),
                ),
                if (isPremium)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.workspace_premium,
                      color: Colors.yellowAccent,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '스타더스트: $point',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '오늘 보낸 염원: $dailyWishCount / ${isPremium ? 20 : 3}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => performLogout(context),
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. 내가 위로한 별들
// ==========================================
class WishedStarsTab extends StatefulWidget {
  const WishedStarsTab({super.key});
  @override
  State<WishedStarsTab> createState() => _WishedStarsTabState();
}

class _WishedStarsTabState extends State<WishedStarsTab> {
  List<dynamic> _wishedStars = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchWishedStars();
  }

  Future<void> _fetchWishedStars() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/stars/wished'),
        headers: {'Authorization': 'Bearer $globalToken'},
      );
      if (res.statusCode == 200)
        setState(() {
          _wishedStars = jsonDecode(utf8.decode(res.bodyBytes))['data'] ?? [];
          _isLoading = false;
        });
      else
        setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    if (_wishedStars.isEmpty)
      return const Center(
        child: Text(
          "아직 염원을 보낸 별이 없습니다.\n밤하늘에서 빛나는 별을 터치해보세요.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white30, height: 1.5),
        ),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _wishedStars.length,
      itemBuilder: (context, index) {
        final star = _wishedStars[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: Color(int.parse("0xFF${star['color'] ?? 'FFFFFF'}")),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.favorite, color: Colors.yellowAccent, size: 16),
              const SizedBox(height: 12),
              Text(
                star['text'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 7. 스타더스트 상점
// ==========================================
class SkinShopTab extends StatefulWidget {
  const SkinShopTab({super.key});
  @override
  State<SkinShopTab> createState() => _SkinShopTabState();
}

class _SkinShopTabState extends State<SkinShopTab> {
  Map<String, dynamic>? _userProfile;
  final List<String> freeColors = ["FFFFFF", "FFF59D", "90CAF9", "CE93D8"];
  final List<String> premiumColors = [
    "FFCDD2",
    "F48FB1",
    "B39DDB",
    "80CBC4",
    "A5D6A7",
    "FFAB91",
    "BCAAA4",
    "81D4FA",
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {'Authorization': 'Bearer $globalToken'},
    );
    if (res.statusCode == 200)
      setState(
        () => _userProfile = jsonDecode(utf8.decode(res.bodyBytes))['data'],
      );
  }

  Future<void> _changeColor(String hex) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/me/star-color'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $globalToken',
      },
      body: jsonEncode({'hexColor': hex}),
    );
    final resData = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) {
      _fetchProfile();
      showToast(context, '우주 색상이 변경되었습니다.');
    } else
      showToast(context, resData['message'] ?? '오류가 발생했습니다.');
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    bool isPremium = _userProfile!['isPremium'] == true;
    String currentSkin = _userProfile!['equippedStarColor'] ?? 'FFFFFF';
    int point = _userProfile!['point'] ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 스타더스트: $point',
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            '기본 별빛 스킨',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: freeColors
                .map((hex) => _buildColorBtn(hex, false, hex == currentSkin))
                .toList(),
          ),
          const SizedBox(height: 48),
          const Text(
            '은하단 전용 스킨',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: premiumColors
                .map(
                  (hex) => _buildColorBtn(hex, !isPremium, hex == currentSkin),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBtn(String hex, bool isLocked, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isLocked)
          showToast(context, '은하단(프리미엄) 전용 스킨입니다.');
        else
          _changeColor(hex);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(int.parse("0xFF$hex")),
          border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
          boxShadow: [
            BoxShadow(
              color: Color(int.parse("0xFF$hex")).withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: isLocked
            ? const Icon(Icons.lock, color: Colors.black54, size: 24)
            : (isSelected
                  ? const Icon(Icons.check, color: Colors.black, size: 28)
                  : null),
      ),
    );
  }
}
