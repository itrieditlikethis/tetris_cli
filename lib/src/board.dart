// This library will be represent the game loop,
// displaying the game board and pieces on it,
// and handling user keystrokes.

import 'dart:async';
import 'dart:io';
import 'blocks.dart';
import '../ansi_cli_helper.dart' as ansi;

// The game board dimensions
const int heightBoard = 20;
const int widthBoard = 10;

// Type of the game field cells
const int posFree = 0; // free space
const int posFilled = 1; // filled space
const int posBorder = 2; // border

late List<List<int>> mainBoard; // main board
late List<List<int>> mainCopy; // copy of main board
late List<List<int>> mblock; // figure block
late int x; // x coordinate
late int y; // y coordinate
bool _isGameOver = false;
int scoreGame = 0;

// subscribtion for key press
StreamSubscription? _subscription;
bool get isGameOver => _isGameOver;

// Main board drawing
void drawBoard() {
  ansi.gotoxy(0, 0); // set cursor to the start
  for (int i = 0; i < heightBoard - 1; i++) {
    for (int j = 0; j < widthBoard - 1; j++) {
      switch (mainBoard[i][j]) {
        case posFree:
          stdout.write(' '); // empty place
        case posFilled:
          stdout.write('O'); // filled place and figure
        case posBorder:
          // set text color to red
          ansi.setTextColor(ansi.redTColor);
          stdout.write('#'); // граница доски
          // return white text color
          ansi.setTextColor(ansi.whiteTColor);
      }
    }
    stdout.write('\n');
  }
}

// Clear filled strings
void clearLine() {
  for (int j = 0; j <= heightBoard - 3; j++) {
    // checking if a line is filled
    int i = 1;
    while (i <= widthBoard - 3) {
      if (mainBoard[j][i] == posFree) {
        break;
      }
      i++;
    }
    if (i == widthBoard - 2) {
      // if line is filled
      // clear it and mowe
      // blocks down
      for (int k = j; k > 0; k--) {
        for (int idx = 1; idx <= widthBoard - 3; idx++) {
          mainBoard[k][idx] = mainBoard[k - 1][idx];
        }
      }
      scoreGame += 10; // score increase
    }
  }
}

// Generate new block and place it on board
void newBlock() {
  // start coordinates of new block
  x = 4;
  y = 0;
  mblock = getNewBlock();
  // add new bloack on the main board
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      mainBoard[i][x + j] = mainCopy[i][x + j] + mblock[i][j];
      // crossing check
      if (mainBoard[i][x + j] > 1) {
        _isGameOver = true;
      }
    }
  }
}

// Moves block on board
// clear one and placed
// on new position
void moveBlock(int x2, int y2) {
  // remove the figure from its current position
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (x + j >= 0) {
        mainBoard[y + i][x + j] -= mblock[i][j];
      }
    }
  }
  // set a new position
  x = x2;
  y = y2;
  // add a figure to a new position
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (x + j >= 0) {
        mainBoard[y + i][x + j] += mblock[i][j];
      }
    }
  }
  drawBoard();
}

// Turn a figure
// using an intermediate two-dimensional array
// and a check is added to determine whether the shape can be rotated.

// Function for checking the possibility
// of shifting a block in a given direction
bool isFilledBlock(int x2, int y2) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (mblock[i][j] != 0 && mainCopy[y2 + i][x2 + j] != 0) {
        return true;
      }
    }
  }
  return false;
}

// Block rotation processing function
void rotateBlock() {
  // temporary block with current figure
  List<List<int>> tmp = List.generate(4, (_) => List.filled(4, 0));
  // fill temporary block
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      tmp[i][j] = mblock[i][j];
    }
  }
  // turn a figure
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      mblock[i][j] = tmp[3 - j][i];
    }
  }
  // Checking whether a figure does not intersect
  // with the border or other blocks of previously
  // placed pieces on the board
  if (isFilledBlock(x, y)) {
    // if there are intersections, then we return the old figure
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        mblock[i][j] = tmp[i][j];
      }
    }
  }
  // Update the current board
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      // remove the old figure
      mainBoard[y + i][x + j] -= tmp[i][j];
      // add a new figure
      mainBoard[y + i][x + j] += mblock[i][j];
    }
  }
  drawBoard();
}

// Update the copy of main board
// after the completion of each game cycle
void savePresentBoardToCpy() {
  for (int i = 0; i < heightBoard - 1; i++) {
    for (int j = 0; j < widthBoard - 1; j++) {
      mainCopy[i][j] = mainBoard[i][j];
    }
  }
}

// Function for processing keystrokes
// Disable echo mode displaying keyboard
// characters in the terminal and pressing Enter,
// which indicates the end of a line.
void controlUserInput() {
  stdin.echoMode = false;
  stdin.lineMode = false;
  _subscription = stdin.listen((data) {
    int key = data.first;
    switch (key) {
      case 119: // W — turn the figure
        rotateBlock();
      case 97: // A — left
        if (!isFilledBlock(x - 1, y)) {
          moveBlock(x - 1, y);
        }
      case 115: // S — down
        if (!isFilledBlock(x, y + 1)) {
          moveBlock(x, y + 1);
        }
      case 100: // D — right
        if (!isFilledBlock(x + 1, y)) {
          moveBlock(x + 1, y);
        }
    }
  });
}

// Function of game initialization
void initGame() {
  scoreGame = 0; // reset the score
  mainBoard = List.generate(
    heightBoard,
    (_) => List.filled(widthBoard, posFree),
  );
  mainCopy = List.generate(
    heightBoard,
    (_) => List.filled(widthBoard, posFree),
  );
  mblock = List.generate(4, (_) => List.filled(4, posFree));
  initDraw();
  controlUserInput();
}

// Function of a game initialization
// Pressing the W key may result in an exception
// being generated and the application being terminated.
// To avoid this, we'll reduce the size of the game board
// in the initDraw function, leaving the rightmost column
// and bottom row empty and filling the row (heightBoard – 2)
// and column (widthBoard – 2) before them with the value 2.
// We'll do the same with the first column of the board.
void initDraw() {
  // fill a game area on main and copy board
  for (int i = 0; i <= heightBoard - 2; i++) {
    for (int j = 0; j <= widthBoard - 2; j++) {
      if (j == 0 || j == widthBoard - 2 || i == heightBoard - 2) {
        mainBoard[i][j] = posBorder;
        mainCopy[i][j] = posBorder;
      }
    }
  }
  newBlock();
  drawBoard();
}

// Game loop step processing function
void nextStep() {
  // can you move the figure checking
  if (!isFilledBlock(x, y + 1)) {
    // yes
    moveBlock(x, y + 1);
  } else {
    // no
    clearLine();
    savePresentBoardToCpy();
    newBlock();
    drawBoard();
  }
}

// Game loop start function
Future<void> start() async {
  while (!isGameOver) {
    // while the fame is not ower
    nextStep();
    await Future.delayed(const Duration(milliseconds: 500));
  }
  // ending the game
  _subscription?.cancel(); // ending the keystrokes listening
  ansi.setTextColor(ansi.yellowTColor);
  stdout.write(
    '===============\n'
    '~~~Game Over~~~\n'
    '===============\n',
  );
  ansi.setBackgroundColor(ansi.blueBgColor);
  stdout.writeln('Score: $scoreGame ');
  await Future.delayed(const Duration(seconds: 5));
  ansi.reset();
}
