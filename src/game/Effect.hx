package game;

class Effect extends h2d.Object {

	private static var ANIMATIONSPEED : Float = 15.0;

	private var animationBehavior : Data.Effects_behavior;
	private var animation : h2d.Anim;

	public var queueForDeletion(default, null) : Bool = false;

	public function new(x : Float, y : Float, type : Data.EffectsKind, ?parent : h2d.Object) {
		super(parent);

		var def = Data.effects.get(type);

		var animationTiles : Array<h2d.Tile> = [];
		for (a in def.animation) {
			var tileSize = a.frame.size;

			var t = hxd.Res.load(a.frame.file).toTile();
			t = t.sub(a.frame.x * tileSize, a.frame.y * tileSize, tileSize, tileSize);

			animationTiles.push(t);
		}

		animation = new h2d.Anim(animationTiles, ANIMATIONSPEED, this);
		animation.x = - def.center.x;
		animation.y = - def.center.y;
		
		switch(def.behavior) {
			case Once:
				animation.loop = false;
				animation.onAnimEnd = destroy;
			case Repeat:
				animation.loop = true;
			case PingPong:
				animation.loop = true;
		}

		this.x = x;
		this.y = y;
	}

	private function destroy() : Void {
		queueForDeletion = true;
	}
}