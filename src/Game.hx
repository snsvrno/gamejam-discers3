import hxd.res.Font;

class Game extends hxd.App {
	////////////////////////////////////////////////////////////////////////////////////////
	// STATIC CONSTANTS
	
	/**
	 * The padding that the edge of the level has against the edge of the game
	 * container. This is inside the game world, so smaller screens will have
	 * less of a padding, so the relative should ook the same.
	 */
	private static inline var LEVELSCREENPADDING : Int = 10;

	/**
	 * Timer Text scale factor
	 */
	 private static inline var TIMERTEXTSCALEFACTOR : Float = 0.25;
	 
	////////////////////////////////////////////////////////////////////////////////////////
	// STATIC CONSTANTS
	private static var instance : Game;

	////////////////////////////////////////////////////////////////////////////////////////
	// UI RELATED OBJECTS
	private var uiLayer : h2d.Object;
	private var gameTimer : Float = 0;
	private var timerText : h2d.Text;

	////////////////////////////////////////////////////////////////////////////////////////
	// SAW RELATED OBJECTS

	private var saws : Array<game.Saw> = [];
	private var sawLayer : h2d.Object;

	////////////////////////////////////////////////////////////////////////////////////////
	// EFFECTS RELATED OBJECTS

	private var effects : Array<game.Effect> = [];
	private var effectsLayer : h2d.Object;

	////////////////////////////////////////////////////////////////////////////////////////
	// BACKGROUND RELATED ELEMENTS

	private var backgroundImage : h2d.Bitmap;
	private var backgroundDef : Data.Backdrops;
	/**
	 * The position of the edge of the world. 
	 * 
	 * for example `left : 10` means that the left edge is at `x = 10`, `right : 300` 
	 * means that the right edge is at `x = 300`.
	 */
	private var backgroundEdges : { left : Float, top : Float, right : Float, bottom : Float, } = { left : 0, right : 0, top : 0, bottom : 0 };

	////////////////////////////////////////////////////////////////////////////////////////
	// DEBUG STUFF

	#if debug
	private var debugOverlay : h2d.Object;
	private var debugBoundaryOverlay : h2d.Graphics;
	#end

	////////////////////////////////////////////////////////////////////////////////////////
	// STANDARD OBJECT FUNCTIONS

	override function init() {
		initalizeResources();

		super.init();
		instance = this;

		var window = hxd.Window.getInstance();
		window.addEventTarget(onEvent);

		#if debug
		debugOverlay = new h2d.Object();
		debugOverlay.alpha = 0;
		debugBoundaryOverlay = new h2d.Graphics(debugOverlay);
		#end

		engine.backgroundColor = 0x666666;

		loadBackgroundImage(level1);
		sawLayer = new h2d.Object(s2d);

		effectsLayer = new h2d.Object(s2d);

		#if debug
		s2d.addChild(debugOverlay);
		#end

		uiLayer = new h2d.Object(s2d);
		timerText = new h2d.Text(hxd.Res.fonts.choko.toFont(), uiLayer);
		timerText.text = "000.000";

		onResize(); // trigger all the sizing
	}

	override function update(dt : Float) {
		super.update(dt);

		gameTimer += dt;
		// formats the number for display.
		var numberText = '${Math.floor(gameTimer * 1000)/1000}';
		var preNumber = '${Math.floor(gameTimer)}';
		while(preNumber.length < 3) { preNumber = "0" + preNumber; }
		timerText.text = preNumber;
		timerText.text += ".";
		timerText.text += numberText.substr(numberText.length-3);

		removeSaws(); // checks and removes any saws that need to be removed.
		removeEffects(); // checks and removes any effects that need to be removed.

		// runs an update on the remaining saws.
		for (s in saws) {
			s.update(dt);
		}

		sawCollisions(); // check if saws hit walls.
	}

	override function onResize() {
		super.onResize();

		placeBackgroundImage(); // resize the background image and boundaries.
		resizeSaws(); // we need to resize and adjust the position of all actors
		resizeUi(); // resizes the UI;
	}

	function onEvent(event : hxd.Event) {
		switch(event.kind) {
			case EKeyDown:
				#if debug
				// if pressing `F1` then we toggle the overlay.
				if (event.keyCode == hxd.Key.F1) { 
					if (debugOverlay.alpha == 1) { debugOverlay.alpha = 0;} else { debugOverlay.alpha = 1;}
				}
				#end
			case EPush:
				createSaw(event.relX, event.relY);
			
			case _:
		}
	}
	////////////////////////////////////////////////////////////////////////////////////////
	// UI RELATED FUNCTIONS.

	private function resizeUi() {
		var window = hxd.Window.getInstance();

		timerText.setScale(TIMERTEXTSCALEFACTOR * backgroundImage.scaleX);
		timerText.x = window.width / 2 - timerText.calcTextWidth("000.000")/2 * backgroundImage.scaleX * TIMERTEXTSCALEFACTOR;
		timerText.y = 10; 
	}

	////////////////////////////////////////////////////////////////////////////////////////
	// SAW RELATED FUNCTIONS.

	/**
	 * We need to resize saws whenever we resize the world. we do everything based on the
	 * background.
	 */
	private function resizeSaws() {
		for (s in saws) {
			s.resize(backgroundImage.scaleX);
		}
	}

	private function createSaw(x : Float, y : Float) {

		var s = new game.Saw(base, x, y, backgroundImage.scaleX, sawLayer);
		s.setDirectionAngle(Math.random() * Math.PI * 2);
		saws.push(s);
	}

	/**
	 * Checks all saws, removes the ones that we don't need anymore.
	 */
	private function removeSaws() {
		var i = saws.length - 1;
		while(i >= 0) {
			if (saws[i].queueForDeletion) {
				sawLayer.removeChild(saws[i]);
				saws.remove(saws[i]);
			}
			i--;
		}
	}

	private function sawCollisions() {
		for (s in saws) { s.wallCollisionCheck(backgroundEdges); }
	}

	////////////////////////////////////////////////////////////////////////////////////////
	// EFFECTS RELATED FUNCTIONS.

	/**
	 * Checks all effects, removes the ones that we don't need anymore. 
	 */
	private function removeEffects() {
		var i = effects.length - 1;
		while(i >= 0) {
			if (effects[i].queueForDeletion) {
				effectsLayer.removeChild(effects[i]);
				effects.remove(effects[i]);
			}
			i--;
		}
	}

	public static function addEffect(effect : game.Effect) {
		effect.setScale(instance.backgroundImage.scaleX);
		instance.effects.push(effect);
		instance.effectsLayer.addChild(effect);
	}

	////////////////////////////////////////////////////////////////////////////////////////
	// BACKGROUND RELATED FUNCTIONS.

	/**
	 * Loads the background from the Data.cdb database. Creates the new data bitmap and triggers
	 * a resize / redefinition of the boundaries.
	 * 
	 * @param background 
	 */
	private function loadBackgroundImage(background : Data.BackdropsKind) {
		var def = Data.backdrops.get(background);
		backgroundDef = def;

		var t = hxd.Res.load(def.sprite.file).toTile();
		var size = def.sprite.size;

		t = t.sub(def.sprite.x * size, def.sprite.y * size, size, size);
		backgroundImage = new h2d.Bitmap(t, s2d);

		placeBackgroundImage();
	}

	/**
	 * Resizes and places the existing background image, as well as resets the edge boundaries
	 */
	private function placeBackgroundImage() {
		var window = hxd.Window.getInstance();

		var scaleX = window.width / (backgroundImage.tile.width + LEVELSCREENPADDING * 2);
		var scaleY = window.height / (backgroundImage.tile.height + LEVELSCREENPADDING * 2);
		var scale = Math.min(scaleX, scaleY);

		backgroundImage.setScale(scale);

		backgroundImage.x = (window.width - backgroundImage.tile.width * scale) / 2;
		backgroundImage.y = (window.height - backgroundImage.tile.height * scale) / 2;

		// need to redefine the boundaries.
		backgroundEdges.left = backgroundImage.x + backgroundDef.gameSpace.x * scale;
		backgroundEdges.top = backgroundImage.y + backgroundDef.gameSpace.y * scale;
		backgroundEdges.right = backgroundEdges.left + backgroundDef.gameSpace.w * scale;
		backgroundEdges.bottom = backgroundEdges.top + backgroundDef.gameSpace.h * scale;

		#if debug
		debugDrawBackgroundImageBoundary();
		#end
	}

	/**
	 * [**DEBUG FUNCTION**] used to draw the background boundary overlay.
	 */
	private function debugDrawBackgroundImageBoundary() {
		debugBoundaryOverlay.clear();

		// draws a rectangle for the gamespace.
		debugBoundaryOverlay.lineStyle(1,0x00FF00);
		debugBoundaryOverlay.beginFill(0x00FF00,0.25);
		debugBoundaryOverlay.drawRect(backgroundEdges.left, backgroundEdges.top, backgroundEdges.right - backgroundEdges.left, backgroundEdges.bottom - backgroundEdges.top);
		debugBoundaryOverlay.endFill();
	}

	////////////////////////////////////////////////////////////////////////////////////////
	// static initalizing functions.

	/**
	 * Loads the castledb file defined in `Data.hx`
	 */
	 static private function initalizeResources() : Void {
		// initalizes the resources.
		
		#if js
		hxd.Res.initEmbed();
		#else
		hxd.Res.initLocal();
		#end

		// loads the castledb resource file.
		Data.load(hxd.Res.data.entry.getText());
	}
}