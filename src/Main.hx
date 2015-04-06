import luxe.Color;
import luxe.Input;
import luxe.ParcelProgress;
import luxe.Sprite;
import luxe.States;
import luxe.Text;
import luxe.Vector;
import phoenix.BitmapFont;
import luxe.States;

class Main extends luxe.Game {

	override function ready() {
		// load up the parcel
		Luxe.loadJSON("assets/parcel.json", function(parcelJSON) {
			var parcel = new luxe.Parcel();
			parcel.from_json(parcelJSON.json);

			// show a loading bar
			new ParcelProgress({
				parcel: parcel,
				background: new Color(0.15, 0.15, 0.15, 1),
				oncomplete: assetsLoaded
			});

			// load it!
			parcel.load();
		});
	} //ready

	public static var fsm:States;
	function assetsLoaded(_) {
		fsm = new States();
		fsm.add(new Menu());
		fsm.add(new Credits());
		fsm.add(new Play());
		fsm.set('play');
	} // assetsLoaded

} //Main