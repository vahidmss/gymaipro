import 'package:flutter/material.dart';

class WelcomeSlider extends StatelessWidget {
  final List<Map<String, String>> slides = [
    {
      'title': 'به دنیای فیتنس هوشمند خوش اومدی!',
      'desc': 'با GymAI Pro مسیر پیشرفتت رو دقیق و علمی دنبال کن.'
    },
    {
      'title': 'پروفایل اختصاصی',
      'desc': 'قد، وزن و رکوردهای خودت رو ثبت کن و پیشرفتت رو ببین.'
    },
    {
      'title': 'امنیت و سرعت',
      'desc': 'ورود سریع با کد تایید و اطلاعاتت همیشه امن و در دسترس.'
    },
  ];

   WelcomeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
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
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                slide['desc']!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
