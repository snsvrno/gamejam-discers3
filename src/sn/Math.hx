package sn;

class Math {

	public static function distance(a : Float, b : Float) : Float {
		return std.Math.sqrt(std.Math.pow(a,2) + std.Math.pow(b,2));
	}

	public static function direction(x : Float, y : Float) : { x : Float, y : Float } {
		var distance = distance(x,y);
		
		return {
			x : x / distance, y : y / distance,
		};
	}

	public static function getAngle(x : Float, y : Float) : Float {
		var angle = std.Math.atan(y/x);

		if (x < 0 && y >= 0) {
			angle = std.Math.PI - angle;
		} else if (x < 0 && y < 0) {
			angle = std.Math.PI + angle;
		} else if (x >= 0 && y < 0) {
			angle = std.Math.PI * 2 - angle;
		}

		return angle;
	}

	public static function sign(a : Float) : Int {
		if (a > 0) {
			return 1;
		} else if (a < 0) {
			return -1;
		} else {
			return 0;
		}
	}
}