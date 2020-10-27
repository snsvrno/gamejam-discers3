package overlays;

class Sawgen extends h2d.Object {

	private static inline var PADDING : Float = 2;
	private static inline var ROTFACTOR : Float = 0.5;

	private var scaleFactor : Float;

	private var listOSaws : Array<{ kind : Data.BladesKind, image : h2d.Bitmap }> = [];
	private var selectedSaw : Int = 0;
	private var selectedImage : h2d.Object;
	private var selectedSawText : h2d.Text;

	private var drawCenter : { x : Float, y : Float };
	private var backgroundSprite : h2d.Bitmap;

	private var timer : Float = 0;
	private var pattern : Array<game.GenerationState.PatternInstruction> = [];

	public function new(?parent : h2d.Object) {
		super(parent);

		for (b in Data.blades.all) {

			// skip ones that shouldn't be selectable.
			if (!b.spawnable) { continue; }

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

		selectedSawText = new h2d.Text(Fonts.timer, this);
		selectedSawText.textAlign = Center;
		selectedSawText.setScale(0.25);
		selectedSawText.dropShadow = { dx : 2, dy : 2, color: 0x000000, alpha: 0.85 };
		selectedSawText.x = - backgroundSprite.tile.width / 2 - PADDING;
		selectedSawText.y = backgroundSprite.tile.height + 2 * PADDING;
		
		selectedImage = new h2d.Object(this);
		selectedImage.x = - backgroundSprite.tile.width / 2 - PADDING;
		selectedImage.y = backgroundSprite.tile.height / 2 + PADDING;

		setSelected(0);
	}

	private function setSelected(index : Int) {
		selectedImage.removeChildren();
		selectedSaw = index;
		selectedImage.addChild(listOSaws[selectedSaw].image);
		selectedSawText.text = Data.blades.get(listOSaws[selectedSaw].kind).description;

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
		timer += dt;
	}

	public function reset() {
		timer = 0;
		while (pattern.length > 0) {
			pattern.pop();
		}
	}

	public function resize(s : Float) {
		var window = hxd.Window.getInstance();
		setScale(s * scaleFactor);
		x = window.width;
	}

	public function createSaw(x : Float, y : Float, s : Float, edges : Game.Edges, layer : h2d.Object) : Null<game.Saw> {

		if (edges.left <= x && x <= edges.right && edges.top <= y && y <= edges.bottom) {
			var sawKind = listOSaws[selectedSaw].kind;
			var s = new game.Saw(sawKind, x, y, s, edges, layer);
			s.setDirectionAngle(Math.random() * Math.PI * 2);


			// adds it to the pattern.
			var rx = (x - edges.left) / (edges.right - edges.left);
			var ry = (x - edges.top) / (edges.top - edges.bottom);
			var distance = sn.Math.distance(rx - 0.5, ry - 0.5);
			pattern.push({
				radius : distance,
				kind : sawKind,
				time : timer,
			});

			return s;
		} else {
			return null;
		}
	}
}