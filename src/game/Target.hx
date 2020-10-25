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
			inactiveBitmap.alpha = 1;
		}
		{
			var tileSize = def.sprite.size;
			var t = hxd.Res.load(def.activeSprite.file).toTile();
			t = t.sub(def.activeSprite.x * tileSize, def.activeSprite.y * tileSize, tileSize, tileSize);
			activeBitmap = new h2d.Bitmap(t, this);
			activeBitmap.x = -t.width/2;
			activeBitmap.y = -t.height/2;
			activeBitmap.alpha = 0;
		}

		transitionTimer = new sn.Timer(TRANSITIONTIME, function() { transitioning = false; });

		this.x = x;
		this.y = y;
		setScale(baseScale * s);
	}

	public function update(dt : Float, humans : Array<game.Human>) {
		if (transitioning) {
			transitionTimer.update(dt);
			var factor = transitionTimer.timer / TRANSITIONTIME;

			if (transitioningToActive) {
				activeBitmap.alpha = factor;
				inactiveBitmap.alpha = 1 - factor;
			} else {
				activeBitmap.alpha = 1- factor;
				inactiveBitmap.alpha = factor;
			} 
		}

		for (h in humans) {
			if (bounds.width/2 * scaleX - x <= h.x && h.x <= bounds.width/2 * scaleX + x
				&& bounds.height/2 * scaleY - y <= h.y && h.y <= bounds.height/2 * scaleY + y) 
			{
				setActive(true);
				break;
			}
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