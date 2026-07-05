import 'package:flutter/material.dart';
import 'package:gymaipro/payment/widgets/wallet_top_up_sheet.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';

/// مسیر قدیمی شارژ — فقط شیت شارژ را باز می‌کند و برمی‌گردد.
class WalletChargeScreen extends StatefulWidget {
  const WalletChargeScreen({super.key});

  @override
  State<WalletChargeScreen> createState() => _WalletChargeScreenState();
}

class _WalletChargeScreenState extends State<WalletChargeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    if (!mounted) return;
    await WalletTopUpSheet.show(context);
    if (mounted) WidgetSafetyUtils.safePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
        ),
      ),
    );
  }
}
