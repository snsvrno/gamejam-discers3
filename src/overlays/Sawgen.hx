package overlays;

class Sawgen extends h2d.Object {

	private static inline var PADDING : Float = 2;
	private static inline var ROTFACTOR : Float = 0.5;

	private var scaleFactor : Float;

	private var listOSaws : Array<{ kind : Data.BladesKind, image : h2d.Bitmap }> = [];
	private var selectedSaw : Int = 0;
	private var selectedImage : h2d.Object;

	private var drawCenter : { x : Float, y : Float };
	private var backgroundSprite : h2d.Bitmap;

	public function new(?parent : h2d.Object) {
		super(parent);

		for (b in Data.blades.all) {
			var tileSize = b.sprite.size;
			var t = hxd.Res.load(b.sprite.file).toTile();
			t = t.sub(b.sprite.x * tileSize, b.sprite.y * tileSize, tileSize, tileSize);

			var image = new h2d.Bitmap(t);
			image.x = -t.width/2;
			image.y = -t.height/2;

			listOSaws.push({
				kind : b.name,
				image : image,
			});
		}

		// builds the available saw kinds.

		var def = Data.misc.get(mouseoverlay);

		scaleFactor = def.scale;

		var tileSize = def.sprite.size;
		var t = hxd.Res.load(def.sprite.file).toTile();
		t = t.sub(def.sprite.x * tileSize, def.sprite.y * tileSize, tileSize, tileSize);
		backgroundSprite = new h2d.Bitmap(t, this);
		backgroundSprite.x = -t.width - PADDING;
		backgroundSprite.y = PADDING;

		selectedImage = new h2d.Object(this);
		selectedImage.x = - backgroundSprite.tile.width / 2 - PADDING;
		selectedImage.y = backgroundSprite.tile.height / 2 + PADDING;

		setSelected(0);
	}

	private function setSelected(index : Int) {
		selectedImage.removeChildren();
		selectedSaw = index;
		selectedImage.addChild(listOSaws[selectedSaw].image);

	}

	public function changeSaw(direction : Float) {
		if (direction > 0) {
			if (selectedSaw < listOSaws.length - 1) { setSelected(selectedSaw + 1); }
			else { setSelected(0); }
		} else {
			if (selectedSaw == 0) { setSelected(listOSaws.length-1); }
			else { setSelected(selectedSaw - 1); }
		}
	}

	public function update(dt : Float) {
		selectedImage.rotate(dt * ROTFACTOR);
	}

	public function resize(s : Float) {
		var window = hxd.Window.getInstance();
		setScale(s * scaleFactor);
		x = window.width;

	}

	public function createSaw(x : Float, y : Float, s : Float, edges : Game.Edges, layer : h2d.Object) : Null<game.Saw> {

		if (edges.left <= x && x <= edges.right && edges.top <= y && y <= edges.bottom) {
			var s = new game.Saw(listOSaws[selectedSaw].kind, x, y, s, edges, layer);
			s.setDirectionAngle(Math.random() * Math.PI * 2);
			return s;
		} else {
			return null;
		}
	}
}