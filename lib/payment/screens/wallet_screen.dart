import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/widgets/wallet_colors.dart';
import 'package:gymaipro/payment/widgets/wallet_overview.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final GlobalKey<WalletOverviewState> _overviewKey =
      GlobalKey<WalletOverviewState>();

  Future<void> _refresh() async {
    await _overviewKey.currentState?.reload(refreshBalance: true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            'کیف پول',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: WalletColors.accent(context),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowRight,
              color: WalletColors.accent(context),
            ),
            onPressed: () => WidgetSafetyUtils.safePop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                LucideIcons.refreshCw,
                color: WalletColors.accent(context),
              ),
              onPressed: _refresh,
            ),
          ],
        ),
        body: WalletOverview(
          key: _overviewKey,
        ),
      ),
    );
  }
}
