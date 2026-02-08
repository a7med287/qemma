class ExamSelection {
  String? selectedGrade;
  String? selectedSubject;
  String? selectedChapter;
  String? selectedDifficulty;

  ExamSelection({
    this.selectedGrade,
    this.selectedSubject,
    this.selectedChapter,
    this.selectedDifficulty,
  });

  bool get isComplete {
    return selectedGrade != null &&
        selectedSubject != null &&
        selectedChapter != null &&
        selectedDifficulty != null;
  }
}