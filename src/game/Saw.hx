package game;

enum State {
	SpawnWait; Active;
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
	private var worldW : Float;
	private var worldH : Float;

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
	private var state : State = SpawnWait;

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
	private var hitRadius : Float;

	public function new(type : Data.BladesKind, x : Float, y : Float, s : Float, ?parent : h2d.Object) {
		super(parent);

		// loads the blade definition from the `cdb`
		var def = Data.blades.get(type);
		// sets the collsion radius
		collisionRadius = def.radius.walls;
		collisionRandomness = def.collisionRandomness;
		baseScale = def.scale;
		movementSpeed = def.movementSpeed;
		rotationSpeed = def.rotationalSpeed;
		spawnWait = def.spawn.wait;
		spawnTransparency = def.spawn.transparency;

		var window = hxd.Window.getInstance();
		worldW = window.width;
		worldH = window.height;

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

			// moves the saw. (need to account for the scale)
			x += direction.x * movementSpeed * dt * scaleX;
			y += direction.y * movementSpeed * dt * scaleY;
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
	public function resize(factor : Float) {
		// changes the visual scale.
		setScale(baseScale * factor);

		// reshifts its position in the world, using ratios.
		var window = hxd.Window.getInstance();
		x = x / worldW * window.width;
		y = y / worldH * window.height;
		worldW = window.width;
		worldH = window.height;
	}

	public function wallCollisionCheck(walls : { left : Float, top : Float, right : Float, bottom : Float}) {

		if (direction.x < 0 && x - collisionRadius * scaleX <= walls.left) {
			direction.x *= -1;
			addRandomSpin();

		} else if (direction.x > 0 && x + collisionRadius * scaleX >= walls.right) {
			direction.x *= -1;
			addRandomSpin();
		}

		if (direction.y < 0 && y - collisionRadius * scaleY <= walls.top) {
			direction.y *= -1;
			addRandomSpin();
		} else if (direction.y > 0 && y + collisionRadius * scaleY >= walls.bottom) {
			direction.y *= -1;
			addRandomSpin();
		}


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