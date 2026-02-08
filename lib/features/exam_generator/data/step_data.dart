class StepData {
  final String title;
  final int stepNumber;
  bool isCompleted;

  StepData({
    required this.title,
    required this.stepNumber,
    this.isCompleted = false,
  });
}