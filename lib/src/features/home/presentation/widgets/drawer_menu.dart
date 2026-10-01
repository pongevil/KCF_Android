import 'package:bs_mobile/src/core/theme/app_color_palette.dart';
import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:bs_mobile/src/global/blocs/theme/theme_bloc.dart';
import 'package:bs_mobile/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bs_mobile/src/features/home/presentation/cubit/drawer_profile_cubit.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppThemeExtension>()!;

    return Drawer(
      backgroundColor: cs.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: app.drawerHeaderDecoration,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: app.drawerHeaderTitleColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: cs.surface,
                    child: Icon(
                      Icons.account_circle,
                      size: 54,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<DrawerProfileCubit, DrawerProfileState>(
                  builder: (context, profile) {
                    return AppText(
                      profile.username,
                      style: TextStyle(
                        color: app.drawerHeaderTitleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return SwitchListTile(
                  secondary: Icon(
                    state.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                  title: AppText(
                    state.isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: state.isDark,
                  activeThumbColor: cs.primary,
                  onChanged: (_) {
                    context.read<ThemeBloc>().add(ThemeToggled());
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Theme Color',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: AppColorPalette.values.map((palette) {
                        final isSelected = state.palette == palette;
                        final color = palette.tokens.primary;
                        return _PaletteSwatch(
                          color: color,
                          label: palette.displayName,
                          isSelected: isSelected,
                          onTap: () {
                            context.read<ThemeBloc>().add(
                              ThemePaletteChanged(palette),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          Divider(color: cs.outlineVariant, height: 1),
          BlocBuilder<DrawerProfileCubit, DrawerProfileState>(
            builder: (context, profile) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: cs.onSurfaceVariant,
                ),
                title: AppText(
                  'Version ${profile.version}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {},
              );
            },
          ),
          Divider(color: cs.outlineVariant, height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: Icon(Icons.logout_rounded, color: app.buttonDanger),
            title: AppText(
              'Logout',
              style: TextStyle(
                color: app.buttonDanger,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              BlocProvider.of<AuthBloc>(context).add(AuthLogoutEvent());

              context.go(Routes.login);
            },
          ),
        ],
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected ? cs.onSurface : Colors.transparent,
              width: isSelected ? 3 : 0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}
