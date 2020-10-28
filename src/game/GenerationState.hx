package game;

typedef PatternInstruction = { 
	radius : Float, 
	kind : Data.BladesKind, 
	time : Float,
	rx : Float,
	ry : Float
};

typedef Score = {
	value : Float,
	ai : Bool,
}

typedef PatternSet = {
	hash : String,
	pattern : Array<PatternInstruction>,
	scores : Array<Score>,
	user : Bool,
}

class GenerationState {
	public var aiHumans : Int = 1;
	
	public var player1 : Bool = false;
	public var player2 : Bool = false;

	public var isRoomAPlayer : Bool = true;
	public var randomRoomPlacement : Bool = false;
	public var activePattern : Int = 0;
	public var patternSets : Array<PatternSet> = [ ];

	public function new() { }

	public static function generateHash() : String {
		var bank = "qwertyuiopasdfghjklzxcvbnmQAZXSWCDEVFRBGTNHYMJUKILOP";
		
		var hash : String = "";
	
		for (i in 0 ... 10) {
			var char = Math.floor(Math.random() * bank.length);
			hash += bank.substr(char,char);
		}
		return hash;
	}

	public static function generateTestPattern() : PatternSet {

		var list : Array<PatternInstruction> = [];

		var time : Float = 0;

		var blades : Array<Data.BladesKind> = [ ];
		for (a in Data.blades.all) {
			if (a.spawnable) { blades.push(a.name); }
		}

		#if debug
		// if we are in debug we're just going to make exactly 3 items
		for (i in 0 ... 3) {
		#else
		// normally we'll make a random pattern.
		for (i in 0 ...  2 + Math.ceil(Math.random() * 20)) {
		#end
				
			var rander = Math.floor(Math.random() * blades.length);
			var kind : Data.BladesKind = blades[rander];

			list.push({ 
				radius : 0.25 + Math.random() * 0.35, 
				rx : 0.15 + Math.random() * 0.70, 
				ry : 0.15 + Math.random() * 0.70, 
				kind : kind, 
				time : time, 
			});

			time += Math.random() * 2;
		}

		return {
			hash : generateHash(),
			scores : [ { value : 1.02, ai : true }, { value : 2.32, ai : false },],
			pattern : list,
			user : false,
		}
	}

	public static function parsePatternSets(string : String) : Array<game.PatternSet> {
		var list : Array<game.PatternSet> = [ ];

		var parsed = haxe.Json.parse(string);

		for (a in cast(parsed, Array<Dynamic>)) {
			list.push({
				hash : a.hash,
				scores : parseScores(a.scores),
				pattern : parsePattern(a.pattern),
				user : a.user,
			});
		}

		return list;
	}

	public static function parseScores(raw : Dynamic) : Array<Score> {
		var list : Array<Score> = [ ];

		for (a in cast(raw, Array<Dynamic>)) {
			list.push({
				value : a.value,
				ai : a.ai,
			});
		}

		return list;
	}

	public static function parsePattern(raw : Dynamic) : Array<PatternInstruction> {
		var list : Array<PatternInstruction> = [ ];

		for (a in cast(raw, Array<Dynamic>)) {
			var kind : Data.BladesKind = simple;

			// parsing KIND it smartly.
			for (bd in Data.blades.all) {
				if ('${bd.name}' == a.kind) { kind = bd.name; }
			}

			list.push({
				radius : a.radius,
				time : a.time,
				rx : a.rx,
				ry : a.ry,
				kind : kind,
			});
		}

		return list;
	}
}