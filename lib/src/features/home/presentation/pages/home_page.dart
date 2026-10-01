import 'package:bs_mobile/index.dart';
import 'package:bs_mobile/src/features/home/presentation/bloc/menu_bloc.dart';
import 'package:bs_mobile/src/features/home/presentation/widgets/drawer_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  void _fetchMenu() {
    context.read<MenuBloc>().add(FetchMenuEvent());
    context.read<VersionBloc>().add(VersionCheckEvent());
  }

  Future<void> _refreshMenu() async {
    _fetchMenu();
  }

  IconData _menuIconForIndex(int index) {
    const icons = [
      Icons.dashboard_rounded,
      Icons.tune_rounded,
      Icons.animation_rounded,
      Icons.login_rounded,
    ];
    return icons[index % icons.length];
  }

  List<Color> _menuGradientForIndex(
    int index,
    AppThemeExtension app,
    ColorScheme colorScheme,
  ) {
    final gradients = [
      app.inboundMenuGradient,
      app.outboundMenuGradient,
      app.menuGradientAlt1,
      app.menuGradientAlt2,
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppThemeExtension>()!;
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawer: const DrawerMenu(),
        backgroundColor: app.pageBackgroundGradient.first,
        body: Stack(
          children: [
            // Background Header
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: app.headerGradient,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color: app.barButtonColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.menu_rounded,
                                color: app.barContentColor,
                                size: 24,
                              ),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            ),
                          ),
                        ),
                        AppText(
                          context.tr('mobile.title', fallback: 'BS Mobile'),
                          color: app.barContentColor,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: app.barButtonColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.store,
                              color: app.barContentColor,
                              size: 24,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Expanded(
                    child: BlocBuilder<MenuBloc, MenuState>(
                      builder: (context, state) {
                        if (state is MenuLoading) {
                          return const _MenuShimmerList();
                        }
                        if (state is MenuSuccess) {
                          return RefreshIndicator(
                            onRefresh: _refreshMenu,
                            child: ListView.builder(
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomHeroMenuCard(
                                  title:
                                      state.menuItems?.data?[index].menuName ??
                                      '',
                                  subtitle: '',
                                  icon: _menuIconForIndex(index),
                                  gradientColors: _menuGradientForIndex(
                                    index,
                                    app,
                                    colorScheme,
                                  ),
                                  onTap: () async {
                                    final routeName =
                                        state.menuItems?.data?[index].menuPath;
                                    if (routeName == null ||
                                        routeName.isEmpty) {
                                      return;
                                    }
                                    RouteRegistry.navigateFromMenu(
                                      context,
                                      routeName,
                                    );
                                  },
                                ),
                              ),
                              itemCount: state.menuItems?.data?.length ?? 0,
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                            ),
                          );
                        } else {
                          return RefreshIndicator(
                            onRefresh: _refreshMenu,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 140),
                                Center(child: AppText('Failed to load menu')),
                              ],
                            ),
                          );
                        }
                      },
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
}

class _MenuShimmerList extends StatelessWidget {
  const _MenuShimmerList();

  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context).extension<AppThemeExtension>()!;
    final shimmerBase = app.barContentColor.withValues(alpha: 0.35);
    final shimmerHighlight = app.barContentColor.withValues(alpha: 0.75);
    final placeholder = app.barContentColor.withValues(alpha: 0.25);

    return ListView.separated(
      itemCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: shimmerBase,
          highlightColor: shimmerHighlight,
          child: Container(
            height: 112,
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: placeholder,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: placeholder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: placeholder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: placeholder,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
