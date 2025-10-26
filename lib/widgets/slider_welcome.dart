import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomeSlider extends StatelessWidget {
  WelcomeSlider({super.key});
  final List<Map<String, String>> slides = [
    {
      'title': 'به دنیای فیتنس هوشمند خوش اومدی!',
      'desc': 'با GymAI Pro مسیر پیشرفتت رو دقیق و علمی دنبال کن.',
    },
    {
      'title': 'پروفایل اختصاصی',
      'desc': 'قد، وزن و رکوردهای خودت رو ثبت کن و پیشرفتت رو ببین.',
    },
    {
      'title': 'امنیت و سرعت',
      'desc': 'ورود سریع با کد تایید و اطلاعاتت همیشه امن و در دسترس.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: PageView.builder(
        itemCount: slides.length,
        itemBuilder: (context, index) {
          final slide = slides[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                slide['title']!,
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                slide['desc']!,
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
