import luxe.Color;
import luxe.Input;
import luxe.ParcelProgress;
import luxe.Sprite;
import luxe.Text;
import luxe.Vector;
import phoenix.BitmapFont;

import snow.Debug.log;

class Main extends luxe.Game {
	var block:Sprite;

	var titleText:Text;
	var titleFont:BitmapFont;

	override function ready() {
		// load up the parcel
		Luxe.loadJSON("assets/parcel.json", function(parcelJSON) {
			var parcel = new luxe.Parcel();
			parcel.from_json(parcelJSON.json);

			// show a loading bar
			new ParcelProgress({
				parcel: parcel,
				background: new Color(1, 0, 0, 1),
				oncomplete: assetsLoaded
			});

			// load it!
			parcel.load();
		});
	} //ready

	function assetsLoaded(_) {
		createTitle();
		createBlock();
	} // assetsLoaded

	function createTitle() {
		log("Listing fonts:");
		for(fnt in Luxe.resources.fonts.keys()) {
			log("  " + fnt);
		}
		log("Done!");
		
		// grab the custom font
		titleFont = Luxe.resources.find_font('assets/font/montez/montez.fnt');
		log("Font is null: " + (titleFont == null));

		// create the title text
		titleText = new Text({
			font: titleFont,
			text: 'Pong',
			depth: 1.5,
			align: center,
			align_vertical: center,
			point_size: 96,
			letter_spacing: 0,
			pos: new Vector(Luxe.screen.mid.x, Luxe.screen.mid.y - 100),
			color: new Color().rgb(0xffffff),
		});
	} //createTitle

	function createBlock() {
		block = new Sprite({
			name: 'block',
			pos: Luxe.screen.mid,
			color: new Color().rgb(0xf94b04),
			size: new Vector(128, 128)
		});
	}

	override function onmousemove(event:MouseEvent) {
		block.pos = event.pos;
	}

} //Main

// Outputs:
/*
Input.hx:42:     i / input / Gamepads supported: true
LuxePong.js:1635 Core.hx:110:      i / luxe / version 1.0.0-alpha.1+781304b460
LuxePong.js:3587 Main.hx::40        i / main / Listing fonts:
LuxePong.js:3587 Main.hx::44        i / main / Done!
LuxePong.js:3587 Main.hx::48        i / main / Font is null: true
*/