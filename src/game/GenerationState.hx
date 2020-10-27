package game;

typedef PatternInstruction = { radius : Float, kind : Data.BladesKind, time : Float };

class GenerationState {
	public var aiHumans : Int = 1;
	public var player1 : Bool = false;
	public var player2 : Bool = false;
	public var isRoomAPlayer : Bool = true;
	public var pattern : Array<PatternInstruction> = [];

	public function new() { }
}