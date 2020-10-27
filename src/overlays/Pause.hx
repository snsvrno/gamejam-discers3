package overlays;

class Pause extends h2d.Object {
	
	private var enabledColor : h3d.Vector = new h3d.Vector(0,1.0,0);
	private var disabledColor : h3d.Vector = new h3d.Vector(1.0,0,0);
	private var overColor : h3d.Vector = new h3d.Vector(0.70,0.7,1.0);
	private var outColor : h3d.Vector = new h3d.Vector(1.0,1.0,1.0);

	private var pauseText : h2d.Text;
	private var background : h2d.Graphics;
	private var restartText : h2d.Text;
	private var instructions : h2d.Text;

	private var title : h2d.Text;
	private var subtitle : h2d.Text;

	private var player1Box : h2d.Object;
	private var player1TextStatus : h2d.Text;

	private var player2Box : h2d.Object;
	private var player2TextStatus : h2d.Text;

	private var aiHumansBox : h2d.Object;
	private var aiHumansTextStatus : h2d.Text;

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

		title = new h2d.Text(Fonts.title, this);
		title.text = "Discers3";
		title.x = 10;
		title.dropShadow = { 
			dx : 0,
			dy : 2,
			color : 0x000000,
			alpha : 0.9,
		};

		subtitle = new h2d.Text(Fonts.title, this);
		subtitle.x = 10;
		subtitle.text = "the Disc is on the other hand now!";
		subtitle.dropShadow = { 
			dx : 0,
			dy : 2,
			color : 0x000000,
			alpha : 0.9,
		};

		instructions = new h2d.Text(Fonts.timer, this);
		instructions.text = "MOUSE Controls Saws\nMOUSEWHEEL to select saw\nCLICK to place.\n\nSPACE pauses\n\nW,A,S,D moves P1\nArrows moves P2";
		instructions.x = 10;
		instructions.dropShadow = { 
			dx : 0,
			dy : 2,
			color : 0x000000,
			alpha : 0.9,
		};

		restartText = new h2d.Text(Fonts.timer, this);
		restartText.text = "R to restart.\nC to select role.\nSPACE to unpause.";
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
		player1Text.x = -100;
		player1Text.y = 25;
		player1TextStatus = new h2d.Text(Fonts.timer, player1Box);
		player1TextStatus.text = "DISABLED";
		player1TextStatus.setScale(1);
		player1TextStatus.textAlign = Center;
		player1TextStatus.x = -100;
		player1TextStatus.y = 50;
		player1TextStatus.color = disabledColor;
		var interactive1 = new h2d.Interactive(200,100,player1Box);
		interactive1.x = -200;
		interactive1.onClick = function(e : hxd.Event) { 
			if (e.button == 0) {
				activeGeneration.player1 = !activeGeneration.player1;
				toggleUpdate(activeGeneration.player1, player1TextStatus);
			}
		}
		interactive1.onOver = function (e : hxd.Event) {
			player1Text.color = overColor;
		};
		interactive1.onOut = function (e : hxd.Event) {
			player1Text.color = outColor;
		};

		player2Box = new h2d.Object(this);
		var player2Text = new h2d.Text(Fonts.timer, player2Box);
		player2Text.text = "Player 2";
		player2Text.color = outColor;
		player2Text.setScale(1);
		player2Text.textAlign = Center;
		player2Text.x = -100;
		player2Text.y = 25;
		player2TextStatus = new h2d.Text(Fonts.timer, player2Box);
		player2TextStatus.text = "DISABLED";
		player2TextStatus.setScale(1);
		player2TextStatus.textAlign = Center;
		player2TextStatus.x = -100;
		player2TextStatus.y = 50;
		player2TextStatus.color = disabledColor;
		var interactive2 = new h2d.Interactive(200,100,player2Box);
		interactive2.x = -200;
		interactive2.onClick = function(e : hxd.Event) { 
			if (e.button == 0) {
				activeGeneration.player2 = !activeGeneration.player2;
				toggleUpdate(activeGeneration.player2, player2TextStatus);
			}
		}
		interactive2.onOver = function (e : hxd.Event) {
			player2Text.color = overColor;
		};
		interactive2.onOut = function (e : hxd.Event) {
			player2Text.color = outColor;
		};

		aiHumansBox = new h2d.Object(this);
		var aiHumansText = new h2d.Text(Fonts.timer, aiHumansBox);
		aiHumansText.text = "# of AI Humans";
		aiHumansText.color = outColor;
		aiHumansText.setScale(1);
		aiHumansText.textAlign = Center;
		aiHumansText.x = -100;
		aiHumansText.y = 25;
		aiHumansTextStatus = new h2d.Text(Fonts.timer, aiHumansBox);
		aiHumansTextStatus.text = '${activeGeneration.aiHumans}';
		aiHumansTextStatus.setScale(1);
		aiHumansTextStatus.textAlign = Center;
		aiHumansTextStatus.x = -100;
		aiHumansTextStatus.y = 50;
		var interactive3 = new h2d.Interactive(200,100,aiHumansBox);
		interactive3.enableRightButton = true;
		interactive3.x = -200;
		interactive3.onClick = function(e : hxd.Event) { 
			if (e.button == 0) { activeGeneration.aiHumans++; }
			else { activeGeneration.aiHumans--; }

			if (activeGeneration.aiHumans <= 0) { activeGeneration.aiHumans = 0; }
			aiHumansTextStatus.text = '${activeGeneration.aiHumans}';
		}
		interactive3.onOver = function (e : hxd.Event) {
			aiHumansText.color = overColor;
		};
		interactive3.onOut = function (e : hxd.Event) {
			aiHumansText.color = outColor;
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
	}

	/**
	 * Updates all parameters.
	 */
	public function updateAllValues() {
		aiHumansTextStatus.text = '${activeGeneration.aiHumans}';
		toggleUpdate(activeGeneration.player1, player1TextStatus);
		toggleUpdate(activeGeneration.player2, player2TextStatus);
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

		title.setScale(0.25 * s);
		subtitle.setScale(0.15 * s);
		subtitle.y = Fonts.title.lineHeight * title.scaleY - 10;
		instructions.setScale(0.25 * s);
		instructions.y = Fonts.title.lineHeight * (title.scaleY + subtitle.scaleY) + 60;

		player1Box.x = window.width;
		player1Box.y = window.height * 0.3;

		player2Box.x = window.width;
		player2Box.y = window.height * 0.3 + 100;

		aiHumansBox.x = window.width;
		aiHumansBox.y = window.height * 0.3 + 200;

		restartWithSettingsButton.x = window.width;
		restartWithSettingsButton.y = window.height;
	}
}