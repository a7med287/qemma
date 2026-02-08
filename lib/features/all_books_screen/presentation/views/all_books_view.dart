import 'package:flutter/material.dart';
import 'package:qemma/core/utils/styles.dart';
import 'package:qemma/core/widgets/back_icon_widget.dart';
import 'package:qemma/features/all_books_screen/presentation/views/widgets/books_card.dart';
import 'package:qemma/features/all_books_screen/presentation/views/widgets/filter_books_search.dart';
import 'package:qemma/features/all_courses_screen/presentation/views/widgets/course_card.dart';
import 'package:qemma/features/all_courses_screen/presentation/views/widgets/filter_search.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BackIconWidget(),
          ),
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff5C6BFF), Color(0xff9C27B0)],
              ),
            ),
          ),
          title:  Text('كتب المدرسين',style: Styles.textStyleBold20.copyWith(color: Colors.white),),
        ),
        body: Column(
          children: [
            FiltersBooksSection(),
            Expanded(
             child: ListView(
               children: [
                 BookCard(
                   title: 'الميكانيكا والحركة',
                   category: 'فيزياء',
                   price: '279 جنيه',
                   oldPrice: '450 جنيه',
                   instructorName: 'أ/ محمد علي',
                   instructorImage: '',
                   rating: 4.7,
                   reviewCount: 1650,
                   pages: 1900,
                   downloads: 55,
                   favorites: 42,
                   tags: ['ميكانيكا', 'حركة', 'قوى'],
                   gradient: const LinearGradient(
                     colors: [Color(0xFF059669), Color(0xFF047857)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                   primaryColor: const Color(0xFF059669),
                 ),
                 CourseCard(
                   title: 'الجبر والهندسة الفراغية',
                   category: 'رياضيات',
                   price: '249 جنيه',
                   oldPrice: '399 جنيه',
                   instructorName: 'أ/ محمد أحمد',
                   instructorImage: '',
                   rating: 4.9,
                   reviewCount: 3200,
                   students: 3200,
                   lessons: 52,
                   duration: 38,
                   tags: ['جبر', 'معادلات', 'هندسة فراغية'],
                   gradient: const LinearGradient(
                     colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                   primaryColor: const Color(0xFF7C3AED),
                 ),
                 CourseCard(
                   title: 'كورس التفاضل والتكامل الشامل',
                   category: 'رياضيات',
                   price: '299 جنيه',
                   oldPrice: '499 جنيه',
                   instructorName: 'أ/ محمد أحمد',
                   instructorImage: '',
                   rating: 4.8,
                   reviewCount: 2950,
                   students: 2500,
                   lessons: 68,
                   duration: 45,
                   tags: ['تفاضل', 'تكامل', 'دوال'],
                   gradient: const LinearGradient(
                     colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                   primaryColor: const Color(0xFF2563EB),
                 ),
               ],
             ),
            )
          ],
        ),
      ),
    );
  }
}
