package overlays;

class Pause extends h2d.Object {
	
	private var pauseText : h2d.Text;

	public function new(?parent : h2d.Object) {
		super(parent);
		
		pauseText = new h2d.Text(hxd.Res.fonts.choko.toFont(), this);
		pauseText.textAlign = Center;
		pauseText.text = "PAUSED";
		pauseText.dropShadow = { 
			dx : 6,
			dy : 6,
			color : 0x000000,
			alpha : 0.9,
		};
		
		alpha = 0;
	}

	public function resize(s : Float) {
		var window = hxd.Window.getInstance();
		
		pauseText.setScale(0.5 * s);
		pauseText.x = window.width/2;
		pauseText.y = window.height/2 - pauseText.textHeight / 2 * s;
	}
}