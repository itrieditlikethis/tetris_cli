import 'package:tetris_cli/tetris_cli.dart' as tetris_cli;
import 'package:tetris_cli/ansi_cli_helper.dart' as ansi;

void main(List<String> arguments) {
  ansi.reset();
  ansi.hideCursor();

  tetris_cli.initGame();
  tetris_cli.start();
}
