package game;

class Target extends h2d.Object {
	// distance from the edges of the map.
	public static inline var SPAWNBUFFER : Float = 100;
	/**
	 * The length of the transition event.
	 */
	private static inline var TRANSITIONTIME : Float = 0.5;

	
	private var boundGrid : Game.Edges; // the bourd boundaries, used for scaling position when resizing.

	private var inactiveBitmap : h2d.Bitmap;
	private var activeBitmap : h2d.Bitmap;

	private var baseScale : Float = 1;

	private var transitionTimer : sn.Timer;
	private var transitioning : Bool = false;
	private var transitioningToActive : Bool = false;

	private var bounds : { height : Float, width : Float,}; 

	public var active(get, null) : Bool;
	private function get_active() : Bool { return activeBitmap.alpha != 0 && transitioningToActive == true; }

	public function new(x : Float, y : Float, s : Float, edges : Game.Edges, ?parent : h2d.Object) {
		super(parent);
		
		boundGrid = {
			left : edges.left,
			right : edges.right,
			top : edges.top,
			bottom : edges.bottom,
		};

		var def = Data.target.get(main);
		bounds = {
			width : def.area.w,
			height : def.area.h,
		};

		{
			var tileSize = def.sprite.size;
			var t = hxd.Res.load(def.sprite.file).toTile();
			t = t.sub(def.sprite.x * tileSize, def.sprite.y * tileSize, tileSize, tileSize);
			inactiveBitmap = new h2d.Bitmap(t, this);
			inactiveBitmap.x = -t.width/2;
			inactiveBitmap.y = -t.height/2;
		}
		{
			var tileSize = def.sprite.size;
			var t = hxd.Res.load(def.activeSprite.file).toTile();
			t = t.sub(def.activeSprite.x * tileSize, def.activeSprite.y * tileSize, tileSize, tileSize);
			activeBitmap = new h2d.Bitmap(t, this);
			activeBitmap.x = -t.width/2;
			activeBitmap.y = -t.height/2;
		}

		transitionTimer = new sn.Timer(TRANSITIONTIME, function() { transitioning = false; });

		this.x = x;
		this.y = y;
		setScale(baseScale * s);

		reset();
	}

	public function update(dt : Float, humans : Array<game.Human>) {
		if (transitioning) {
			// updates the timer, which stops the transition effect.
			transitionTimer.update(dt);

			// fades between the two images.
			var factor = transitionTimer.timer / TRANSITIONTIME;
			if (transitioningToActive) {
				activeBitmap.alpha = factor;
				inactiveBitmap.alpha = 1 - factor;
			} else {
				activeBitmap.alpha = 1 - factor;
				inactiveBitmap.alpha = factor;
			}
		}

		// checks each human to see if we should keep it active.
		var shouldBeActive = false;
		for (h in humans) {
			if (bounds.width/2 * scaleX - x <= h.x && h.x <= bounds.width/2 * scaleX + x
				&& bounds.height/2 * scaleY - y <= h.y && h.y <= bounds.height/2 * scaleY + y) 
			{
				setActive(true);
				shouldBeActive = true;
				break;
			}
		}

		if (!shouldBeActive) {
			setActive(false);
		}
	}

	public function resize(s : Float, edges : Game.Edges) {
		// changes the visual scale.
		setScale(baseScale * s);

		var rx = (x - boundGrid.left) / (boundGrid.right - boundGrid.left);
		var ry = (y - boundGrid.top) / (boundGrid.bottom - boundGrid.top);

		x = rx * (edges.right - edges.left) + edges.left;
		y = ry * (edges.bottom - edges.top) + edges.top;

		boundGrid.left = edges.left;
		boundGrid.right = edges.right;
		boundGrid.bottom = edges.bottom;
		boundGrid.top = edges.top;
	}

	public function reset() {
		inactiveBitmap.alpha = 1;
		activeBitmap.alpha = 0;
		transitioning = false;
		transitioningToActive = false;
		transitionTimer.reset();
	}

	private function setActive(status : Bool) {
		if (status && inactiveBitmap.alpha == 1) {
			transitioning = true;
			transitionTimer.reset();
			transitioningToActive = true;
		} else if (status == false && activeBitmap.alpha == 1) {
			transitioning = true;
			transitionTimer.reset();
			transitioningToActive = false;
		}
	}
}