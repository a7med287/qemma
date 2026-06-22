import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'on_boarding_models.dart';
import 'step_card.dart';

class StepsOnBoardingPage extends StatelessWidget {
  const StepsOnBoardingPage({super.key});

  // Displayed in natural reading order 1 -> 4; the RTL grid takes care of
  // placing "1" on the right, matching the original design.
  static const List<OnBoardingStepModel> _steps = [
    OnBoardingStepModel(
      number: 1,
      title: "سجل حسابك",
      description: "أنشئ حسابك على المنصة في خطوات بسيطة وابدأ رحلتك التعليمية فورًا.",
    ),
    OnBoardingStepModel(
      number: 2,
      title: "اختر موادك",
      description: "اختر المواد التي تناسب قسمك الدراسي وابدأ في التعلم فورًا.",
    ),
    OnBoardingStepModel(
      number: 3,
      title: "تابع دروسك",
      description: "شاهد الفيديوهات التعليمية، وحل التمارين، وتفاعل مع المدرسين.",
    ),
    OnBoardingStepModel(
      number: 4,
      title: "حسّن نتائجك",
      description: "راقب تقدمك، واستفد من التحليلات، وحقق أعلى الدرجات.",
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
            "كيف قِمّة بتسهل عليك؟",
            style: TextStyles.bold20.copyWith(color: context.textPrimary),
          ),
          SizedBox(height: 6.h),
          Text(
            "خطواتنا بتساعدك تتعلم بأسرع طريقة ممكنة وتخليك دايمًا في المقدمة.",
            textAlign: TextAlign.center,
            style: TextStyles.regular13.copyWith(color: context.textSecondary),
          ),
          SizedBox(height: 20.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _steps.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                // mainAxisExtent: 168.h,
                childAspectRatio: 0.80
            ),
            itemBuilder: (context, index) => StepCard(step: _steps[index]),
          ),
        ],
      ),
    );
  }
}