package overlays;

import h2d.Object;

class Sawgen extends h2d.Object {

	private static inline var PADDING : Float = 2;
	private static inline var ROTFACTOR : Float = 0.5;
	private static inline var SCROLLWAIT : Float = 0.1; // how many seconds to wait when scrolling before registering it.


	private var scaleFactor : Float;

	private var listOSaws : Array<{ kind : Data.BladesKind, image : h2d.Bitmap }> = [];
	private var selectedSaw : Int = 0;
	private var selectedImage : h2d.Object;
	private var selectedSawText : h2d.Text;

	private var drawCenter : { x : Float, y : Float };
	private var backgroundSprite : h2d.Bitmap;
	private var container : h2d.Object;

	private var timer : Float = 0;
	private var scrollWaitTimer : Float = 0;

	public var aiControlled(default, null) : Bool = false;
	private var randomPos : Bool = false;
	private var aiPatternPosition : Int = 0;
	private var aiPatternTimer : Float = 0;
	public var pattern : Array<game.GenerationState.PatternInstruction> = [];

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

		container = new h2d.Object(this);

		var tileSize = def.sprite.size;
		var t = hxd.Res.load(def.sprite.file).toTile();
		t = t.sub(def.sprite.x * tileSize, def.sprite.y * tileSize, tileSize, tileSize);
		backgroundSprite = new h2d.Bitmap(t, container);
		backgroundSprite.x = -t.width - PADDING;
		backgroundSprite.y = PADDING;

		selectedSawText = new h2d.Text(Fonts.timer, container);
		selectedSawText.textAlign = Center;
		selectedSawText.setScale(0.25);
		selectedSawText.dropShadow = { dx : 2, dy : 2, color: 0x000000, alpha: 0.85 };
		selectedSawText.x = - backgroundSprite.tile.width / 2 - PADDING;
		selectedSawText.y = backgroundSprite.tile.height + 2 * PADDING;
		
		selectedImage = new h2d.Object(container);
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

	public function setAiControl(pattern : Array<game.GenerationState.PatternInstruction>, randomGen : Bool) {
		this.pattern = pattern;
		aiControlled = true;
		randomPos = randomGen;

		container.alpha = 0;
	}

	public function setHumanControl() {
		aiControlled = false;
		this.pattern = [];
		container.alpha = 1;
	}

	public function changeSaw(direction : Float) {
		// has the scroll wait.
		if (scrollWaitTimer != 0) { return; }

		if (direction > 0) {
			if (selectedSaw < listOSaws.length - 1) { setSelected(selectedSaw + 1); }
			else { setSelected(0); }
		} else {
			if (selectedSaw == 0) { setSelected(listOSaws.length-1); }
			else { setSelected(selectedSaw - 1); }
		}
		scrollWaitTimer = SCROLLWAIT;
	}

	public function update(dt : Float, s : Float, edges : Game.Edges, layer : h2d.Object) : Null<game.Saw> {

		if (aiControlled) {

			aiPatternTimer += dt;

			if (pattern[aiPatternPosition].time <= aiPatternTimer) {
				// we make the saw!
				var instruction = pattern[aiPatternPosition];
				
				for (i in 0 ... listOSaws.length) {
					if (listOSaws[i].kind == instruction.kind) {
						selectedSaw = i;
						break;
					}
				}

				var sx;
				var sy;
				if (randomPos) {
					var angle = Math.random() * 2 * Math.PI;
					sx = Math.cos(angle) * instruction.radius * (edges.right - edges.left) + (edges.right - edges.left) / 2  + edges.left;
					sy = Math.sin(angle) * instruction.radius * (edges.top - edges.bottom) +  (edges.top - edges.bottom) / 2 + edges.bottom;
				} else {
					sx = instruction.rx * (edges.right - edges.left) + edges.left;
					sy = instruction.ry * (edges.top - edges.bottom) + edges.bottom;
				}

				var saw = createSaw(sx, sy, s, edges, layer);

				aiPatternPosition++;
				if (aiPatternPosition >= pattern.length) {
					aiPatternPosition = 0;
					aiPatternTimer = -1;
				}
				return saw;
			}


		} else {
			
			selectedImage.rotate(dt * ROTFACTOR);
			timer += dt;

			if (scrollWaitTimer != 0) { 
				scrollWaitTimer -= dt; 
				if (scrollWaitTimer < 0) {
					scrollWaitTimer = 0;
				}
			}
			
		}

		return null;

	}

	public function reset() {
		timer = 0;
	
		if (aiControlled == false) {
			pattern = [];
		}
	
		aiPatternPosition = 0;
		aiPatternTimer = 0;
		
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

			if (aiControlled == false) {
				// adds it to the pattern.
				var rx = (x - edges.left) / (edges.right - edges.left);
				var ry = (y - edges.bottom) / (edges.top - edges.bottom);
				var distance = sn.Math.distance(rx - 0.5, ry - 0.5);
				pattern.push({
					radius : distance,
					kind : sawKind,
					time : timer,
					rx : rx, ry : ry,
				});
			}

			return s;
		} else {
			return null;
		}
	}
}