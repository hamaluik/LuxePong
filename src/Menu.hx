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

class Menu extends State {
	var titleText:Text;
	var titleFont:BitmapFont;
	var titleShader:Shader;

	var menuItemShader:Shader;
	var hlMenuItemShader:Shader;

	var menuItems:StringMap<Text>;
	var currentSelection:String = '';

	public function new() {
		super({ name: 'menu' });
	}

	override function onenter<T>(_:T) {
		create_title();
		create_menu_items();
	}

	override function onleave<T>(_:T) {
		destroy_menu_items( );
		destroy_title();
	}

	function create_title() {
		// grab the custom font
		titleShader = Luxe.renderer.shaders.bitmapfont.shader.clone('menu-title-shader');
		titleFont = Luxe.resources.font('assets/fonts/digital7.fnt');

		// create the title text
		titleText = new Text({
			font: titleFont,
			text: 'Pong',
			depth: 1.5,
			align: center,
			align_vertical: center,
			point_size: 96,
			letter_spacing: 0,
			pos: new Vector(Luxe.screen.mid.x, Luxe.screen.mid.y - 178),
			color: new Color(1, 1, 1, 1),
			sdf: true
		});
	} // create_title

	function destroy_title() {
		titleText.destroy();
	} // destroy_title

	function create_menu_items() {
		menuItems = new StringMap<Text>();

		menuItemShader = Luxe.renderer.shaders.bitmapfont.shader.clone('menu-item-shader');

		menuItems.set('play', new Text({
			font: titleFont,
			text: 'Play!',
			shader: menuItemShader,
			depth: 2,
			align: center,
			align_vertical: center,
			point_size: 48,
			letter_spacing: 0,
			pos: new Vector( Luxe.screen.mid.x, Luxe.screen.mid.y - 32),
			color: new Color(1, 1, 1, 1),
			sdf: true
		}));

		menuItems.set('credits', new Text({
			font: titleFont,
			text: 'Credits',
			shader: menuItemShader,
			depth: 2,
			align: center,
			align_vertical: center,
			point_size: 48,
			letter_spacing: 0,
			pos: new Vector( Luxe.screen.mid.x, Luxe.screen.mid.y + 32),
			color: new Color(1, 1, 1, 1),
			sdf: true
		}));

	} // create_menu_items

	function destroy_menu_items() {
		for(item in menuItems.iterator())
			item.destroy();
	} // destroy_menu_items

	function select_item(item:String) {
		for(other in menuItems) {
			other.point_size = 48;
		}

		if(item != '') {
			menuItems.get(item).point_size = 64;
		}
		currentSelection = item;
	} // select_item

	override function onmousemove(e:MouseEvent) {
		for(item in menuItems.keys()) {
			if(menuItems.get(item).point_inside(e.pos) && currentSelection != item) {
				select_item(item);
			}
		}
	} // onmousemove

	override function onmouseup(e:MouseEvent) {
		if(currentSelection == '')
			return;

		Main.fsm.set(currentSelection);
	} // onmouseup
}