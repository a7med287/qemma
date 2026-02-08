import 'package:flutter/material.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/exam_header.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/exam_summary_dialog.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/navigation_buttons.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/pages/chapter_selection_page.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/pages/difficulty_selection_page.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/pages/grade_selection_page.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/pages/subject_selection_page.dart';
import 'package:qemma/features/exam_generator/presentation/views/widgets/step_indicator.dart';

import '../../data/exam_selection.dart';
import '../../data/step_data.dart';



class ExamSelectionFlow extends StatefulWidget {
  const ExamSelectionFlow({Key? key}) : super(key: key);

  @override
  State<ExamSelectionFlow> createState() => _ExamSelectionFlowState();
}

class _ExamSelectionFlowState extends State<ExamSelectionFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final ExamSelection _selection = ExamSelection();

  final List<StepData> steps = [
    StepData(title: 'اختر الصف', stepNumber: 1),
    StepData(title: 'اختر المادة', stepNumber: 2),
    StepData(title: 'اختر الفصل', stepNumber: 3),
    StepData(title: 'اختر الصعوبة', stepNumber: 4),
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showFinalSummary();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selection.selectedGrade != null;
      case 1:
        return _selection.selectedSubject != null;
      case 2:
        return _selection.selectedChapter != null;
      case 3:
        return _selection.selectedDifficulty != null;
      default:
        return false;
    }
  }

  void _showFinalSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExamSummaryDialog(
        grade: _selection.selectedGrade ?? '',
        subject: _selection.selectedSubject ?? '',
        chapter: _selection.selectedChapter ?? '',
        difficulty: _selection.selectedDifficulty ?? '',
        onStart: _startExam,
      ),
    );
  }

  void _startExam() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'بدء الامتحان: ${_selection.selectedGrade} - ${_selection.selectedSubject} - ${_selection.selectedChapter} - ${_selection.selectedDifficulty}',
          textAlign: TextAlign.right,
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD81B60), Color(0xFFC2185B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const ExamHeader(),
              StepIndicator(
                steps: steps,
                currentPage: _currentPage,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      for (int i = 0; i < index; i++) {
                        steps[i].isCompleted = true;
                      }
                    });
                  },
                  children: [
                    GradeSelectionPage(
                      selectedGrade: _selection.selectedGrade,
                      onGradeSelected: (grade) {
                        setState(() {
                          _selection.selectedGrade = grade;
                        });
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          _nextPage,
                        );
                      },
                    ),
                    SubjectSelectionPage(
                      selectedSubject: _selection.selectedSubject,
                      onSubjectSelected: (subject) {
                        setState(() {
                          _selection.selectedSubject = subject;
                        });
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          _nextPage,
                        );
                      },
                    ),
                    ChapterSelectionPage(
                      selectedChapter: _selection.selectedChapter,
                      onChapterSelected: (chapter) {
                        setState(() {
                          _selection.selectedChapter = chapter;
                        });
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          _nextPage,
                        );
                      },
                    ),
                    DifficultySelectionPage(
                      selectedDifficulty: _selection.selectedDifficulty,
                      onDifficultySelected: (difficulty) {
                        setState(() {
                          _selection.selectedDifficulty = difficulty;
                        });
                      },
                    ),
                  ],
                ),
              ),
              NavigationButtons(
                currentPage: _currentPage,
                canProceed: _canProceed(),
                onPrevious: _previousPage,
                onNext: _nextPage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}