enum GameState {
	Play; Pause; Done; PlayerSelect;
}

typedef Edges = { left : Float, top : Float, right : Float, bottom : Float };

class Game extends hxd.App {
	////////////////////////////////////////////////////////////////////////////////////////
	// STATIC CONSTANTS
	
	/**
	 * The padding that the edge of the level has against the edge of the game
	 * container. This is inside the game world, so smaller screens will have
	 * less of a padding, so the relative should ook the same.
	 */
	private static inline var LEVELSCREENPADDING : Int = 10;

	private static inline var VERSION : String = "GAMEJAMv5_2020.10.28";

	private static inline var SCORECOUNTLIMIT : Int = 6;

	/**
	 * Timer Text scale factor
	 */
	 private static inline var TIMERTEXTSCALEFACTOR : Float = 0.5;
	 
	////////////////////////////////////////////////////////////////////////////////////////
	// STATIC MEMBERS
	
	private static var instance : Game;
	public static function getOverallTime() : Float { return instance.gameTimer; }
	
	////////////////////////////////////////////////////////////////////////////////////////
	// GENERAL STUFF

	private var gameState : GameState;
	private var target : game.Target;
	private var lastGenerationState : game.GenerationState;
	private var loadstring : Null<String> = null; // the load string we get from the json.

	////////////////////////////////////////////////////////////////////////////////////////
	// UI RELATED OBJECTS
	
	private var uiLayer : h2d.Object;
	private var gameTimer : Float = 0;
	private var timerText : h2d.Text;
	private var currentScoreBoard : h2d.Object;

	private var sawgenOverlay : overlays.Sawgen;

	private var pauseLayer : overlays.Pause;
	private var gameOverLayer : overlays.Gameover;

	private var versionText : h2d.Text;

	////////////////////////////////////////////////////////////////////////////////////////
	// SAW RELATED OBJECTS

	private var saws : Array<game.Saw> = [];
	private var sawLayer : h2d.Object;

	////////////////////////////////////////////////////////////////////////////////////////
	// HUMAN RELATED OBJECTS

	private var humans : Array<game.Human> = [];
	private var humanLayer : h2d.Object;
	private var deadHumans : Array<{p1 : Bool, p2 : Bool, time : Float, color : h3d.Vector}> = [];

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
	private var backgroundEdges : Edges = { left : 0, right : 0, top : 0, bottom : 0 };

	////////////////////////////////////////////////////////////////////////////////////////
	// DEBUG STUFF

	#if debug
	private var debugOverlay : h2d.Object;
	private var debugBoundaryOverlay : h2d.Graphics;
	private var debugCollisionsOverlay : h2d.Graphics;
	#end

	////////////////////////////////////////////////////////////////////////////////////////
	// STANDARD OBJECT FUNCTIONS

	public function new(loadstring : Null<String>) {
		super();

		this.loadstring = loadstring;
	}

	override function init() {
		initalizeResources();

		lastGenerationState = new game.GenerationState();
		if (loadstring != null) {
			// parse it.
			var loadedSets = game.GenerationState.parsePatternSets(loadstring);
			lastGenerationState.patternSets = loadedSets;
		} else {
			// generate a few sample ones. 
			for (i in 0 ... 2) {
				lastGenerationState.patternSets.push(game.GenerationState.generateTestPattern()); 
			}
		}

		super.init();
		instance = this;

		var window = hxd.Window.getInstance();
		window.addEventTarget(onEvent);

		#if debug
		debugOverlay = new h2d.Object();
		debugOverlay.alpha = 0;
		debugBoundaryOverlay = new h2d.Graphics(debugOverlay);
		debugCollisionsOverlay = new h2d.Graphics(debugOverlay);
		#end

		engine.backgroundColor = 0x666666;

		loadBackgroundImage(level1);
		
		//var tp = getPointInsideLevel(game.Target.SPAWNBUFFER * backgroundImage.scaleX);
		var tp = { 
			x : (backgroundEdges.right - backgroundEdges.left) / 2 + backgroundEdges.left, 
			y : (backgroundEdges.top - backgroundEdges.bottom) / 2 + backgroundEdges.bottom,
		};
		target = new game.Target(tp.x, tp.y, backgroundImage.scaleX, backgroundEdges, s2d);
		humanLayer = new h2d.Object(s2d);
		sawLayer = new h2d.Object(s2d);
		effectsLayer = new h2d.Object(s2d);

		

		#if debug
		s2d.addChild(debugOverlay);
		#end

		uiLayer = new h2d.Object(s2d);
		sawgenOverlay = new overlays.Sawgen(uiLayer);
		timerText = new h2d.Text(Fonts.timer, uiLayer);
		timerText.text = "000.000";
		timerText.dropShadow = { dx : 0, dy : 2, color: 0x000000, alpha : 0.8 };
		pauseLayer = new overlays.Pause(lastGenerationState, s2d);
		gameOverLayer = new overlays.Gameover(s2d);
		currentScoreBoard = new h2d.Object(uiLayer);
		currentScoreBoard.x = 20;
		currentScoreBoard.y = 10;

		versionText = new h2d.Text(Fonts.timer, s2d);
		versionText.setScale(0.15 * backgroundImage.scaleX);
		versionText.text = "v" + VERSION;
		versionText.x = 10;
		versionText.alpha = 0.25;

		executeGeneration();
		changeGameState(Pause);

		onResize(); // trigger all the sizing
	}

	override function update(dt : Float) {
		super.update(dt);

		switch(gameState) {
			case Play:

				if (humans.length == 0) { changeGameState(Done); }

				var newSaw = sawgenOverlay.update(dt, backgroundImage.scaleX, backgroundEdges, sawLayer);
				if (newSaw != null) { saws.push(newSaw); }

				if (target.active) { 
					gameTimer += dt;
					// formats the number for display.
					var preNumber = '${Math.floor(gameTimer)}';
					var postNumber = '${Math.floor((Math.floor(gameTimer * 1000)/1000 - Math.floor(gameTimer))*1000)}';
					while(preNumber.length < 3) { preNumber = "0" + preNumber; }
					timerText.text = '$preNumber.$postNumber';
				}

				removeSaws(); // checks and removes any saws that need to be removed.
				removeEffects(); // checks and removes any effects that need to be removed.
				removeHumans(); // checks and removes any humans that need to be removed.

				for (s in saws) { s.update(dt); }
				sawCollisions(); // check if saws hit walls.

				humanAvoidsSaws(); // tells the humans where the saws are this frame.
				humanHumanCollisions();
				for (h in humans) { h.goToPoint(target.x, target.y); }
				for (h in humans) { h.update(dt); }
				humanCollisions();

				humanSawCollisions();

				target.update(dt, humans);


			case Pause:
				// check if we have an updated gamestate
				if (pauseLayer.newSettingsReady) {
					pauseLayer.newSettingsReady = false;
					restart();
				}

			case unknown:
				
		}
	}

	override function onResize() {
		super.onResize();

		var oldSizes = {
			left : backgroundEdges.left,
			top : backgroundEdges.top,
			right : backgroundEdges.right,
			bottom : backgroundEdges.bottom,
		};

		placeBackgroundImage(); // resize the background image and boundaries.
		resizeSaws(); // we need to resize and adjust the position of all actors
		resizeHumans(); // we need to resize all the humans.
		resizeUi(); // resizes the UI;
		target.resize(backgroundImage.scaleX, backgroundEdges);
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

				#if js
				if (event.keyCode == hxd.Key.QWERTY_TILDE) {
					var storage = js.Browser.getLocalStorage();
					storage.clear();
				}
				#end

				switch(event.keyCode) {
					case hxd.Key.SPACE:
						changeGameState(Pause);
					case hxd.Key.R:
						restart();
					case _:
				}

				if (gameState == Play) {
					for (h in humans) { h.onKeyPressed(event.keyCode); }
				}

				if (sawgenOverlay.aiControlled == false) {
					switch(event.keyCode) {
						case hxd.Key.QWERTY_MINUS | hxd.Key.NUMPAD_SUB:
							sawgenOverlay.changeSaw(-1);
						case hxd.Key.QWERTY_EQUALS | hxd.Key.NUMPAD_ADD:
							sawgenOverlay.changeSaw(1);
						case _:
					}
				}

			case EKeyUp:
				if (gameState == Play) {
					for (h in humans) { h.onKeyReleased(event.keyCode); }
				}

			case EPush:
				if (gameState == Play && sawgenOverlay.aiControlled == false) {
					var saw = sawgenOverlay.createSaw(event.relX, event.relY, backgroundImage.scaleX, backgroundEdges, sawLayer);
					if (saw != null) { saws.push(saw); }
				}
			
			case EWheel:
				if (gameState == Play) {
					sawgenOverlay.changeSaw(event.wheelDelta);
				}

			case _:
		}
	}

	private function executeGeneration() {
		
		// set the target position
		var tp = { 
			x : (backgroundEdges.right - backgroundEdges.left) / 2 + backgroundEdges.left, 
			y : (backgroundEdges.top - backgroundEdges.bottom) / 2 + backgroundEdges.bottom,
		};
		target.x = tp.x;
		target.y = tp.y;
		
		for (i in 0 ... lastGenerationState.aiHumans) {
			// create the ai humans.
			var p = getPointInsideLevel(32);
			humans.push(new game.Human(p.x, p.y, backgroundImage.scaleX, simple, backgroundEdges, humanLayer));
		}

		if (lastGenerationState.player1) {
			var p = getPointInsideLevel(32);
			var human = new game.Human(p.x, p.y, backgroundImage.scaleX, simple, backgroundEdges, humanLayer);
			human.setPlayable(1);
			humans.push(human);
			
		}

		if (lastGenerationState.player2) {
			var p = getPointInsideLevel(32);
			var human = new game.Human(p.x, p.y, backgroundImage.scaleX, simple, backgroundEdges, humanLayer);
			human.setPlayable(2);
			humans.push(human);

		}

		// gives ai the room
		if (lastGenerationState.isRoomAPlayer == false) {
			if (lastGenerationState.patternSets.length == 0) {
				sawgenOverlay.setHumanControl();
				lastGenerationState.isRoomAPlayer = true;
			} else {
				var activePattern = lastGenerationState.patternSets[lastGenerationState.activePattern];
				sawgenOverlay.setAiControl(activePattern.pattern, lastGenerationState.randomRoomPlacement);
			}
		} else {
			sawgenOverlay.setHumanControl();
		}

		changeGameState(Play);
	}

	private function changeGameState(newState : GameState) {
		#if debug
		trace(newState, gameState);
		#end
		if (gameState == null) { gameState = newState; return; }

		var oldState = gameState;

		// used to catch specific changes.
		switch([gameState, newState]) {
			case [Pause, Pause]: gameState = Play;

			case [_, _] : gameState = newState;
		}

		// do we need to do any thing specific leaving the state?
		switch(oldState) {
			case Pause: 
				pauseLayer.setVisible(false);
				sawgenOverlay.alpha = 1;

			case Done:
				
			case _:
		}

		// do we need to do any thing specific going into the state.?
		switch(gameState) {
			case Pause:
				pauseLayer.setVisible(true);
				sawgenOverlay.alpha = 0;
			case Done:
				gameOver();
			case _:
		}

	}

	/**
	 * Restarts the game.
	 */
	private function restart() {
		removeSaws(true);
		removeHumans(true);
		trace(humans.length);

		gameTimer = 0;
		timerText.text = "000.000";

		pauseLayer.setVisible(false);
		gameOverLayer.alpha = 0;

		//var tp = getPointInsideLevel(game.Target.SPAWNBUFFER * backgroundImage.scaleX);
		//target.x = tp.x;
		//target.y = tp.y;
		target.reset();

		sawgenOverlay.reset();

		deadHumans = [];
		currentScoreBoard.removeChildren();

		executeGeneration();
	}

	private function gameOver() {
		pauseLayer.setVisible(false);
		gameOverLayer.alpha = 1;

		var newScores : Array<game.GenerationState.Score> = [];

		for (s in deadHumans) {
			newScores.push({
				value : s.time,
				ai : s.p1 == true || s.p2 == true ? false : true,
			});
		}

		// checks if we were using a current pattern
		if (lastGenerationState.isRoomAPlayer == false) {
			var currentPattern = lastGenerationState.patternSets[lastGenerationState.activePattern];

			for (s in newScores) { currentPattern.scores.push(s); }
			
			haxe.ds.ArraySort.sort(currentPattern.scores, (a,b) -> sn.Math.sign(b.value-a.value));
			
			if (currentPattern.scores.length > SCORECOUNTLIMIT) {

				while(currentPattern.scores.length > SCORECOUNTLIMIT) {
					currentPattern.scores.pop();
				}
			}

		} else {
			// trims the scores if too many are stored.
			if (newScores.length > SCORECOUNTLIMIT) {
				haxe.ds.ArraySort.sort(newScores, (a,b) -> sn.Math.sign(b.value-a.value));

				while(newScores.length > SCORECOUNTLIMIT) {
					newScores.pop();
				}
			}

			// saves the current pattern and the current score.
			lastGenerationState.patternSets.push({
				hash : game.GenerationState.generateHash(),
				scores : newScores,
				pattern : sawgenOverlay.pattern,
				user : true,
			});

			// sets the active pattern to the one just made.
			lastGenerationState.activePattern = lastGenerationState.patternSets.length - 1;
		}

		saveData();
	}

	////////////////////////////////////////////////////////////////////////////////////////
	// UI RELATED FUNCTIONS.

	private function updateCurrentScoreboard() {
		currentScoreBoard.removeChildren();

		haxe.ds.ArraySort.sort(deadHumans, (a,b) -> sn.Math.sign(b.time - a.time));

		var y = 10;
		for (a in deadHumans) {
			var text = new h2d.Text(Fonts.timer, currentScoreBoard);
			text.y = y;
			text.color = a.color;
			text.text = '${Math.floor(a.time*1000)/1000}';
			text.dropShadow = { dx : 0, dy : 1, color : 0xFFFFFF, alpha: 0.7 };
			text.setScale(2);
			y += 45;
		}
	}

	private function resizeUi() {
		var window = hxd.Window.getInstance();

		timerText.setScale(TIMERTEXTSCALEFACTOR * backgroundImage.scaleX);
		timerText.x = window.width / 2 - timerText.calcTextWidth("000.000")/2 * backgroundImage.scaleX * TIMERTEXTSCALEFACTOR;
		timerText.y = 6; 

		pauseLayer.resize(backgroundImage.scaleX);
		gameOverLayer.resize(backgroundImage.scaleX);

		sawgenOverlay.resize(backgroundImage.scaleX);

		versionText.setScale(0.15 * backgroundImage.scaleX);
		versionText.y = window.height - versionText.font.lineHeight * versionText.scaleY - 3;
	}

	////////////////////////////////////////////////////////////////////////////////////////
	// SAW RELATED FUNCTIONS.

	/**
	 * We need to resize saws whenever we resize the world. we do everything based on the
	 * background.
	 */
	private function resizeSaws() {

		for (s in saws) {
			s.resize(backgroundImage.scaleX, backgroundEdges);
		}
	}

	/**
	 * Checks all saws, removes the ones that we don't need anymore.
	 */
	private function removeSaws(?forced : Bool = false) {
		var i = saws.length - 1;
		while(i >= 0) {
			if (saws[i].queueForDeletion || forced) {

				// skip adding new saws from destroying because
				// we are restarting the game.
				if(!forced) {
					for (ns in saws[i].newSaws) {
						sawLayer.addChild(ns);
						saws.push(ns);
					}
				}

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
	// HUMAN RELATED FUNCTIONS.

	private function humanSawCollisions() {
		for (s in saws) {
			if (s.state != Active) { continue; }

			for (h in humans) {
				var distance = sn.Math.distance(s.x-h.x,s.y-h.y);
				if (distance < h.hitRadius * h.scaleX + s.hitRadius * s.scaleX) {
					h.hit();
				}
			}
		}
	}

	/**
	 * making the human ai avoid each other.
	 */
	private function humanHumanCollisions() {
		for (i in 0 ... humans.length) {
			for (j in i+1 ... humans.length) {

				// only do this for AI.
				if (humans[i].humanPlayer) { continue; }

				var distance = sn.Math.distance(humans[i].x - humans[j].x, humans[i].y - humans[j].y);
				if (distance < humans[i].scaleX * game.Human.HUMANBUBBLE) {
					var d = sn.Math.direction(humans[j].x - humans[i].x, humans[j].y - humans[i].y);
					humans[i].x = humans[j].x + d.x * humans[i].scaleX * game.Human.HUMANBUBBLE;
					humans[i].y = humans[j].y + d.y * humans[i].scaleY * game.Human.HUMANBUBBLE;
				}

			}
		}
	}

	private function resizeHumans() {
		for (h in humans) {
			h.resize(backgroundImage.scaleX, backgroundEdges);
		}
	}

	private function humanAvoidsSaws() {
		for (h in humans) {
			for (s in saws) {
				if (s.state == Active) {
					h.avoidPoint(s.x, s.y);
				}
			}
		}
	}

	private function humanCollisions() {
		for (h in humans) { h.wallCollisionCheck(backgroundEdges); }
	}

	/**
	 * Checks all effects, removes the ones that we don't need anymore. 
	 */
	 private function removeHumans(?force : Bool = false) {
		var i = humans.length - 1;
		while(i >= 0) {
			if (humans[i].queueForDeletion || force) {

				if (force == false) {
					// if we are removing the human because they lost, we should save their score.
					
					var color = if (humans[i].humanPlayer) { humans[i].humanColor; } else { new h3d.Vector(1,1,1); }
					
					deadHumans.push({
						time : gameTimer,
						p1 : humans[i].humanPlayer && humans[i].humanPlayerNumber == 1 ? true : false,
						p2 : humans[i].humanPlayer && humans[i].humanPlayerNumber == 2 ? true : false,
						color : color,
					});

					updateCurrentScoreboard();
				}

				humanLayer.removeChild(humans[i]);
				humans.remove(humans[i]);
			}
			i--;
		}
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
	 * Gets a random point inside the level space, respects the padding from the wall edges
	 * (used when you want to place an object with a width and height and don't want it
	 * intersecting the walls)
	 * @param padding 
	 */
	private function getPointInsideLevel(padding : Float) : { x : Float, y : Float } {
		var width = backgroundEdges.right - backgroundEdges.left - padding * 2;
		var height = backgroundEdges.bottom - backgroundEdges.top - padding * 2;

		var x = backgroundEdges.left + padding + Math.random() * width;
		var y = backgroundEdges.top + padding + Math.random() * height;

		return {
			x : x, y : y,
		}
	}

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
		debugDrawCollisionBoxes();
		#end
	}

	#if debug

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

	/**
	 * [**DEBUG FUNCTION**] used to draw object collisions.
	 */
	private function debugDrawCollisionBoxes() {
		debugCollisionsOverlay.clear();

		debugCollisionsOverlay.lineStyle(1,0xFF0000);
		debugCollisionsOverlay.beginFill(0xFFFF00,0.25);
		for (s in saws) {
			debugCollisionsOverlay.drawCircle(s.x, s.y, s.hitRadius * s.scaleX);
		}
		for (h in humans) {
			debugCollisionsOverlay.drawCircle(h.x, h.y, h.hitRadius * h.scaleX);
		}
		debugCollisionsOverlay.endFill();

	}

	#end

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

		Fonts.init();

		// loads the castledb resource file.
		Data.load(hxd.Res.data.entry.getText());
	}

	private function saveData() {
		// we save all the data
		var stringify = haxe.Json.stringify(lastGenerationState.patternSets);

		#if js

		var storage = js.Browser.getLocalStorage();
		storage.setItem("savedata",stringify);	

		#else
		// how do we save this if we aren't in javascript???

		#end
	}
}