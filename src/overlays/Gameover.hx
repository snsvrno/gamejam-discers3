package overlays;

class Gameover extends h2d.Object {
	
	private var gameOverText : h2d.Text;

	public function new(?parent : h2d.Object) {
		super(parent);

		gameOverText = new h2d.Text(hxd.Res.fonts.choko.toFont(), this);
		gameOverText.text = "GAME OVER";
		gameOverText.textAlign = Center;
		gameOverText.dropShadow = { 
			dx : 6,
			dy : 6,
			color : 0x000000,
			alpha : 0.9,
		};

		alpha = 0;
	}

	public function resize(s : Float) {
		var window = hxd.Window.getInstance();
		
		gameOverText.setScale(0.5 * s);
		gameOverText.x = window.width/2;
		gameOverText.y = window.height/2 - gameOverText.textHeight / 2 * s;
	}
}