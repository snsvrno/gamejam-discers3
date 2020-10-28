class Main {
	public static function main() {

		var data : Null<String> = null;

		#if js
		var storage = js.Browser.getLocalStorage();
		data = storage.getItem("savedata");
		#end

		var game = new Game(data);
	}
}