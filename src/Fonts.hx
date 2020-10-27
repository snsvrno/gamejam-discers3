class Fonts {

	private static var instance : Fonts;

	private var _normal : h2d.Font;
	private var _title : h2d.Font;
	private var _timer : h2d.Font;

	public static var normal(get, null) : h2d.Font;
	public static var title(get, null) : h2d.Font;
	public static var timer(get, null) : h2d.Font;

	private static function get_normal() { return instance._normal; }
	private static function get_title() { return instance._title; }
	private static function get_timer() { return instance._timer; }

	public function new() {
		_normal= hxd.Res.fonts.cokobi_16.toFont();
		_title = hxd.Res.fonts.cokobi_64.toFont();
		_timer = hxd.Res.fonts.cokobi_32.toFont();
	}

	public static function init() {
		instance = new Fonts();
	}
}