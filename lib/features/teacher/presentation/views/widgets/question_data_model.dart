import 'package:flutter/material.dart';

class QuestionData {
  String type = 'multiple-choice';
  int marks = 5;
  int correctAnswerIndex = 0;

  final TextEditingController textCtrl;
  final TextEditingController gradingCtrl;
  List<TextEditingController> optionCtrls;

  QuestionData({
    TextEditingController? textCtrl,
    TextEditingController? gradingCtrl,
    List<TextEditingController>? optionCtrls,
  })  : textCtrl = textCtrl ?? TextEditingController(),
        gradingCtrl = gradingCtrl ?? TextEditingController(),
        optionCtrls = optionCtrls ??
            List.generate(4, (_) => TextEditingController());
}
