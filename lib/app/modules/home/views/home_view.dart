import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../global/accent.dart';
import '../../../global/size_config.dart';
import '../../../global/styles/app_text_style.dart';
import '../../../global/variables.dart';
import '../../../global/widget/accent_pill.dart';
import '../../../global/widget/animated_counter.dart';
import '../../../global/widget/app_buttons.dart';
import '../../../global/widget/functions_widget.dart';
import '../../../global/widget/skeleton_widgets.dart';
import '../../../global/widget/stock_direction_icon.dart';
import '../controllers/home_controller.dart';

/// How far (in `size` units) the Overview card overlaps the header wave —
/// small enough that the wave crest stays visible above the card.
const double _overlap = 0.8;

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    final userName = controller.getName();
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: pageBackground,
        body: Column(
          children: [
            // Pinned like the old AppBar; everything below scrolls under it.
            _buildTopBar(size, topInset, userName),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.reloadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildGreetingHeader(size),
                      Transform.translate(
                        offset: Offset(0, -size * _overlap),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: size * 1.6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildOverviewCard(size),
                              SizedBox(height: size * 2.4),
                              _buildTaskSection(size),
                              SizedBox(height: size * 2.4),
                              _buildInventorySection(size),
                              SizedBox(height: size * 2.4),
                              _buildLatestTransactions(size),
                              SizedBox(height: size * 2.4),
                              _buildSerialTypeCard(size),
                              SizedBox(height: size * 2),
                            ],
                          ),
                        ),
                      ),
                      // Last item of the scroll, not pinned.
                      _buildFooter(size, MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== FOOTER =====================

  /// Slim footer at the end of the scroll; pads past the system navigation bar
  /// so it isn't hidden under it (edge-to-edge).
  Widget _buildFooter(double size, double bottomInset) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: size * 0.6, bottom: size * 0.6 + bottomInset),
      decoration: const BoxDecoration(
        color: navyDark,
        border: Border(top: BorderSide(color: navyMid)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, color: Colors.white54, size: size * 1.1),
          SizedBox(width: size * 0.5),
          Text(
            'Mastercool Inventory Management',
            style: AppTextStyle.custom(
              size,
              scale: 1.0,
              weight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HEADER =====================

  /// Logo + account button, pinned under the status bar.
  Widget _buildTopBar(double size, double topInset, String userName) {
    return Container(
      color: navyDark,
      padding: EdgeInsets.fromLTRB(size * 2, topInset + size * 1.2, size * 2, size * 1.2),
      child: Row(
        children: [
          Container(
            width: size * 3.8,
            height: size * 3.8,
            padding: EdgeInsets.all(size * 0.5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size)),
            child: Image.asset("assets/images/logo_short.png", fit: BoxFit.contain),
          ),
          SizedBox(width: size),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warehouse',
                  style: AppTextStyle.bodyBold(size, color: Colors.white, weight: FontWeight.w700),
                ),
                Text('Mastercool Inventory', style: AppTextStyle.small(size, color: Colors.white70)),
              ],
            ),
          ),
          _buildAccountButton(size, userName),
        ],
      ),
    );
  }

  /// Date, greeting and role over the navy ground, ending in the wave. Scrolls
  /// with the page.
  Widget _buildGreetingHeader(double size) {
    final userName = controller.getName();
    final roles = controller.getRoles();
    return Container(
      width: double.infinity,
      color: navyDark,
      child: Stack(
        children: [
          Positioned(
            right: -size * 6,
            top: -size * 7,
            child: Container(
              width: size * 22,
              height: size * 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: size * 3.6),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: size * 6.4,
              child: const CustomPaint(painter: _HeaderWavePainter()),
            ),
          ),
          Padding(
            // Bottom padding = card overlap + room for the visible wave crest.
            padding: EdgeInsets.fromLTRB(size * 2, size * 0.6, size * 2, size * 7.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    DateFormat('EEEE, d MMMM yyyy').format(controller.currentTime.value),
                    style: AppTextStyle.custom(size, scale: 1.2, weight: FontWeight.w500, color: Colors.white70),
                  ),
                ),
                SizedBox(height: size * 0.4),
                Obx(
                  () => Text(
                    userName.isEmpty ? controller.getGreeting() : '${controller.getGreeting()}, $userName',
                    style: AppTextStyle.h2(size, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
                if (roles.isNotEmpty) ...[
                  SizedBox(height: size * 0.8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: size, vertical: size * 0.4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(size * 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.white, size: size * 1.3),
                        SizedBox(width: size * 0.5),
                        Text(
                          roles,
                          style: AppTextStyle.custom(size, scale: 1.1, weight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountButton(double size, String userName) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.5)),
      child: InkWell(
        key: const Key('homeAccountButton'),
        customBorder: const CircleBorder(),
        onTap: () => controller.showAccountSheet(userName),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              controller.getInitials(userName),
              style: AppTextStyle.bodyBold(size, color: Colors.white, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== SECTION TITLE =====================

  Widget _sectionTitle(double size, String title) {
    return Text(title, style: AppTextStyle.h5(size, weight: FontWeight.w700));
  }

  // ===================== OVERVIEW =====================

  Widget _buildOverviewCard(double size) {
    return Container(
      padding: EdgeInsets.all(size * 1.6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 2),
        border: Border.all(color: cardOutline),
        boxShadow: [BoxShadow(color: navyDark.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overview', style: AppTextStyle.bodyBold(size, weight: FontWeight.w700)),
              Obx(
                () => Container(
                  padding: EdgeInsets.symmetric(horizontal: size, vertical: size * 0.4),
                  decoration: BoxDecoration(
                    color: AppAccent.navy.tint(0.08),
                    borderRadius: BorderRadius.circular(size * 2),
                  ),
                  child: Text(
                    'Year ${controller.currentTime.value.year}',
                    style: AppTextStyle.custom(size, scale: 1.1, weight: FontWeight.w700, color: navyDark),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: size * 1.2),
          Obx(() {
            final dashboard = controller.dashboard.value;
            final stats = [
              _StatConfig(
                'homeStatProducts',
                'Products',
                dashboard.product,
                AppAccent.slate,
                controller.goToProductPage,
              ),
              _StatConfig(
                'homeStatReceive',
                'Received',
                dashboard.receiveOrder,
                AppAccent.navy,
                controller.goToReceiveOrderHomePage,
              ),
              _StatConfig(
                'homeStatOutflow',
                'Outflow',
                dashboard.outflowOrder,
                AppAccent.purple,
                controller.goToOutflowOrderHomePage,
              ),
            ];
            return Row(
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  Expanded(child: _statTile(size, stats[i])),
                  if (i < stats.length - 1) SizedBox(width: size * 0.8),
                ],
              ],
            );
          }),
          SizedBox(height: size * 1.2),
          KeyedSubtree(
            key: const Key('homeViewProducts'),
            child: navyButton(
              size,
              'View products',
              icon: Icons.inventory_2_rounded,
              onPressed: controller.goToProductPage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(double size, _StatConfig stat) {
    final radius = BorderRadius.circular(size * 1.4);
    return Material(
      color: stat.accent.tint(0.08),
      borderRadius: radius,
      child: InkWell(
        key: Key(stat.key),
        borderRadius: radius,
        onTap: stat.onTap,
        child: Padding(
          padding: EdgeInsets.all(size * 1.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCounter(
                value: stat.value,
                style: AppTextStyle.custom(size, scale: 2.2, weight: FontWeight.w800, color: stat.accent.text),
              ),
              SizedBox(height: size * 0.2),
              Text(
                stat.label,
                style: AppTextStyle.custom(size, scale: 1.1, weight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== START A TASK =====================

  Widget _buildTaskSection(double size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(size, 'Start a task'),
        SizedBox(height: size),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _taskCard(
                  size,
                  key: 'homeReceiveTask',
                  title: 'Receive',
                  subtitle: 'By PO · By Supplier',
                  icon: Icons.move_to_inbox_rounded,
                  accent: AppAccent.navy,
                  onTap: controller.goToReceiveOrderHomePage,
                ),
              ),
              SizedBox(width: size),
              Expanded(
                child: _taskCard(
                  size,
                  key: 'homeOutflowTask',
                  title: 'Outflow',
                  subtitle: 'By Request · By Customer',
                  icon: Icons.outbox_rounded,
                  accent: AppAccent.purple,
                  onTap: controller.goToOutflowOrderHomePage,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size),
        _buildDeliveryTile(size),
      ],
    );
  }

  Widget _taskCard(
    double size, {
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required AppAccent accent,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(size * 1.8);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: accent.gradient, borderRadius: radius),
        child: InkWell(
          key: Key(key),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(right: -size * 3, bottom: -size * 3, child: _decorCircle(size * 9, 0.08)),
              Positioned(right: size * 3, top: -size * 2.4, child: _decorCircle(size * 5, 0.06)),
              Padding(
                padding: EdgeInsets.all(size * 1.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: size * 4.2,
                      height: size * 4.2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(size * 1.2),
                      ),
                      child: Icon(icon, color: Colors.white, size: size * 2.2),
                    ),
                    SizedBox(height: size * 1.4),
                    Text(
                      title,
                      style: AppTextStyle.h4(size, color: Colors.white, weight: FontWeight.w700),
                    ),
                    SizedBox(height: size * 0.2),
                    Text(
                      subtitle,
                      style: AppTextStyle.custom(size, scale: 1.1, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _decorCircle(double diameter, double alpha) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  Widget _buildDeliveryTile(double size) {
    const accent = AppAccent.steel;
    final radius = BorderRadius.circular(size * 1.6);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: cardOutline),
      ),
      child: InkWell(
        key: const Key('homeDeliveries'),
        borderRadius: radius,
        onTap: controller.goToDeliveryPage,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 1.4, vertical: size * 1.2),
          child: Row(
            children: [
              Container(
                width: size * 4.2,
                height: size * 4.2,
                decoration: BoxDecoration(gradient: accent.gradient, borderRadius: BorderRadius.circular(size * 1.2)),
                child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: size * 2.1),
              ),
              SizedBox(width: size * 1.2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deliveries', style: AppTextStyle.bodyBold(size, weight: FontWeight.w700)),
                    Text('Track shipped outflow orders', style: AppTextStyle.small(size, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Obx(() {
                final pending = controller.pendingDeliveries.value;
                if (pending == null || pending == 0) return const SizedBox.shrink();
                return accentPill(size, '$pending pending', accent: accent);
              }),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500, size: size * 2.2),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== INVENTORY =====================

  Widget _buildInventorySection(double size) {
    final menus = [
      _MenuConfig('Transactions', Icons.swap_horiz_rounded, AppAccent.sky, controller.goToTransactionPage),
      _MenuConfig('Category', Icons.category_rounded, AppAccent.sage, controller.goToCategoryPage),
      _MenuConfig('Brand', Icons.workspace_premium_rounded, AppAccent.purple, controller.goToBrandPage),
      _MenuConfig('Unit', Icons.straighten_rounded, AppAccent.amber, controller.goToUnitPage),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(size, 'Inventory'),
        SizedBox(height: size),
        Container(
          padding: EdgeInsets.symmetric(horizontal: size * 0.8, vertical: size * 1.2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 1.8),
            border: Border.all(color: cardOutline),
          ),
          child: Row(children: [for (final menu in menus) Expanded(child: _inventoryTile(size, menu))]),
        ),
      ],
    );
  }

  Widget _inventoryTile(double size, _MenuConfig menu) {
    return InkWell(
      onTap: menu.onTap,
      borderRadius: BorderRadius.circular(size * 1.4),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: size * 0.6),
        child: Column(
          children: [
            Container(
              width: size * 4.6,
              height: size * 4.6,
              decoration: BoxDecoration(color: menu.accent.tint(0.12), borderRadius: BorderRadius.circular(size * 1.4)),
              child: Icon(menu.icon, color: menu.accent.text, size: size * 2.2),
            ),
            SizedBox(height: size * 0.6),
            Text(
              menu.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.custom(size, scale: 1.1, weight: FontWeight.w600, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== LATEST TRANSACTIONS =====================

  Widget _buildLatestTransactions(double size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle(size, 'Latest transactions'),
            TextButton(
              onPressed: controller.goToTransactionPage,
              child: Text(
                'See all',
                style: AppTextStyle.bodyBold(size, color: navyDark, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Obx(() {
          if (controller.isLatestLoading.value) {
            return skeletonGenericList(size, count: 4);
          }
          if (controller.lastTransactions.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: size * 2),
              child: textNoData(size),
            );
          }
          final rows = controller.lastTransactions;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: size * 1.4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 1.8),
              border: Border.all(color: cardOutline),
            ),
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _transactionRow(
                    size,
                    rows[i].productName,
                    rows[i].order?.code ?? '-',
                    rows[i].flowType == 'IN',
                    rows[i].qty,
                    rows[i].time,
                  ),
                  if (i < rows.length - 1) const Divider(height: 1, color: cardOutline),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _transactionRow(double size, String name, String code, bool isIn, double qty, String time) {
    final color = isIn ? stockInColor : stockOutColor;
    final qtyText = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size * 1.2),
      child: Row(
        children: [
          stockDirectionIcon(size, isIn: isIn),
          SizedBox(width: size * 1.2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.bodyBold(size, weight: FontWeight.w700),
                ),
                Text(code, style: AppTextStyle.small(size, color: Colors.grey.shade600)),
              ],
            ),
          ),
          SizedBox(width: size),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}$qtyText',
                style: AppTextStyle.bodyBold(size, color: color, weight: FontWeight.w800),
              ),
              Text(time, style: AppTextStyle.small(size, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== SERIAL NUMBER TYPE =====================

  Widget _buildSerialTypeCard(double size) {
    return Container(
      padding: EdgeInsets.all(size * 1.6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 1.8),
        border: Border.all(color: cardOutline),
      ),
      child: Obx(() {
        final unique = controller.productUnique;
        final other = controller.productOther;
        final total = unique + other;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle(size, 'Serial number type'),
                Text('$total products', style: AppTextStyle.small(size, color: Colors.grey.shade600)),
              ],
            ),
            SizedBox(height: size * 1.2),
            if (total == 0)
              textNoData(size, message: 'No data available')
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(size),
                child: SizedBox(
                  height: size * 1.2,
                  child: Row(
                    children: [
                      if (unique > 0)
                        Expanded(
                          flex: unique,
                          child: const ColoredBox(color: navyDark),
                        ),
                      if (unique > 0 && other > 0) const SizedBox(width: 2),
                      if (other > 0)
                        Expanded(
                          flex: other,
                          child: ColoredBox(color: hex1),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size * 1.2),
              Wrap(
                spacing: size * 2,
                runSpacing: size * 0.6,
                children: [
                  _legend(size, navyDark, 'Unique', unique, total),
                  _legend(size, hex1, 'Other', other, total),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _legend(double size, Color color, String label, int count, int total) {
    final percent = (count * 100 / total).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        SizedBox(width: size * 0.6),
        Text(label, style: AppTextStyle.small(size, color: Colors.grey.shade600)),
        SizedBox(width: size * 0.6),
        Text('$count · $percent%', style: AppTextStyle.bodyBold(size, weight: FontWeight.w800)),
      ],
    );
  }
}

// ── Private data classes ──────────────────────────────────────────

class _StatConfig {
  final String key;
  final String label;
  final int value;
  final AppAccent accent;
  final VoidCallback onTap;

  const _StatConfig(this.key, this.label, this.value, this.accent, this.onTap);
}

class _MenuConfig {
  final String title;
  final IconData icon;
  final AppAccent accent;
  final VoidCallback onTap;

  const _MenuConfig(this.title, this.icon, this.accent, this.onTap);
}

/// Two-layer wave at the bottom of the navy header: a faint white swell behind
/// a [pageBackground] wave, so the header flows into the page.
class _HeaderWavePainter extends CustomPainter {
  const _HeaderWavePainter();

  // Drawn on a 390 × 64 grid: start y, two cubic segments, end y.
  static const _back = [18.0, 80.0, 52.0, 160.0, 4.0, 250.0, 22.0, 340.0, 40.0, 360.0, 46.0, 14.0];
  static const _front = [32.0, 90.0, 64.0, 180.0, 10.0, 270.0, 32.0, 360.0, 54.0, 365.0, 50.0, 28.0];

  Path _wave(Size s, List<double> d) {
    double x(double v) => v * s.width / 390;
    double y(double v) => v * s.height / 64;
    return Path()
      ..moveTo(0, y(d[0]))
      ..cubicTo(x(d[1]), y(d[2]), x(d[3]), y(d[4]), x(d[5]), y(d[6]))
      ..cubicTo(x(d[7]), y(d[8]), x(d[9]), y(d[10]), s.width, y(d[11]))
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_wave(size, _back), Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawPath(_wave(size, _front), Paint()..color = pageBackground);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
