# مستندات کامل Feature Showcase Overlay

## 📋 خلاصه
این ویجت یک سیستم راهنمای تعاملی (Feature Tour) است که المان‌های UI را با افکت spotlight هایلایت می‌کند و tooltip راهنما نمایش می‌دهد.

---

## 🏗️ ساختار کلی

### 1. **StatefulWidget با Animation**
```dart
class FeatureShowcaseOverlay extends StatefulWidget
```
- یک `StatefulWidget` که state را مدیریت می‌کند
- از `SingleTickerProviderStateMixin` استفاده می‌کند برای انیمیشن‌ها

### 2. **State Management**
```dart
class _FeatureShowcaseOverlayState extends State<FeatureShowcaseOverlay>
    with SingleTickerProviderStateMixin
```
- `_animationController`: کنترل انیمیشن‌های fade و scale
- `_targetRect`: موقعیت و اندازه المان هدف در صفحه
- `_dontShowAgain`: وضعیت checkbox "دیگه نشون نده"

---

## 🎨 ویجت‌ها و تکنولوژی‌های استفاده شده

### 1. **LayoutBuilder** (برای Responsive Design)
```dart
LayoutBuilder(
  builder: (context, constraints) {
    // محاسبات بر اساس constraints.maxWidth و constraints.maxHeight
  }
)
```
**استفاده:**
- در `build()` برای wrap کردن کل `Stack`
- در `_buildTooltipCard()` برای محاسبه padding و spacing
- در `_buildProgressIndicator()` برای اندازه dots
- در `_buildDontShowAgainCheckbox()` برای اندازه فونت
- در `_buildNavigationButtons()` برای اندازه دکمه‌ها

**چرا؟** برای محاسبه مقادیر بر اساس اندازه واقعی صفحه، نه مقادیر ثابت.

---

### 2. **Stack** (برای Overlay)
```dart
Stack(
  children: [
    // Backdrop
    // Spotlight
    // Tooltip
    // Skip Button
  ]
)
```
**استفاده:** برای قرار دادن چند لایه روی هم:
- لایه 1: Backdrop با blur
- لایه 2: Spotlight (CustomPaint)
- لایه 3: Tooltip card
- لایه 4: دکمه Skip

---

### 3. **Positioned** (برای موقعیت‌یابی دقیق)
```dart
Positioned(
  top: top,
  left: left,
  child: ...
)
```
**استفاده:**
- برای قرار دادن tooltip در موقعیت‌های مختلف (top, bottom, left, right, center)
- برای دکمه Skip در گوشه صفحه

**مهم:** `Positioned` باید مستقیماً فرزند `Stack` باشد (نه داخل `LayoutBuilder`).

---

### 4. **AnimatedBuilder** (برای انیمیشن‌های real-time)
```dart
AnimatedBuilder(
  animation: _animationController,
  builder: (context, child) {
    return Opacity(
      opacity: _fadeAnimation.value,
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
    );
  },
  child: ...
)
```
**استفاده:**
- برای fade in/out tooltip
- برای scale animation (بزرگ شدن تدریجی)
- برای backdrop blur animation

---

### 5. **BackdropFilter** (برای Blur Effect)
```dart
BackdropFilter(
  filter: ImageFilter.blur(
    sigmaX: blurAmount * _fadeAnimation.value,
    sigmaY: blurAmount * _fadeAnimation.value,
  ),
  child: Container(
    color: Colors.black.withValues(alpha: backdropOpacity),
  ),
)
```
**استفاده:** برای تاریک کردن و blur کردن پس‌زمینه (focus روی tooltip)

**مقدار blur:**
- برای center tooltip: `3.0`
- برای سایر موقعیت‌ها: `1.5`

---

### 6. **CustomPaint** (برای Spotlight Effect)
```dart
CustomPaint(
  painter: SpotlightPainter(
    targetRect: _targetRect!,
    progress: _fadeAnimation.value,
    usePulse: widget.step.usePulseAnimation,
    pulseValue: _animationController.value,
  ),
  child: Container(),
)
```
**استفاده:** برای رسم hole در backdrop و highlight کردن المان هدف

**کلاس SpotlightPainter:**
- یک `CustomPainter` که:
  - پس‌زمینه تیره می‌کشد
  - یک hole (سوراخ) در محل المان هدف ایجاد می‌کند
  - border دور hole می‌کشد
  - افکت glow (درخشش) اضافه می‌کند (اگر `usePulse` true باشد)

---

### 7. **SingleChildScrollView** (برای جلوگیری از Overflow)
```dart
SingleChildScrollView(
  padding: EdgeInsets.all(padding),
  child: Column(...)
)
```
**استفاده:** در `_buildTooltipCard()` برای scrollable کردن محتوای tooltip اگر محتوا زیاد باشد

---

### 8. **Expanded و Flexible** (برای Layout Responsive)
```dart
Row(
  children: [
    Flexible(child: Icon(...)),  // آیکون
    Expanded(child: Text(...)),  // عنوان
  ]
)
```
**استفاده:**
- `Flexible` برای آیکون (می‌تواند shrink کند)
- `Expanded` برای عنوان (تمام فضای باقیمانده را می‌گیرد)
- `Expanded` برای دکمه‌های navigation (قبلی/بعدی)

**چرا؟** برای اینکه layout در همه اندازه‌های صفحه درست کار کند.

---

### 9. **ConstrainedBox** (برای محدود کردن اندازه)
```dart
ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: tooltipMaxWidth,
    maxHeight: tooltipMaxHeight,
  ),
  child: _buildTooltipCard(),
)
```
**استفاده:** برای محدود کردن اندازه tooltip به اندازه صفحه

---

### 10. **MediaQuery** (برای اطلاعات صفحه)
```dart
final screenSize = MediaQuery.of(context).size;
final screenWidth = screenSize.width;
final screenHeight = screenSize.height;
final safeAreaTop = mediaQuery.padding.top;
final safeAreaBottom = mediaQuery.padding.bottom;
```
**استفاده:** برای:
- محاسبه اندازه tooltip
- محاسبه safe area (برای notch و navigation bar)
- محاسبه موقعیت tooltip

---

### 11. **Scrollable.ensureVisible** (برای اسکرول خودکار)
```dart
Scrollable.ensureVisible(
  widget.step.targetKey!.currentContext!,
  duration: const Duration(milliseconds: 500),
  curve: Curves.easeInOut,
  alignment: 0.3, // المنت در 30% بالای صفحه
  alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
);
```
**استفاده:** برای اسکرول خودکار به المان هدف قبل از نمایش tooltip

**چرا؟** اگر المان خارج از صفحه باشد، tooltip نمایش داده نمی‌شود.

---

### 12. **GlobalKey و RenderBox** (برای محاسبه موقعیت)
```dart
final RenderBox renderBox = renderObject;
final offset = renderBox.localToGlobal(Offset.zero);
final size = renderBox.size;
final targetRect = offset & size;
```
**استفاده:** برای محاسبه موقعیت دقیق المان در صفحه

**منطق:**
1. از `GlobalKey` برای دسترسی به `BuildContext` المان استفاده می‌شود
2. از `findRenderObject()` برای گرفتن `RenderObject`
3. از `localToGlobal()` برای تبدیل موقعیت local به global
4. از `&` operator برای ایجاد `Rect` از `Offset` و `Size`

---

## 📐 منطق Responsive Design

### 1. **محاسبه اندازه Tooltip**
```dart
final tooltipMaxWidth = screenWidth > 600
    ? 400.w  // برای تبلت‌ها
    : screenWidth * 0.9;  // برای موبایل‌ها (90% عرض)

final tooltipMaxHeight = screenHeight > 800
    ? screenHeight * 0.4  // برای صفحه‌های بزرگ (40% ارتفاع)
    : screenHeight * 0.5;  // برای سایر دستگاه‌ها (50% ارتفاع)
```

### 2. **محاسبه Padding و Spacing**
```dart
final padding = constraints.maxWidth * 0.04;  // 4% از عرض
final spacing = constraints.maxHeight * 0.015;  // 1.5% از ارتفاع
```

### 3. **محاسبه اندازه فونت**
```dart
// عنوان
fontSize: constraints.maxWidth * 0.04  // 4% از عرض

// توضیحات
fontSize: constraints.maxWidth * 0.033  // 3.3% از عرض

// دکمه‌ها
fontSize: constraints.maxWidth * 0.033  // 3.3% از عرض
```

### 4. **محاسبه اندازه آیکون**
```dart
size: constraints.maxWidth * 0.045  // 4.5% از عرض
```

### 5. **محاسبه Progress Indicator**
```dart
final dotSize = constraints.maxWidth * 0.015;  // 1.5% از عرض
final activeDotSize = constraints.maxWidth * 0.05;  // 5% از عرض
final dotSpacing = constraints.maxWidth * 0.006;  // 0.6% از عرض
```

### 6. **محاسبه Spotlight (در SpotlightPainter)**
```dart
// Padding
final basePaddingPercent = size.width > 600 ? 0.013 : 0.015;
final basePadding = size.width * basePaddingPercent;

// Border Radius
final borderRadiusPercent = size.width > 600 ? 0.027 : 0.03;
final borderRadius = size.width * borderRadiusPercent;

// Stroke Width
final strokeWidthPercent = size.width > 600 ? 0.005 : 0.006;
final strokeWidth = size.width * strokeWidthPercent;
```

---

## 🎬 انیمیشن‌ها

### 1. **AnimationController**
```dart
_animationController = AnimationController(
  duration: const Duration(milliseconds: 400),
  vsync: this,
);
```

### 2. **Fade Animation**
```dart
_fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
);
```
**استفاده:** برای fade in/out tooltip و backdrop

### 3. **Scale Animation**
```dart
_scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
  CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
);
```
**استفاده:** برای بزرگ شدن تدریجی tooltip (از 80% به 100%)

### 4. **Pulse Animation (در SpotlightPainter)**
```dart
final padding = basePadding + (usePulse ? pulseValue * size.width * 0.005 : 0);
```
**استفاده:** برای pulse کردن border دور spotlight

---

## 📍 منطق موقعیت‌یابی Tooltip

### 1. **TooltipPosition Enum**
- `center`: وسط صفحه
- `top`: بالای المان
- `bottom`: پایین المان
- `left`: چپ المان
- `right`: راست المان

### 2. **محاسبه موقعیت**
```dart
switch (widget.step.tooltipPosition) {
  case TooltipPosition.bottom:
    top = _targetRect!.bottom + spacing;
    left = (screenWidth - tooltipMaxWidth) / 2;
    // اگر جا نداره، بالای target قرار بده
    if (top + tooltipMaxHeight > screenHeight - minBottom) {
      top = _targetRect!.top - tooltipMaxHeight - spacing;
    }
    break;
  // ...
}
```

### 3. **Safe Area Support**
```dart
final minTop = safeAreaTop + (screenHeight * 0.02);
final minBottom = safeAreaBottom + (screenHeight * 0.02);
final minLeft = screenWidth * 0.04;
final minRight = screenWidth * 0.04;
```
**استفاده:** برای جلوگیری از خارج شدن tooltip از safe area (notch, navigation bar)

### 4. **Fallback Logic**
- اگر tooltip از صفحه خارج شود، موقعیت تغییر می‌کند
- اگر باز هم جا نداشته باشد، در center قرار می‌گیرد

---

## 🔄 Lifecycle و State Management

### 1. **initState**
```dart
@override
void initState() {
  super.initState();
  // ایجاد AnimationController
  // اسکرول به target
  // محاسبه موقعیت
  // شروع انیمیشن
}
```

### 2. **didUpdateWidget**
```dart
@override
void didUpdateWidget(FeatureShowcaseOverlay oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.step.id != widget.step.id) {
    // اگر step تغییر کرد، دوباره اسکرول و نمایش بده
    _animationController.reset();
    _scrollToTargetAndShow();
  }
}
```

### 3. **dispose**
```dart
@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}
```

---

## 🎯 متدهای کلیدی

### 1. **_scrollToTarget()**
- از `Scrollable.ensureVisible` استفاده می‌کند
- المنت را در 30% بالای صفحه قرار می‌دهد
- 550ms صبر می‌کند تا اسکرول کامل شود

### 2. **_calculateTargetPosition()**
- از `GlobalKey` برای دسترسی به `BuildContext` استفاده می‌کند
- از `RenderBox` برای محاسبه موقعیت استفاده می‌کند
- از `localToGlobal()` برای تبدیل موقعیت استفاده می‌کند
- Retry logic دارد (اگر renderBox آماده نباشد، دوباره تلاش می‌کند)

### 3. **_positionTooltip()**
- موقعیت tooltip را بر اساس `tooltipPosition` محاسبه می‌کند
- Safe area را در نظر می‌گیرد
- Fallback logic دارد

### 4. **_buildTooltipCard()**
- کارت tooltip را می‌سازد
- از `LayoutBuilder` برای responsive design استفاده می‌کند
- از `SingleChildScrollView` برای scrollable کردن استفاده می‌کند

---

## 🎨 UI Components

### 1. **Progress Indicator**
- Dots برای نمایش پیشرفت
- Dot فعال بزرگ‌تر است
- Dots قبلی پررنگ‌تر هستند

### 2. **Icon و Title**
- آیکون در یک Container با پس‌زمینه رنگی
- عنوان در `Expanded` widget

### 3. **Description**
- متن توضیحات با `maxLines: 5`
- `TextOverflow.ellipsis` برای متن‌های طولانی

### 4. **Action Button (اختیاری)**
- دکمه عمل اگر `step.action` وجود داشته باشد

### 5. **Checkbox "دیگه نشون نده"**
- فقط در آخرین مرحله نمایش داده می‌شود
- از `Flexible` برای layout استفاده می‌کند

### 6. **Navigation Buttons**
- دکمه "قبلی" (فقط اگر اولین مرحله نباشد)
- دکمه "بعدی" یا "متوجه شدم!" (در آخرین مرحله)
- از `Expanded` برای layout استفاده می‌کند

### 7. **Skip Button**
- در گوشه بالا چپ
- با `Positioned` قرار گرفته

---

## 🐛 مشکلات حل شده

### 1. **ParentDataWidget Error**
**مشکل:** `Positioned` داخل `LayoutBuilder` بود
**حل:** `LayoutBuilder` را به `build()` منتقل کردیم و `_positionTooltip()` را تغییر دادیم که `BoxConstraints` را به عنوان پارامتر بگیرد

### 2. **Overflow در Tooltip**
**مشکل:** محتوای tooltip از container خارج می‌شد
**حل:** `SingleChildScrollView` اضافه کردیم

### 3. **المان خارج از صفحه**
**مشکل:** اگر المان خارج از صفحه بود، tooltip نمایش داده نمی‌شد
**حل:** `Scrollable.ensureVisible` اضافه کردیم

### 4. **موقعیت نادرست در دستگاه‌های مختلف**
**مشکل:** موقعیت tooltip در دستگاه‌های مختلف متفاوت بود
**حل:** همه محاسبات را بر اساس درصد صفحه انجام دادیم

### 5. **Blur زیاد**
**مشکل:** المان‌ها به خاطر blur زیاد واضح نبودند
**حل:** مقدار blur را کاهش دادیم (از 4.0 به 1.5)

---

## 📦 Dependencies

```yaml
flutter_screenutil: ^3.x.x  # برای responsive sizing (.w, .h, .r, .sp)
```

---

## 🎯 نتیجه

این ویجت یک سیستم راهنمای کامل و responsive است که:
- ✅ در همه اندازه‌های صفحه درست کار می‌کند
- ✅ انیمیشن‌های smooth دارد
- ✅ المان‌ها را به وضوح highlight می‌کند
- ✅ از safe area پشتیبانی می‌کند
- ✅ به صورت خودکار اسکرول می‌کند
- ✅ از flexible widgets استفاده می‌کند

