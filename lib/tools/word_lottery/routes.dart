/// Absolute paths for Word Lottery screens. Kept apart from word_lottery_tool.dart so
/// screens can navigate without importing the route table.
abstract final class WordLotteryRoutes {
  static const home = '/word-lottery';
  static const newQuiz = '$home/new';
  static String play(int quizId) => '$home/quiz/$quizId';
}
