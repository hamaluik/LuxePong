import luxe.Color;
import luxe.Input;
import luxe.ParcelProgress;
import luxe.options.ParcelOptions;
import luxe.Parcel.ParcelChange;
import luxe.Sprite;
import luxe.States;
import luxe.Text;
import luxe.Vector;
import phoenix.BitmapFont;
import luxe.States;
import phoenix.Texture;
import luxe.resource.Resource;

class Main extends luxe.Game {

	override function ready() {
		var po:ParcelOptions = {
			onprogress: function(state:luxe.ParcelChange) {
			},
			onfailed: function(state:luxe.ParcelChange)
			{
			},
		 };
		Luxe.resources.load_json("assets/parcel.json").then(function(json:JSONResource) {
			var parcel = new luxe.Parcel(po);
			new ParcelProgress({
				parcel: parcel,
				background: new Color(0.15, 0.15, 0.15, 1),
				oncomplete: assetsLoaded
			});

			parcel.from_json(json.asset.json);
			parcel.load();
		});
	} //ready

	public static var fsm:States;
	function assetsLoaded(_) {
		fsm = new States();
		fsm.add(new Menu());
		fsm.add(new Credits());
		fsm.add(new Play());
		fsm.set('menu');
	} // assetsLoaded

} //Main