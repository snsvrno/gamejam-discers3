package sn;

class Timer {
	private var timeLimit : Float;
	public var timer(default,null) : Float = 0;
	private var callback : () -> Void;

	public function new(limit : Float, callback : () -> Void) {
		timeLimit = limit;
		this.callback = callback;
	}

	/**
	 * Updates the timer, and runs the callback if triggered.
	 * will return `true` if the timer has finished executing.
	 * @param dt 
	 * @return Bool
	 */
	public function update(dt : Float) : Bool {
		timer += dt;

		if (timeLimit <= timer) {
			timer = timeLimit;
			callback();
			return true;
		}

		return false;
	}

	/**
	 * Resets the timer so that it starts from zero again.
	 */
	public function reset() {
		
	}
}