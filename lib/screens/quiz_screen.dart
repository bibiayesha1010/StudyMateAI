import 'package:flutter/material.dart';

import '../models/quiz_model.dart';
import '../models/feedback_model.dart';
import '../models/tips_model.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  late List<int?> userAnswers;
  bool showResult = false;

  int score = 0;
  List<WrongAnswerFeedback> wrongAnswers = [];

  @override
  void initState() {
    super.initState();
    userAnswers = List<int?>.filled(widget.quiz.questions.length, null);
  }

  void selectAnswer(int optionIndex) {
    setState(() {
      userAnswers[currentIndex] = optionIndex;
    });
  }

  void nextQuestion() {
    if (currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      finishQuiz();
    }
  }

  // All scoring happens right here, in Dart, comparing to the
  // correctIndex stored in the quiz — no AI call, no ambiguity.
  void finishQuiz() {
    int computedScore = 0;
    final computedWrong = <WrongAnswerFeedback>[];

    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final q = widget.quiz.questions[i];
      final userAnswer = userAnswers[i];

      if (userAnswer == q.correctIndex) {
        computedScore++;
      } else {
        computedWrong.add(
          WrongAnswerFeedback(
            question: q.question,
            correctAnswer: q.options[q.correctIndex],
            userAnswer:
                userAnswer != null ? q.options[userAnswer] : "No answer",
            explanation: q.explanation,
          ),
        );
      }
    }

    ProgressService.instance.addEntry(
      ProgressEntry(
        topic: widget.quiz.topic,
        score: computedScore,
        total: widget.quiz.questions.length,
        date: DateTime.now(),
      ),
    );

    setState(() {
      score = computedScore;
      wrongAnswers = computedWrong;
      showResult = true;
    });
  }

  void retakeQuiz() {
    setState(() {
      currentIndex = 0;
      userAnswers = List<int?>.filled(widget.quiz.questions.length, null);
      showResult = false;
      score = 0;
      wrongAnswers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return showResult ? buildResultScreen() : buildQuestionScreen();
  }

  Widget buildQuestionScreen() {
    final question = widget.quiz.questions[currentIndex];
    final selected = userAnswers[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Question ${currentIndex + 1}/${widget.quiz.questions.length}",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(question.options.length, (index) {
              final isSelected = selected == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.blue.withOpacity(0.1) : null,
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => selectAnswer(index),
                  child: Text(question.options[index]),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected == null ? null : nextQuestion,
                child: Text(
                  currentIndex == widget.quiz.questions.length - 1
                      ? "Finish"
                      : "Next",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildResultScreen() {
    final feedback = FeedbackModel(
      score: score,
      total: widget.quiz.questions.length,
      wrongAnswers: wrongAnswers,
    );

    final tips = TipsModel.fromWrongTopics(
      wrongAnswers.map((w) => w.question).toList(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Result")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  "${feedback.score}/${feedback.total}",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.isGoodScore
                      ? "Nice work! 🎉"
                      : "Let's review a few things",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          if (feedback.wrongAnswers.isNotEmpty) ...[
            const Text(
              "Where you went wrong:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...feedback.wrongAnswers.map(
              (w) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.question,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Your answer: ${w.userAnswer}",
                        style: const TextStyle(color: Colors.red),
                      ),
                      Text(
                        "Correct answer: ${w.correctAnswer}",
                        style: const TextStyle(color: Colors.green),
                      ),
                      const SizedBox(height: 6),
                      Text(w.explanation),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            "Tips:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...tips.tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text("• $t"),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Chat"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: retakeQuiz,
                  child: const Text("Retake Quiz"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}