import '../tools/team_dice/team_dice_tool.dart';
import '../tools/word_lottery/word_lottery_tool.dart';
import 'tool.dart';

/// Every tool in the app, in main-menu order. Register new tools here.
final List<ToolDefinition> appTools = [
  teamDiceTool,
  wordLotteryTool,
];
