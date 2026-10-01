import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:bs_mobile/src/global/blocs/locale/locale_bloc.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _loaderFade;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Staggered Animations
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Pulse Animation for the background rings
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine));

    _entranceCtrl.forward().then((_) {
      if (mounted) {
        _pulseCtrl.repeat(reverse: true);
      }
    });

    checkToken();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void checkToken() async {
    await Future.delayed(const Duration(milliseconds: 4000));

    if (!mounted) return;

    final localeBloc = context.read<LocaleBloc>();

    final api = await AppStorage.getApi();
    if (!mounted) return;

    if (api == null || api.isEmpty) {
      context.go(Routes.login);
      return;
    }

    final token = await AppStorage.getToken();
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      final localeReady = localeBloc.stream.firstWhere(
        (state) => state is LocaleLoaded || state is LocaleFailure,
      );
      localeBloc.add(LoadLocaleEvent());
      await localeReady;
      if (!mounted) return;
      context.go(Routes.home);
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            _buildAnimatedLogo(cs),
            const SizedBox(height: 48),
            _buildAnimatedText(cs),
            const Spacer(flex: 2),
            _buildLoader(cs),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(ColorScheme cs) {
    return FadeTransition(
      opacity: _logoFade,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _logoScale.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer subtle pulse ring
                Container(
                  width: 190 * _pulseScale.value,
                  height: 190 * _pulseScale.value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(56),
                    color: cs.primary.withOpacity(0.03),
                  ),
                ),
                // Inner distinct pulse ring
                Container(
                  width: 150 * _pulseScale.value,
                  height: 150 * _pulseScale.value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    color: cs.primary.withOpacity(0.05),
                  ),
                ),
                // Main Logo Card
                Container(
                  width: 110,
                  height: 110,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/oga.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.warehouse_rounded,
                        size: 54,
                        color: cs.primaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedText(ColorScheme cs) {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textFade,
        child: Column(
          children: [
            AppText(
              'OGA GROUP',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            AppText(
              'OGA GROUP Warehouse Management',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader(ColorScheme cs) {
    return FadeTransition(
      opacity: _loaderFade,
      child: Column(
        children: [
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                backgroundColor: cs.primary.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            'Initializing workspace...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant.withOpacity(0.8),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
