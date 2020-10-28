package overlays;

class Pause extends h2d.Object {
	
	private var enabledColor : h3d.Vector = new h3d.Vector(0,1.0,0);
	private var disabledColor : h3d.Vector = new h3d.Vector(1.0,0,0);
	private var overColor : h3d.Vector = new h3d.Vector(0.70,0.7,1.0);
	private var outColor : h3d.Vector = new h3d.Vector(1.0,1.0,1.0);

	private var pauseText : h2d.Text;
	private var background : h2d.Graphics;
	private var restartText : h2d.Text;

	private var player1Box : h2d.Object;
	private var player1TextStatus : h2d.Text;

	private var player2Box : h2d.Object;
	private var player2TextStatus : h2d.Text;

	private var aiHumansBox : h2d.Object;
	private var aiHumansTextStatus : h2d.Text;

	private var roomController : h2d.Object;
	private var roomPattern : h2d.Object;
	private var roomPatternGraphic : h2d.Object;
	private var roomPatternText : h2d.Text;

	private var currentScores : h2d.Object;

	private var restartWithSettingsButton : h2d.Object;

	private var activeGeneration : game.GenerationState;

	public var newSettingsReady : Bool = false;

	public function new(generationState : game.GenerationState, ?parent : h2d.Object) {
		super(parent);

		activeGeneration = generationState;

		background = new h2d.Graphics(this);
		
		pauseText = new h2d.Text(Fonts.title, this);
		pauseText.textAlign = Center;
		pauseText.text = "PAUSED";
		pauseText.dropShadow = { 
			dx : 2,
			dy : 3,
			color : 0x000000,
			alpha : 0.9,
		};

		restartText = new h2d.Text(Fonts.timer, this);
		restartText.text = "R to restart. \nSPACE to unpause.";
		restartText.textAlign = Center;
		restartText.dropShadow = { 
			dx : 0,
			dy : 2,
			color : 0x000000,
			alpha : 0.9,
		};

		player1Box = new h2d.Object(this);
		var player1Text = new h2d.Text(Fonts.timer, player1Box);
		player1Text.text = "Player 1";
		player1Text.color = outColor;
		player1Text.setScale(1);
		player1Text.textAlign = Center;
		player1Text.x = -75;
		player1Text.y = 0;
		var player1Text2 = new h2d.Text(Fonts.normal, player1Box);
		player1Text2.text = "W,A,S,D KEYS";
		player1Text2.color = outColor;
		player1Text2.setScale(0.5);
		player1Text2.textAlign = Center;
		player1Text2.x = -75;
		player1Text2.y = 25;
		player1TextStatus = new h2d.Text(Fonts.timer, player1Box);
		player1TextStatus.text = "DISABLED";
		player1TextStatus.setScale(1);
		player1TextStatus.textAlign = Center;
		player1TextStatus.x = -75;
		player1TextStatus.y = 35;
		player1TextStatus.color = disabledColor;
		var interactive1 = new h2d.Interactive(150,70,player1Box);
		interactive1.x = -150;
		interactive1.onClick = function(e : hxd.Event) { 
			if (e.button == 0) {
				activeGeneration.player1 = !activeGeneration.player1;
				toggleUpdate(activeGeneration.player1, player1TextStatus);
			}
		}
		interactive1.onOver = function (e : hxd.Event) {
			player1Text.color = overColor;
			player1Text2.color = overColor;
		};
		interactive1.onOut = function (e : hxd.Event) {
			player1Text.color = outColor;
			player1Text2.color = outColor;
		};

		player2Box = new h2d.Object(this);
		var player2Text = new h2d.Text(Fonts.timer, player2Box);
		player2Text.text = "Player 2";
		player2Text.color = outColor;
		player2Text.setScale(1);
		player2Text.textAlign = Center;
		player2Text.x = -75;
		player2Text.y = 0;
		var player2Text2 = new h2d.Text(Fonts.normal, player2Box);
		player2Text2.text = "ARROW KEYS";
		player2Text2.color = outColor;
		player2Text2.setScale(0.5);
		player2Text2.textAlign = Center;
		player2Text2.x = -75;
		player2Text2.y = 25;
		player2TextStatus = new h2d.Text(Fonts.timer, player2Box);
		player2TextStatus.text = "DISABLED";
		player2TextStatus.setScale(1);
		player2TextStatus.textAlign = Center;
		player2TextStatus.x = -75;
		player2TextStatus.y = 35;
		player2TextStatus.color = disabledColor;
		var interactive2 = new h2d.Interactive(150,70,player2Box);
		interactive2.x = -150;
		interactive2.onClick = function(e : hxd.Event) { 
			if (e.button == 0) {
				activeGeneration.player2 = !activeGeneration.player2;
				toggleUpdate(activeGeneration.player2, player2TextStatus);
			}
		}
		interactive2.onOver = function (e : hxd.Event) {
			player2Text.color = overColor;
			player2Text2.color = overColor;
		};
		interactive2.onOut = function (e : hxd.Event) {
			player2Text.color = outColor;
			player2Text2.color = outColor;
		};

		aiHumansBox = new h2d.Object(this);
		var aiHumansText = new h2d.Text(Fonts.timer, aiHumansBox);
		aiHumansText.text = "AI Humans";
		aiHumansText.color = outColor;
		aiHumansText.setScale(1);
		aiHumansText.textAlign = Center;
		aiHumansText.x = -75;
		aiHumansText.y = 0;
		var aiHumansText2 = new h2d.Text(Fonts.normal, aiHumansBox);
		aiHumansText2.text = "LCLICK +, RCLICK -";
		aiHumansText2.color = outColor;
		aiHumansText2.setScale(0.5);
		aiHumansText2.textAlign = Center;
		aiHumansText2.x = -75;
		aiHumansText2.y = 25;
		aiHumansTextStatus = new h2d.Text(Fonts.timer, aiHumansBox);
		aiHumansTextStatus.text = '${activeGeneration.aiHumans}';
		aiHumansTextStatus.setScale(1);
		aiHumansTextStatus.textAlign = Center;
		aiHumansTextStatus.x = -75;
		aiHumansTextStatus.y = 35;
		var interactive3 = new h2d.Interactive(150,70,aiHumansBox);
		interactive3.enableRightButton = true;
		interactive3.x = -150;
		interactive3.onClick = function(e : hxd.Event) { 
			if (e.button == 0) { activeGeneration.aiHumans++; }
			else { activeGeneration.aiHumans--; }

			if (activeGeneration.aiHumans <= 0) { activeGeneration.aiHumans = 0; }
			aiHumansTextStatus.text = '${activeGeneration.aiHumans}';
		}
		interactive3.onOver = function (e : hxd.Event) {
			aiHumansText.color = overColor;
			aiHumansText2.color = overColor;
		};
		interactive3.onOut = function (e : hxd.Event) {
			aiHumansText.color = outColor;
			aiHumansText2.color = outColor;
		};

		currentScores = new h2d.Object(this);
		currentScores.alpha = 0;
		currentScores.x = 10;
		currentScores.y = 10;

		roomPattern = new h2d.Object(this);
		roomPattern.alpha = 0;
		roomPatternText = new h2d.Text(Fonts.timer, roomPattern);
		roomPatternText.color = outColor;
		roomPatternText.text = "NO PATTERN";
		roomPatternText.setScale(1);
		roomPatternText.textAlign = Center;
		roomPatternText.x = -75;
		roomPatternText.y = 0;
		var roomPatternTextLeft = new h2d.Text(Fonts.normal, roomPattern);
		roomPatternTextLeft.text = "PREVIOUS";
		roomPatternTextLeft.color = outColor;
		roomPatternTextLeft.setScale(0.5);
		roomPatternTextLeft.textAlign = Center;
		roomPatternTextLeft.x = -75 - 35;
		roomPatternTextLeft.y = 40;
		var roomPatternTextRight = new h2d.Text(Fonts.normal, roomPattern);
		roomPatternTextRight.text = "NEXT";
		roomPatternTextRight.color = outColor;
		roomPatternTextRight.setScale(0.5);
		roomPatternTextRight.textAlign = Center;
		roomPatternTextRight.x = -75 + 35;
		roomPatternTextRight.y = 40;
		roomPatternGraphic = new h2d.Object(roomPattern);
		roomPatternGraphic.x = -150;
		roomPatternGraphic.y = 45;
		var roomPatternRandomSpawn = new h2d.Text(Fonts.timer, roomPattern);
		roomPatternRandomSpawn.text = "fixed x,y";
		roomPatternRandomSpawn.color = outColor;
		roomPatternRandomSpawn.setScale(0.75);
		roomPatternRandomSpawn.textAlign = Center;
		roomPatternRandomSpawn.x = -75;
		roomPatternRandomSpawn.y = 20;
		var spawnInteractive = new h2d.Interactive(150,30, roomPattern);
		spawnInteractive.x = -150;
		spawnInteractive.y = 20;
		spawnInteractive.onClick = function(e : hxd.Event) { 
			activeGeneration.randomRoomPlacement = !activeGeneration.randomRoomPlacement;
			if (activeGeneration.randomRoomPlacement) {roomPatternRandomSpawn.text = "random x,y";}
			else {roomPatternRandomSpawn.text = "fixed x,y";}
		}
		spawnInteractive.onOver = function (e : hxd.Event) { roomPatternRandomSpawn.color = overColor; };
		spawnInteractive.onOut = function (e : hxd.Event) { roomPatternRandomSpawn.color = outColor; };

		roomPatternGraphic = new h2d.Object(roomPattern);
		roomPatternGraphic.x = -150;
		roomPatternGraphic.y = 55;
		var emptyRoom = new h2d.Text(Fonts.timer, roomPatternGraphic);
		emptyRoom.text = "No Available Patterns";
		emptyRoom.setScale(0.75);
		var roominteractiveLeft = new h2d.Interactive(75, 25, roomPattern);
		roominteractiveLeft.x = -150;
		roominteractiveLeft.y = 40;
		roominteractiveLeft.onClick = function(e : hxd.Event) { selectPreviousPattern(); }
		roominteractiveLeft.onOver = function (e : hxd.Event) { roomPatternTextLeft.color = overColor; };
		roominteractiveLeft.onOut = function (e : hxd.Event) { roomPatternTextLeft.color = outColor; };
		var roominteractiveRight = new h2d.Interactive(75, 25, roomPattern);
		roominteractiveRight.x = -75;
		roominteractiveRight.y = 40;
		roominteractiveRight.onClick = function(e : hxd.Event) { selectNextPattern(); }
		roominteractiveRight.onOver = function (e : hxd.Event) { roomPatternTextRight.color = overColor; };
		roominteractiveRight.onOut = function (e : hxd.Event) { roomPatternTextRight.color = outColor; };

		roomController = new h2d.Object(this);
		var roomText = new h2d.Text(Fonts.timer, roomController);
		roomText.text = "Player is Room";
		roomText.color = outColor;
		roomText.setScale(1);
		roomText.textAlign = Center;
		roomText.x = -75;
		roomText.y = 0;
		var roomText2 = new h2d.Text(Fonts.normal, roomController);
		roomText2.text = "MOUSE, LCLICK SPAWN,\nWHEEL or +,- SWITCH";
		roomText2.color = outColor;
		roomText2.setScale(0.5);
		roomText2.textAlign = Center;
		roomText2.x = -75;
		roomText2.y = 25;
		var roomStatusText = new h2d.Text(Fonts.timer, roomController);
		roomStatusText.text = 'ENABLED';
		roomStatusText.setScale(1);
		roomStatusText.textAlign = Center;
		roomStatusText.x = -75;
		roomStatusText.y = 50;
		roomStatusText.color = enabledColor;
		var interactive4 = new h2d.Interactive(150,70,roomController);
		interactive4.x = -150;
		interactive4.onClick = function(e : hxd.Event) { 
			if (e.button == 0) {
				activeGeneration.isRoomAPlayer = !activeGeneration.isRoomAPlayer;
				toggleUpdate(activeGeneration.isRoomAPlayer, roomStatusText);

				if (activeGeneration.isRoomAPlayer == false) {
					currentScores.alpha = 1;
				} else {
					currentScores.alpha = 0;
				}
			}

			if (activeGeneration.isRoomAPlayer == false) {
				roomPattern.alpha = 1;
			} else {
				roomPattern.alpha = 0;
			}
		}
		interactive4.onOver = function (e : hxd.Event) {
			roomText.color = overColor;
			roomText2.color = overColor;
		};
		interactive4.onOut = function (e : hxd.Event) {
			roomText.color = outColor;
			roomText2.color = outColor;
		};

		restartWithSettingsButton = new h2d.Object(this);
		var restartWithSettingsButtonText = new h2d.Text(Fonts.timer, restartWithSettingsButton);
		restartWithSettingsButtonText.text = "Restart with These Settings";
		restartWithSettingsButtonText.color = outColor;
		restartWithSettingsButtonText.setScale(1);
		restartWithSettingsButtonText.textAlign = Right;
		restartWithSettingsButtonText.x = -10;
		restartWithSettingsButtonText.y = -10 - Fonts.timer.lineHeight;
		var interactiveRestart = new h2d.Interactive(300, 100, restartWithSettingsButtonText);
		interactiveRestart.x = -300;
		interactiveRestart.y = -50;
		interactiveRestart.onClick = function (e : hxd.Event) { 
			newSettingsReady = true;
		};
		interactiveRestart.onOver = function (e : hxd.Event) {
			restartWithSettingsButtonText.color = overColor;
		};
		interactiveRestart.onOut = function (e : hxd.Event) {
			restartWithSettingsButtonText.color = outColor;
		};
		
		alpha = 0;

		updateSelectedPattern();
	}

	public function setVisible(state : Bool) {
		if (state) { alpha = 1; } else { alpha = 0; }
		updateSelectedPattern();
		updateScores();
	}

	/**
	 * Updates all parameters.
	 */
	public function updateAllValues() {
		aiHumansTextStatus.text = '${activeGeneration.aiHumans}';
		toggleUpdate(activeGeneration.player1, player1TextStatus);
		toggleUpdate(activeGeneration.player2, player2TextStatus);
	}

	private function selectNextPattern() {
		if (activeGeneration.patternSets.length == 0) { return; }
		
		activeGeneration.activePattern ++;
		if (activeGeneration.activePattern > activeGeneration.patternSets.length - 1) { 
			activeGeneration.activePattern = 0;
		}

		updateSelectedPattern();
	}

	private function selectPreviousPattern() {
		if (activeGeneration.patternSets.length == 0) { return; }
		
		if (activeGeneration.activePattern <= 0) { 
			activeGeneration.activePattern = activeGeneration.patternSets.length - 1;
		} else {
			activeGeneration.activePattern --;
		}
		
		updateSelectedPattern();
	}

	private function updateScores() {
		if (activeGeneration.patternSets.length == 0) { return; }

		currentScores.removeChildren();

		var dy = 0;
		for (s in activeGeneration.patternSets[activeGeneration.activePattern].scores) {

			var aitag : String = if (s.ai) { "ai "; } else { "   "; };

			var text = new h2d.Text(Fonts.timer, currentScores);
			text.setScale(1);
			text.text = '$aitag${Math.floor(s.value*1000)/1000}';
			text.y = dy;
			dy += 20;
		}
	}

	private function updateSelectedPattern() {
		if (activeGeneration.patternSets.length == 0) { return; }

		roomPatternGraphic.removeChildren();

		var selectedPattern = activeGeneration.patternSets[activeGeneration.activePattern];
		var i = 1;

		if (selectedPattern.user) { roomPatternText.text = "Pattern, User"; }
		else { roomPatternText.text = "Pattern, Generated"; }
		roomPatternText.text = '${activeGeneration.activePattern+1} ' + roomPatternText.text;

		var dy = 0;
		var currentKind : Data.BladesKind = selectedPattern.pattern[i].kind;
		var currentCount : Int = 1;
		while(i <= selectedPattern.pattern.length) {
			var generate = false;

			if (i < selectedPattern.pattern.length) {
				if (selectedPattern.pattern[i].kind == currentKind) { currentCount++; }
				else { generate = true; }
			}

			if (i == selectedPattern.pattern.length) { generate = true; }

			if (generate) {
				
				var text = new h2d.Text(Fonts.timer, roomPatternGraphic);
				text.setScale(0.75);
				text.text = '${currentCount}x ${currentKind}';
				text.y = dy;

				dy += 15;

				if (i < selectedPattern.pattern.length) {
					currentCount = 1;
					currentKind = selectedPattern.pattern[i].kind;
				}
			}

			i++;
		}

		

		updateScores();
	}

	private function toggleUpdate(status : Bool, text : h2d.Text) {
		if (status) { 
			text.text = "ENABLED";
			text.color = enabledColor; 
		}
		else { 
			text.text = "DISABLED";
			text.color = disabledColor; 
		}
	}

	public function updateGeneration(gen : game.GenerationState) {
		activeGeneration = gen;
	}

	public function resize(s : Float) {
		var window = hxd.Window.getInstance();
		
		background.clear();
		background.setColor(0x000000, 0.25);
		background.beginFill(0x000000, 0.25);
		background.drawRect(0,0,window.width, window.height);
		background.endFill();
		
		pauseText.setScale(0.5 * s);
		pauseText.x = window.width/2;
		pauseText.y = window.height/2 - pauseText.textHeight / 2 * s;

		restartText.setScale(0.5 * s);
		restartText.x = window.width/2;
		restartText.y = window.height/6 * 5 - restartText.textHeight / 2 * s;

		player1Box.x = window.width;
		player1Box.y = 10;

		player2Box.x = window.width;
		player2Box.y = 10 + 75;

		aiHumansBox.x = window.width;
		aiHumansBox.y = 10 * 2 + 75 * 2;

		roomController.x = window.width;
		roomController.y = 10 * 3 + 75 * 3;

		roomPattern.x = window.width - 200;
		roomPattern.y = 10;

		restartWithSettingsButton.x = window.width;
		restartWithSettingsButton.y = window.height;
	}
}