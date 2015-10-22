import haxe.ds.StringMap;
import luxe.Color;
import luxe.Input;
import luxe.ParcelProgress;
import luxe.Sprite;
import luxe.Text;
import luxe.Vector;
import phoenix.BitmapFont;
import luxe.States;
import phoenix.Shader;

class Credits extends State {
	var titleText:Text;
	var titleFont:BitmapFont;
	var titleShader:Shader;

	var creditsText:Text;

	public function new() {
		super({ name: 'credits' });
	}

	override function onenter<T>(_:T) {
		create_title();
		create_credits();
	}

	override function onleave<T>(_:T) {
		destroy_credits( );
		destroy_title();
	}

	function create_title() {
		// grab the custom font
		titleShader = Luxe.renderer.shaders.bitmapfont.shader.clone('credits-title-shader');
		titleFont = Luxe.resources.font('assets/fonts/digital7.fnt');

		// create the title text
		titleText = new Text({
			font: titleFont,
			text: 'Pong - Credits',
			depth: 1.5,
			align: center,
			align_vertical: center,
			point_size: 96,
			letter_spacing: 0,
			pos: new Vector(Luxe.screen.mid.x, Luxe.screen.mid.y - 178),
			color: new Color(1, 1, 1, 1),
			shader: titleShader,
			sdf: true
		});
	} // create_title

	function destroy_title() {
		titleText.destroy();
	} // destroy_title

	function create_credits() {
		creditsText = new Text({
			font: titleFont,
			text: 'Made by FuzzyWuzzie\n\nAs a learning excerise in Luxe\n\nClick to return',
			depth: 1.5,
			align: center,
			align_vertical: center,
			point_size: 48,
			letter_spacing: 0,
			pos: new Vector(Luxe.screen.mid.x, Luxe.screen.mid.y),
			color: new Color(1, 1, 1, 1),
			shader: titleShader,
			sdf: true
		});
	} // create_credits

	function destroy_credits() {
		creditsText.destroy();
	} // destroy_credits

	override function onmouseup(e:MouseEvent) {
		Main.fsm.set('menu');
	} // onmouseup
}