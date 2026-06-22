import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'feature_card.dart';
import 'on_boarding_models.dart';

class FeaturesOnBoardingPage extends StatelessWidget {
  const FeaturesOnBoardingPage({super.key});

  static const List<OnBoardingFeatureModel> _features = [
    OnBoardingFeatureModel(
      icon: Icons.emoji_events_rounded,
      color: AppColors.accentPink,
      title: "نظام Gamification",
      description: "اكسب نقاط وجوائز مع كل إنجاز، واستمتع بتجربة تعليمية ممتعة.",
    ),
    OnBoardingFeatureModel(
      icon: Icons.trending_up_rounded,
      color: AppColors.accentTeal,
      title: "متابعة مستمرة",
      description: "نظام متابعة شامل يرصد تقدمك ويعطيك تقارير دورية عن أدائك.",
    ),
    OnBoardingFeatureModel(
      icon: Icons.school_rounded,
      color: AppColors.accentBlue,
      title: "شرح بسيط وواضح",
      description: "نقدم محتوى تعليمي بسيط وسهل الفهم يساعدك على استيعاب المواد بكل سهولة.",
    ),
    OnBoardingFeatureModel(
      icon: Icons.bar_chart_rounded,
      color: AppColors.accentIndigo,
      title: "اختبارات شهرية",
      description: "تدريبات واختبارات دورية تضمن لك الاستعداد التام للامتحانات.",
    ),
    OnBoardingFeatureModel(
      icon: Icons.groups_rounded,
      color: AppColors.accentPink,
      title: "فصول افتراضية تفاعلية",
      description: "تفاعل مباشر مع المدرسين وزملائك في بيئة تعليمية حية.",
    ),
    OnBoardingFeatureModel(
      icon: Icons.psychology_alt_rounded,
      color: AppColors.accentPurple,
      title: "AI لتحديد نقاط الضعف",
      description: "الذكاء الاصطناعي يحلل أداءك ويساعدك على تقوية نقاط ضعفك.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: [
          Text(
            "ليه تختار قِمّة؟",
            style: TextStyles.bold20.copyWith(color: context.textPrimary),
          ),
          SizedBox(height: 6.h),
          Text(
            "لأننا مش مجرد منصة تعليمية\nإحنا شريكك لحد يوم النتيجة",
            textAlign: TextAlign.center,
            style: TextStyles.regular13.copyWith(color: context.textSecondary),
          ),
          SizedBox(height: 20.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _features.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                // mainAxisExtent: 168.h,
                childAspectRatio: 0.80
            ),
            itemBuilder: (context, index) => FeatureCard(feature: _features[index]),
          ),
        ],
      ),
    );
  }
}