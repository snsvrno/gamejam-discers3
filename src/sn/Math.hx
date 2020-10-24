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
}