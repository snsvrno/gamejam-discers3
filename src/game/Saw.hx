package game;

enum State {
	SpawnWait; Active;
}

enum Wall { 
	Left; Top; Right; Bottom;
}

class Saw extends h2d.Object {

	/**
	 * The period of time where the saw is inactive, and doesn't do anything.
	 */
	private var spawnWait : Float;
	/**
	 * The alpha value immediately at spawn.
	 */
	private var spawnTransparency : Float;
	

	// the world height and width, so we can properly scare the objects
	// coordinates when resizing.
	private var boundGrid : Game.Edges;

	/**
	 * Rotational speed of the saw.
	 */
	private var rotationSpeed : Float;

	/**
	 * The base scale value that is used when resizing this saw item.
	 */
	private var baseScale : Float;

	/**
	 * The variance that happens when a wall hit occurs. Is a scalar for the 
	 * random angle that is added, so between `0.0` and `1.0`
	 */
	private var collisionRandomness : Float;

	/**
	 * The state of the saw. Always starts in `SpawnWait` which is the
	 * point where it stays still and counts down before it starts moving.
	 */
	public var state(default, null) : State = SpawnWait;

	/**
	 * The basic image.
	 */
	private var sprite : h2d.Bitmap;

	/**
	 * A list of timers for this saw. Helps control special timed behaviors.
	 */
	private var timerQue : Array<sn.Timer> = [];

	/**
	 * The movement direction of the saw.
	 */
	private var direction : { x : Float, y : Float } = { x : 0, y : 0 };
	private var movementSpeed : Float;

	/**
	 * The radius when bouncing and stuff, not for game objects
	 */
	private var collisionRadius : Float;
	/**
	 * The radius for game objects, like humans.
	 */
	public var hitRadius(default, null) : Float;
	/**
	 * What kind of behavior does this saw do when it hits a wall.
	 */
	private var wallCollisionBehavior : Data.WallCollision;
	/**
	 * What kind of behavior does this saw normally do when it moves.
	 */
	private var movementBehavior : Data.MovementBehavior;

	/**
	 * switch so we know we no longer want this piece around.
	 */
	public var queueForDeletion(default, null) : Bool = false;

	public function new(type : Data.BladesKind, x : Float, y : Float, s : Float, edges  : Game.Edges, ?parent : h2d.Object) {
		super(parent);

		// loads the blade definition from the `cdb`
		var def = Data.blades.get(type);
		// sets the collsion radius
		collisionRadius = def.collision.walls;
		hitRadius = def.collision.fleshy;
		collisionRandomness = def.collision.randomness;
		baseScale = def.scale;
		movementSpeed = def.speeds.move;
		rotationSpeed = def.speeds.rotation;
		spawnWait = def.spawn.wait;
		spawnTransparency = def.spawn.transparency;
		wallCollisionBehavior = def.behavior.wallCollision;
		movementBehavior = def.behavior.movement;

		boundGrid = {
			left : edges.left,
			right : edges.right,
			top : edges.top,
			bottom : edges.bottom,
		};

		this.x = x;
		this.y = y;
		setScale(baseScale * s);

		// loads the sprite to use.
		var tileSize = def.sprite.size;
		var t = hxd.Res.load(def.sprite.file).toTile();
		t = t.sub(def.sprite.x * tileSize, def.sprite.y * tileSize, tileSize, tileSize);
		sprite = new h2d.Bitmap(t, this);
		sprite.x = -t.width/2;
		sprite.y = -t.height/2;

		setSpawnState();
		timerQue.push(new sn.Timer(spawnWait, leaveSpawnState));
	}

	public function update(dt : Float) {

		if (state == Active) {
			// rotate the saw
			this.rotate(dt * rotationSpeed);

			// moves the saw based on the behavior defined.
			switch (movementBehavior) {
				case Straight:
					x += direction.x * movementSpeed * dt * scaleX;
					y += direction.y * movementSpeed * dt * scaleY;

				case unknown:
					trace('unplemented movement behavior $unknown');
			}

		}

		// works on the timer que if there are any timers.
		var i = timerQue.length - 1;
		while (i >= 0) {
			if (timerQue[i].update(dt)) {
				timerQue.remove(timerQue[i]);
			}
			i--;
		}
	}

	/**
	 * Sets the direction using `x` and `y`. it will normalize
	 * the inputs.
	 * @param x 
	 * @param y 
	 */
	public function setDirection(x : Float, y : Float) {
		var length = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2));

		direction.x = x / length;
		direction.y = y / length;
	}

	/**
	 * Sets the direction using an angle.
	 * @param angle 
	 */
	public function setDirectionAngle(angle : Float) {
		var x = Math.cos(angle);
		var y = Math.sin(angle);

		setDirection(x,y);
	}

	/**
	 * Resizes the position and scale of this object based on the 
	 * scale factor of the background (passed in).
	 * @param factor 
	 */
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

	public function wallCollisionCheck(walls : { left : Float, top : Float, right : Float, bottom : Float}) {

		var impact : Null<Wall> = null;
		var point : Null<{ x : Float, y : Float }> = null;

		// checks the left and right sides for a collision
		if (direction.x < 0 && x - collisionRadius * scaleX <= walls.left) {
			impact = Left;
			point = { x : walls.left, y : y };
		} else if (direction.x > 0 && x + collisionRadius * scaleX >= walls.right) {
			impact = Right;
			point = { x : walls.right, y : y };
		}

		// checks the top and bottom sides for a collision.
		if (direction.y < 0 && y - collisionRadius * scaleY <= walls.top) {
			impact = Top;
			point = { x : x, y : walls.top };
		} else if (direction.y > 0 && y + collisionRadius * scaleY >= walls.bottom) {
			impact = Bottom;
			point = { x : x, y : walls.bottom };
		}

		if (impact != null && point != null) {

			var effect = new game.Effect(point.x, point.y, sparks);
			Game.addEffect(effect);

			// if we have a wall collision lets check what kind of behavior we should do.
			switch(wallCollisionBehavior) {
				case Bounce: wallCollisionBounce(impact);
				case Dispose: wallCollisionDispose(impact);
				case unknown:
					trace('unhandled wall collision behavior: $unknown');
			}
		}
	}

	/**
	 * A basic bouncing wall behaviour, mirrors the direction opposite of the impact
	 * to look like a bounce. Also applies a random spin if set.
	 * @param wall 
	 */
	private function wallCollisionBounce(wall : Wall) {
		switch(wall) {
			case Left | Right:
				direction.x *= -1;
			case Top | Bottom:
				direction.y *= -1;
		}

		addRandomSpin();
	}

	/**
	 * Destroys the saw on the collision.
	 * @param wall 
	 */
	private function wallCollisionDispose(wall : Wall) {
		this.queueForDeletion = true;
	}

	private function addRandomSpin() {
		// generates a random angle to give the bounce a little more interest.
		var randomAngle = Math.random() * Math.PI * 2;
		var ax = Math.cos(randomAngle) * collisionRandomness;
		var ay = Math.sin(randomAngle) * collisionRandomness;
		direction.x += ax;
		direction.y += ay;

		// normalizes the angle.
		var length = Math.sqrt(Math.pow(direction.x, 2) + Math.pow(direction.y, 2));
		direction.x /= length;
		direction.y /= length;
	}

	private function setSpawnState() {
		state = SpawnWait;
		alpha = spawnTransparency;
	}

	private function leaveSpawnState() {
		state = Active;
		alpha = 1;
	}
}