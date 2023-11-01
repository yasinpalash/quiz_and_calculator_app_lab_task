import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'CalculatorScreen.dart';
import 'SummaryScreen.dart';

void main() {
  runApp(MaterialApp(
    home: QuizScreen(),
  ));
}

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  SharedPreferences? sharedPreferences;
  int highestScore = 0;
  int quizNumber = 1;
  int questionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  int timeLeft = 5;
  late Timer timer;

  List<String> questions = [
    'What is the capital of France?',
    'Who painted the Mona Lisa?',
    'What is the largest planet in our solar system?',
    'Which gas do plants absorb from the atmosphere?',
    'What is the largest mammal on Earth?',
    'Who wrote the play "Romeo and Juliet"?',
    'What is the chemical symbol for gold?',
    'Which country is known as the Land of the Rising Sun?',
  ];

  List<List<String>> options = [
    ['Paris', 'London', 'Madrid', 'Rome'],
    ['Leonardo da Vinci', 'Pablo Picasso', 'Vincent van Gogh', 'Claude Monet'],
    ['Saturn', 'Mars', 'Earth', 'Jupiter'],
    ['Carbon dioxide', 'Oxygen', 'Nitrogen', 'Hydrogen'],
    ['Blue whale', 'African elephant', 'Giraffe', 'Hippopotamus'],
    ['William Shakespeare', 'Charles Dickens', 'Jane Austen', 'George Orwell'],
    ['Au', 'Ag', 'Fe', 'Hg'],
    ['Japan', 'China', 'South Korea', 'India'],
  ];

  List<String> correctAnswers = ['Paris', 'Leonardo da Vinci', 'Jupiter', 'Carbon dioxide', 'Blue whale', 'William Shakespeare', 'Au', 'Japan'];

  List<String> selectedAnswers = [];

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    startTimer();
  }

  void initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      highestScore = sharedPreferences?.getInt('highestScore') ?? 0;
    });
  }

  void updateHighestScore() async {
    final currentScore = await sharedPreferences?.getInt('highestScore');
    if (currentScore != null) {
      if (score > currentScore) {
        await sharedPreferences?.setInt('highestScore', score);
        setState(() {
          highestScore = score;
        });
      }
    } else {
      await sharedPreferences?.setInt('highestScore', score);
      setState(() {
        highestScore = score;
      });
    }
  }

  void checkAnswer(String selectedOption) {
    if (isAnswered) {
      return;
    }

    String correctAnswer = correctAnswers[questionIndex];
    bool isCorrect = selectedOption == correctAnswer;

    setState(() {
      selectedAnswers.add(selectedOption);
      isAnswered = true;

      if (isCorrect) {
        score++;
        sharedPreferences?.setInt('highestScore', score);
      }
    });

    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        if (questionIndex < questions.length - 1) {
          questionIndex++;
          isAnswered = false;
          timeLeft = 5;
          startTimer();
        } else {
          // Quiz completed, navigate to the summary screen
          navigateToSummaryScreen();
        }
      });
    });
  }

  void shareScore() {
    String message = 'I scored $score out of ${questions.length} in the quiz app!';
    Share.share(message);
  }

  void resetQuiz() {
    setState(() {
      selectedAnswers.clear();
      questionIndex++;
      quizNumber++;
      score = 0;
      isAnswered = false;
      timeLeft = 5;
    });

    timer.cancel();

    startTimer();
  }

  void updateHighScore() {
    if (score > highestScore) {
      setState(() {
        highestScore = score;
      });
    }
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        if (questionIndex < questions.length - 1) {
          setState(() {
            questionIndex++;
            isAnswered = false;
            timeLeft = 5;
            startTimer();
          });
        } else {
          navigateToSummaryScreen();
        }
      }
    });
  }

  void navigateToSummaryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryScreen(
          totalScore: score,
          highestScore: highestScore,
        ),
      ),
    );
  }

  void nextQuestion() {
    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        isAnswered = false;
        timeLeft = 5;
        startTimer();
      });
    } else {
      navigateToSummaryScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz App'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Question ${questionIndex + 1}:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              questions[questionIndex],
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Time Left: $timeLeft seconds',
              style: TextStyle(
                fontSize: 16,
                color: timeLeft <= 5 ? Colors.red : Colors.green,
              ),
            ),
            Column(
              children: options[questionIndex]
                  .asMap()
                  .entries
                  .map(
                    (entry) => OptionItem(
                  index: entry.key,
                  text: entry.value,
                  isSelected: selectedAnswers.contains(entry.value),
                  isCorrect: entry.value == correctAnswers[questionIndex],
                  showCorrectAnswer: isAnswered && entry.value == correctAnswers[questionIndex],
                  onSelected: () {
                    if (!isAnswered) {
                      checkAnswer(entry.value);
                      timer.cancel();
                    }
                  },
                ),
              )
                  .toList(),
            ),
            SizedBox(height: 16),
            Text(
              'Score: $score / ${questions.length}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: shareScore,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CalculatorScreen()),
                    );
                  },
                  child: Text('Calculator'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (selectedAnswers.contains(correctAnswers[questionIndex]))
              Text(
                'Correct Answer: ${correctAnswers[questionIndex]}',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              'Highest Score: $highestScore',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 16),
            // "Next Question" button
            ElevatedButton(
              onPressed: nextQuestion,
              child: Text('Next Question'),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(16),
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quiz $quizNumber',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'High Score: $highestScore',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionItem extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showCorrectAnswer;
  final Function() onSelected;

  OptionItem({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showCorrectAnswer,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    if (isSelected) {
      backgroundColor = isCorrect ? Colors.green : Colors.red;
    } else if (showCorrectAnswer) {
      backgroundColor = Colors.green;
    }

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '${String.fromCharCode(65 + index)}.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                color: isSelected || showCorrectAnswer ? Colors.white : Colors.black,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


