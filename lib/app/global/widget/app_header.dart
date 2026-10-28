import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../accent.dart';
import '../functions.dart';
import '../size_config.dart';
import '../variables.dart';
import '../styles/app_text_style.dart';
import 'skeleton_widgets.dart';

/// The navy AppBar used by every screen except Home. The module color shows
/// only in the white tile ([accent] icon); back always pops via [closeRoute]
/// unless [onBack] overrides it.
PreferredSizeWidget appHeader(
  String title, {
  required AppAccent accent,
  required IconData icon,
  String? subtitle,
  bool subtitleLoading = false,
  List<Widget> actions = const [],
  bool showBack = true,
  VoidCallback? onBack,
}) => _AppHeader(
  title: title,
  accent: accent,
  icon: icon,
  subtitle: subtitle,
  subtitleLoading: subtitleLoading,
  actions: actions,
  showBack: showBack,
  onBack: onBack,
);

/// Reads [SizeConfig.defaultSize] at build/layout time, so the header can be
/// created before `SizeConfig.init` runs.
class _AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const _AppHeader({
    required this.title,
    required this.accent,
    required this.icon,
    required this.subtitle,
    required this.subtitleLoading,
    required this.actions,
    required this.showBack,
    required this.onBack,
  });

  final String title;
  final AppAccent accent;
  final IconData icon;
  final String? subtitle;
  final bool subtitleLoading;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(SizeConfig.defaultSize * 6.25);

  @override
  Widget build(BuildContext context) {
    final size = SizeConfig.defaultSize;
    final subtitle = this.subtitle;
    return AppBar(
      toolbarHeight: size * 6.25,
      elevation: 0,
      scrolledUnderElevation: 3,
      surfaceTintColor: Colors.transparent,
      backgroundColor: navyDark, // fallback under the gradient
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      // SizedBox.expand: a childless DecoratedBox lays out at zero height here.
      flexibleSpace: const SizedBox.expand(child: DecoratedBox(decoration: BoxDecoration(gradient: navyGradient))),
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? 0 : size * 1.6,
      leadingWidth: showBack ? size * 5.4 : 0,
      leading: showBack
          ? IconButton(
              key: const Key('appBarBackButton'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              tooltip: 'Back',
              onPressed: onBack ?? () => closeRoute(),
            )
          : null,
      title: Row(
        children: [
          Container(
            width: size * 3.75,
            height: size * 3.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 1.05),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: accent.base, size: size * 1.9),
          ),
          SizedBox(width: size * 1.2),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.custom(size, scale: 1.67, weight: FontWeight.w700, color: Colors.white),
                ),
                if (subtitle != null)
                  skeletonize(
                    loading: subtitleLoading,
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.custom(
                        size,
                        scale: 1.25,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        if (actions.isNotEmpty) SizedBox(width: size * 0.8),
      ],
    );
  }
}

/// Wraps an [appHeader] in an [Obx] for headers whose subtitle reads Rx state
/// (e.g. the selected fill item or the loaded delivery).
PreferredSizeWidget obxHeader(PreferredSizeWidget Function() builder) =>
    PreferredSize(preferredSize: Size.fromHeight(SizeConfig.defaultSize * 6.25), child: Obx(builder));

/// Square translucent action button for [appHeader] `actions`.
Widget headerAction(IconData icon, {required String tooltip, required VoidCallback onPressed}) {
  final size = SizeConfig.defaultSize;
  return Padding(
    padding: EdgeInsets.only(left: size * 0.6),
    child: Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 1.25),
        child: InkWell(
          borderRadius: BorderRadius.circular(size * 1.25),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: size * 2.1),
          ),
        ),
      ),
    ),
  );
}
