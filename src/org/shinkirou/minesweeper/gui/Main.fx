package org.shinkirou.minesweeper.gui;
import com.javafx.preview.control.*;
import org.shinkirou.minesweeper.*;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.scene.image.*;
import javafx.scene.shape.*;
import javafx.scene.text.*;
import javafx.animation.*;
import javafx.stage.*;
import javafx.scene.*;
import javax.swing.*;
import java.lang.*;

var boardView = Group {
	styleClass: "board"
}

def w = 20;
def h = w;
def flag:Image = Image { url: "{__DIR__}resources/flag.png" };
def mine:Image = Image { url: "{__DIR__}resources/mine.png" };

function lbl(x:String) {
	return Label {
		text: x
	}
}

function box():TextBox {
	return TextBox {
		text: "10"
		columns: 4
		selectOnFocus: true
		multiline: false
		editable: bind levelSel.selectedIndex == 0
		opacity: bind if (levelSel.selectedIndex == 0) then 1 else 0.5
	}
}

def widthField:TextBox = box();
def heightField:TextBox = box();
def minesField:TextBox = box();
def widthOption = bind
	if (levelSel.selectedIndex == 3) then 30
	else if (levelSel.selectedIndex == 2) then 16
	else if (levelSel.selectedIndex == 1) then 8
	else Integer.parseInt(widthField.text);
def heightOption = bind
	if (levelSel.selectedIndex == 3) then 15
	else if (levelSel.selectedIndex == 2) then 16
	else if (levelSel.selectedIndex == 1) then 8
	else Integer.parseInt(heightField.text);
def minesOption = bind
	if (levelSel.selectedIndex == 3) then 100
	else if (levelSel.selectedIndex == 2) then 40
	else if (levelSel.selectedIndex == 1) then 10
	else Integer.parseInt(minesField.text);
def levelSel = ChoiceBox {
	items: [ 'Custom', 'Beginner', 'Intermidiate', 'Advanced' ]
};

def timer = Timeline {
	repeatCount: Timeline.INDEFINITE
	keyFrames: [
		KeyFrame {
			time: 1s
			action: function() {
				time ++;
			}
		}
	];
}

def cheatBtn:Button = Button {
	text: "Cheat"
	action: function() {
		solver.iteration();
		updateSquares();
	}
}

var time = 0;

var tb = ToolBar {
	styleClass: "toolbar"
	items: [
		Button {
			text: "+"
			action: newGame
		}
		levelSel,
		lbl("Width: "),
		widthField,
		lbl("Height: "),
		heightField,
		lbl("Mines: "),
		minesField,
		cheatBtn
	]
}

var board:Board = null;
var solver:MinesweeperSolver = null;

function gameStarted() {
	return board != null and not(board.isFailed() or board.isSolved())
}

function square(x:Integer, y:Integer):Group {
	return Group {
		content: [
			Rectangle {
				x: x * w
				y: y * h
				width: w
				height: h
				styleClass: "normal"
			}
			Text {
				x: x * w + w * 0.2
				y: y * h + h * 0.8
				styleClass: "label"
				font: Font {
					size: (w + h) / 2 * 0.8
				}
			}
			ImageView {
				x: x * w
				y: y * h
			}
		]
		onMousePressed: function(e) {
			if (gameStarted()) {
				if (e.primaryButtonDown) {
					board.probe(x, y);
				} else if (e.secondaryButtonDown) {
					if (board.getMarks()[y][x]) {
						board.unmark(x, y);
					} else {
						board.mark(x, y);
					}
				} else if (e.middleButtonDown) {
					var count = board.getInformation(x, y);
					if (count < 9) {
						var actual = 0;
						var marks = board.getMarks();
						var width = board.getWidth();
						var height = board.getHeight();
						if (y - 1 > -1 and x - 1 > -1 and marks[y - 1][x - 1]) actual ++;
						if (y - 1 > -1 and marks[y - 1][x]) actual ++;
						if (y - 1 > -1 and x + 1 < width and marks[y - 1][x + 1]) actual ++;
						if (x - 1 > -1 and marks[y][x - 1]) actual ++;
						if (x + 1 < width and marks[y][x + 1]) actual ++;
						if (y + 1 < height and x - 1 > -1 and marks[y + 1][x - 1]) actual ++;
						if (y + 1 < height and marks[y + 1][x]) actual ++;
						if (y + 1 < height and x + 1 < width and marks[y + 1][x + 1]) actual ++;
						if (actual >= count) {
							if (y - 1 > -1 and x - 1 > -1) board.probe(x - 1, y - 1);
							if (y - 1 > -1) board.probe(x, y - 1);
							if (y - 1 > -1 and x + 1 < width) board.probe(x + 1, y - 1);
							if (x - 1 > -1) board.probe(x - 1, y);
							if (x + 1 < width) board.probe(x + 1, y);
							if (y + 1 < height and x - 1 > -1) board.probe(x - 1, y + 1);
							if (y + 1 < height) board.probe(x, y + 1);
							if (y + 1 < height and x + 1 < width) board.probe(x + 1, y + 1);
						}
					}
				}
				updateSquares();
			}
		}
	}
}

function updateSquares() {
	if (board.isFailed()) {
		for (y in [0..<board.getHeight()]) {
			for (x in [0..<board.getWidth()]) {
				board.probe(x, y);
			}
		}
	}

	var i = 0;
	for (y in [0..<board.getHeight()]) {
		for (x in [0..<board.getWidth()]) {
			var gr = (boardView.content[i] as Group).content;
			var n = board.getInformation(x, y);
			(gr[0] as Rectangle).styleClass =
				if (n == 10) then "normal"
				else if (n == 9) then
					if (board.isFailed()) then "mine"
					else "marked"
				else "ground";
			(gr[1] as Text).content =
				if (n > 0 and n < 9) then n.toString()
				else "";
			(gr[2] as ImageView).image =
				if (n == 9) then
					if (board.isFailed()) then mine
					else flag
				else null;
			i ++;
		}
	}
	if (board.isFailed()) {
		JOptionPane.showMessageDialog(null, "GAME OVER");
		cheatBtn.disable = true;
	} else if (board.isSolved()) {
		JOptionPane.showMessageDialog(null, "YOU WIN");
		cheatBtn.disable = true;
	}
}

function num(f:TextBox) {
	var r:Integer;
	try {
		r = Integer.parseInt(widthField.text);
	} catch (e:NumberFormatException) {
		f.text = "10";
	}
	if (r > 100) {
		r = 100;
		f.text = "100";
	} else if (r < 10) {
		r = 10;
		f.text = "10";
	}
	return r;
}

function newGame():Void {
	var width;
	var height;
	var mines;
	if (levelSel.selectedIndex == 0) {
		width = num(widthField);
		height = num(heightField);
		try {
			mines = Integer.parseInt(minesField.text);
		} catch (e:NumberFormatException) {
			mines = 10;
			minesField.text = "10";
		}

		var a = width * height * 0.8 as Integer;
		if (mines > a) {
			 mines = a;
			 minesField.text = a.toString();
		} else if (mines < 1) {
			mines = 1;
			minesField.text = "1";
		}
	} else {
		width = widthOption;
		height = heightOption;
		mines = minesOption;
	}

	time = 0;
	board = new Board(width, height, mines);
	solver = new MinesweeperSolver(board);
	cheatBtn.disable = false;
	boardView.content =
		for (y in [0..<board.getHeight()])
			for (x in [0..<board.getWidth()])
				square(x, y);
}

var mainScene:Scene = Scene {
	width: 600
	height: 600
	stylesheets: [ "{__DIR__}resources/main.css" ]
	content: VBox {
		width: bind mainScene.width
		height: bind mainScene.height
		content: [
			tb,
			ScrollView {
				node: boardView
			}
		]
	}
}

Stage {
	title : "Minesweeper"
	resizable: true
	scene: mainScene
}

newGame();
