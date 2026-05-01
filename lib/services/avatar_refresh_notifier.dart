import 'package:flutter/foundation.dart';

/// وقتی تصویر پروفایل در هر جای اپ عوض شد، این نهifier اعلام می‌کند
/// تا هدر داشبورد، دراور و هر ویجت دیگری که آواتار را نشان می‌دهد به‌روز شود.
class AvatarRefreshNotifier extends ChangeNotifier {
  AvatarRefreshNotifier._();
  static final AvatarRefreshNotifier instance = AvatarRefreshNotifier._();

  void notifyAvatarUpdated() {
    notifyListeners();
  }
}
