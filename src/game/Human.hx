package game;

class Human extends h2d.Object {

	private static inline var TARGETDEADBAND : Float = 20; 

	private var boundGrid : Game.Edges; // the bourd boundaries, used for scaling position when resizing.

	private var currentAnimation : String;

	// if the human is player controlled.
	private var movementMatrix : { u : Int, d : Int, l : Int, r : Int } = { u : 0, d : 0, l : 0, r : 0 };

	private var animations : Map<String, h2d.Anim> = new Map();
	private var avoidThesePoints : Array<{ x : Float, y : Float }> = [];
	private var targetPoint : Null<{x : Float, y : Float}> = null;

	/**
	 * The movement direction of the saw.
	 */
	private var direction : { x : Float, y : Float } = { x : 0, y : 0 };
	private var movementSpeed : Float;
	/**
	 * How far this player looks for threats.
	 */
	private var vision : Float;
	/**
	 * The radius for game objects, like humans.
	 */
	public var hitRadius(default, null) : Float;

	private var collisionRadius : Float;

	private var baseScale : Float;

	public var humanPlayer(default, null) : Bool = false;
	public var humanPlayerNumber(default, null) : Int;
	public var humanColor(default, null) : h3d.Vector;

	/**
	 * switch so we know we no longer want this piece around.
	 */
	public var queueForDeletion(default, null) : Bool = false;

	public function new(x : Float, y : Float, s : Float, type : Data.HumansKind, edges : Game.Edges, ?parent : h2d.Object) {
		super(parent);

		loadAnimations(type);
		var def = Data.humans.get(type);
		baseScale = def.scale;
		movementSpeed = def.speed;
		vision = def.radius.vision;
		collisionRadius = def.radius.wall;
		hitRadius = def.radius.fleshy;

		boundGrid = {
			left : edges.left,
			right : edges.right,
			top : edges.top,
			bottom : edges.bottom,
		};

		this.x = x;
		this.y = y;
		setScale(baseScale * s);
	}

	/**
	 * Makes the human controlable by a player.
	 */
	public function setPlayable(playerNumber : Int) {
		humanPlayer = true;
		humanPlayerNumber = playerNumber;
		humanColor = new h3d.Vector(Math.random(),Math.random(),Math.random());
		
		for (a in animations) {
			a.color = humanColor;
		}
	}

	public function onKeyPressed(key : Int) {
		if (humanPlayer == false) { return; }

		if (humanPlayerNumber == 1) {
			switch (key) {
				case hxd.Key.W: movementMatrix.u = 1;
				case hxd.Key.A: movementMatrix.l = 1;
				case hxd.Key.S: movementMatrix.d = 1;
				case hxd.Key.D: movementMatrix.r = 1;
				case _:
			}
		} else if (humanPlayerNumber == 2) {
			switch (key) {
				case hxd.Key.UP: movementMatrix.u = 1;
				case hxd.Key.LEFT: movementMatrix.l = 1;
				case hxd.Key.DOWN: movementMatrix.d = 1;
				case hxd.Key.RIGHT: movementMatrix.r = 1;
				case _:
			}
		}
	}

	public function onKeyReleased(key : Int) {
		if (humanPlayer == false) { return; }

		if (humanPlayerNumber == 1) {
			switch (key) {
				case hxd.Key.W: movementMatrix.u = 0;
				case hxd.Key.A: movementMatrix.l = 0;
				case hxd.Key.S: movementMatrix.d = 0;
				case hxd.Key.D: movementMatrix.r = 0;
				case _:
			}
		} else if (humanPlayerNumber == 2) {
			switch (key) {
				case hxd.Key.UP: movementMatrix.u = 0;
				case hxd.Key.LEFT: movementMatrix.l = 0;
				case hxd.Key.DOWN: movementMatrix.d = 0;
				case hxd.Key.RIGHT: movementMatrix.r = 0;
				case _:
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

	public function update(dt: Float) {

		if (humanPlayer) {

			direction.x = (movementMatrix.r - movementMatrix.l);
			direction.y = (movementMatrix.d - movementMatrix.u);

			if (direction.x != 0 && direction.y != 0) {
				// normalizing it.
				var distance = sn.Math.distance(direction.x, direction.y);
				direction.x /= distance;
				direction.y /= distance;
			}

		} else {

			if (avoidThesePoints.length == 0 && targetPoint != null) {
				var distance = sn.Math.distance(targetPoint.x - x, targetPoint.y -y);
				if (distance <= TARGETDEADBAND * scaleX) {
					setAnimation("idle");
					return;
				}
			}

			adjustDirection();
		}

		x += direction.x * movementSpeed * dt * scaleX;
		y += direction.y * movementSpeed * dt * scaleY;

		if (direction.x != 0 || direction.y != 0) {
			setAnimation("run");
		} else {
			setAnimation("idle");
		}
	}
	
	/**
	 * Used when the human is hit.
	 */
	public function hit() {
		queueForDeletion = true;
	}

	public function wallCollisionCheck(walls : { left : Float, top : Float, right : Float, bottom : Float}) {


		// checks the left and right sides for a collision
		if (direction.x < 0 && x - collisionRadius * scaleX <= walls.left) {
			x = walls.left + collisionRadius * scaleX;
		} else if (direction.x > 0 && x + collisionRadius * scaleX >= walls.right) {
			x = walls.right - collisionRadius * scaleX;
		}

		// checks the top and bottom sides for a collision.
		if (direction.y < 0 && y - collisionRadius * scaleY <= walls.top) {
			y = walls.top + collisionRadius * scaleY;
		} else if (direction.y > 0 && y + collisionRadius * scaleY >= walls.bottom) {
			y = walls.bottom - collisionRadius * scaleY;
		}
	}

	public function avoidPoint(x : Float, y : Float) {
		var distance = sn.Math.distance(x - this.x, y - this.y);
		if (distance <= vision * scaleX) {
			avoidThesePoints.push({ x : x, y : y });
		}
	}

	public function goToPoint(x : Float, y : Float) {
		targetPoint = { x : x, y : y };
	}

	/**
	 * Looks at the points to avoid and determines if it should change what
	 * direction its currently moving.
	 */
	private function adjustDirection() {

		var directions : Array<{x : Float, y : Float, weight : Float }> = [];

		while(avoidThesePoints.length > 0) {
			var point = avoidThesePoints.pop();
			var distance = sn.Math.distance(point.x - this.x, point.y - this.y);

			// direction away from the saw.
			var d = sn.Math.direction(x - point.x, y - point.y);
			directions.push({x : d.x, y : d.y, weight : distance / (vision * scaleX) });
		}

		if (targetPoint != null) {
			var d = sn.Math.direction(targetPoint.x - x, targetPoint.y - y);
			directions.push({x : d.x, y : d.y, weight: 1 / (vision * scaleX )});
		}

		if (directions.length > 0) {
			var directionX : Float = 0;
			var directionY : Float = 0;

			for (d in directions) {
				directionX += d.x * d.weight;
				directionY += d.y * d.weight;
			}

			var dist = sn.Math.distance(directionX, directionY);
			direction.x = directionX / dist;
			direction.y = directionY / dist;
		}

/*
		var count : Int = 0;
		var x : Float = 0;
		var y : Float = 0;

		while(avoidThesePoints.length > 0) {
			var point = avoidThesePoints.pop();
			var distance = sn.Math.distance(point.x - this.x, point.y - this.y);

			if (distance <= vision * scaleX) {
				x += point.x;
				y += point.y;
				count += 1;
			}
		}

		if (count > 0) {

			// the target point
			x = x / count;
			y = y / count;

			var newDirection = sn.Math.direction(this.x - x,this.y - y);
			direction.x = newDirection.x;
			direction.y = newDirection.y;
		} else {
			direction.x = 0;
			direction.y = 0;
		}*/
	}

	private function loadAnimations(actor : Data.HumansKind) : Void {
		var def = Data.humans.get(actor);

		for (a in def.animations) {
			var frames : Array<h2d.Tile> = [ ];
			for (f in a.frames) {
				var t = hxd.Res.load(f.frame.file).toTile();
				var tileSize = f.frame.size;
				t = t.sub(f.frame.x * tileSize, f.frame.y * tileSize, tileSize, tileSize);
				frames.push(t);
			}
	
			var newAnimation = new h2d.Anim(frames);
			// offsetting it so its centered when we move around the player object.
			newAnimation.x = - def.center.x;
			newAnimation.y = - def.center.y;

			newAnimation.color = new h3d.Vector(0,0,0);

			animations.set(a.name, newAnimation);
		}

		if (animations.get("idle") != null) { 
			setAnimation("idle"); 
		}
	}

	private function setAnimation(name : String) {
		
		// removes the current animation.
		if (currentAnimation != null) {
			this.removeChild(animations.get(currentAnimation));
		}

		// sets the new animation
		this.addChild(animations.get(name));
		currentAnimation = name;
	}

}