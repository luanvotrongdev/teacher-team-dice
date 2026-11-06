/// Absolute paths for Team Dice screens. Kept apart from team_dice_tool.dart so
/// screens can navigate without importing the route table.
abstract final class TeamDiceRoutes {
  static const home = '/team-dice';
  static const newClass = '$home/new';
  static String draw(int classId) => '$home/draw/$classId';
  static String result(int classId) => '$home/class/$classId';
}
