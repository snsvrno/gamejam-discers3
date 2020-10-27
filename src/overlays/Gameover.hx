package overlays;

class Gameover extends h2d.Object {
	
	private var gameOverText : h2d.Text;
	private var restartText : h2d.Text;
	private var background : h2d.Graphics;

	public function new(?parent : h2d.Object) {
		super(parent);

		background = new h2d.Graphics(this);

		gameOverText = new h2d.Text(Fonts.title, this);
		gameOverText.text = "GAME OVER";
		gameOverText.textAlign = Center;
		gameOverText.dropShadow = { 
			dx : 2,
			dy : 3,
			color : 0x000000,
			alpha : 0.9,
		};

		restartText = new h2d.Text(Fonts.timer, this);
		restartText.text = "\"R\" to restart.\n\"C\" to select role.";
		restartText.textAlign = Center;
		restartText.dropShadow = { 
			dx : 0,
			dy : 2,
			color : 0x000000,
			alpha : 0.9,
		};

		alpha = 0;
	}

	public function resize(s : Float) {
		var window = hxd.Window.getInstance();
		
		background.clear();
		background.setColor(0x000000, 0.25);
		background.beginFill(0x000000, 0.25);
		background.drawRect(0,0,window.width, window.height);
		background.endFill();
		
		gameOverText.setScale(0.5 * s);
		gameOverText.x = window.width/2;
		gameOverText.y = window.height/2 - gameOverText.textHeight / 2 * s;

		restartText.setScale(0.5 * s);
		restartText.x = window.width/2;
		restartText.y = window.height/4 * 3 - restartText.textHeight / 2 * s;
	}
}