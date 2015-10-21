import haxe.ds.StringMap;
import luxe.Audio;
import luxe.collision.Collision;
import luxe.collision.shapes.Circle;
import luxe.collision.shapes.Polygon;
import luxe.Color;
import luxe.Component;
import luxe.Entity;
import luxe.Input;
import luxe.ParcelProgress;
import luxe.Rectangle;
import luxe.Sprite;
import luxe.Text;
import luxe.Vector;
import luxe.Visual;
import phoenix.BitmapFont;
import luxe.States;
import phoenix.Shader;
import phoenix.geometry.CircleGeometry;
import phoenix.Texture;
import luxe.collision.shapes.Shape;

class GameEntity extends Sprite {
	public var v:Vector = new Vector();
	public var collider:Shape;
}

class Ball extends GameEntity {

	public function new()  {
		super({
	            pos: Luxe.screen.mid,
	            size: new Vector(15,15), 
	            depth:2,
	            texture: Luxe.resources.texture('assets/textures/ball.png'),
	            centered:true
	        });
		collider = new Circle(pos.x, pos.y, 7.5);
	}

	override function update(dt:Float) {
		pos.x += v.x * dt;
		pos.y += v.y * dt;

		if(pos.y <= 0 || pos.y + 15 >= Luxe.screen.h) {
			v.y *= -1;
		}

		if(pos.x <= 0) {
			Play.instance.p2Score++;
		}
		else if(pos.x >= Luxe.screen.w - 15) {
			Play.instance.p1Score++;
		}

		collider.position = pos;

		transform.dirty = true;
		// or update geometry.transform

		// My sage advice is to make a hard and fast rule to always use entity.transform
	}
}

class Paddle extends GameEntity {

	private var targetY:Float = 0;
	private var speed:Float = 200;

	public function new(startPos:Vector, speed:Float) {
		super({
			pos: startPos,
			size: new Vector(20, 60),
			color: new Color(1, 1, 1, 1),
			centered: false
		});
		
		this.speed = speed;

		targetY = Luxe.screen.h / 2 - 30;

		collider = Polygon.rectangle(startPos.x, startPos.y, 20, 60, false);
	}

	public function setTargetY(y:Float) {
		targetY = y;
	}

	override function update(dt:Float) {
		pos.x += v.x * dt;
		pos.y += v.y * dt;

		if(Math.abs(targetY - pos.y) >= 5) { // 20
			v.y = speed * (targetY < pos.y ? -1 : 1); // 30
		}
		else {
			v.y = 0;
		}

		if(pos.y <= 0) {
			pos.y = 0;
		}
		else if(pos.y + 60 >= Luxe.screen.h) {
			pos.y = Luxe.screen.h - 60;
		}

		collider.position = pos;
		transform.dirty = true;
	}
}

class CPUPaddle extends Paddle {
	override function update(dt:Float) {
		setTargetY(Play.instance.ball.pos.y - 30);
		super.update(dt);
	}
}

class Play extends State {
	var scoreText:Text;
	
	var scoreFont:BitmapFont;

	var p1Paddle:Paddle;
	var p2Paddle:Paddle;
	public var ball:Ball;

	public static var instance:Play = null;

	public var p1Score(default, set):Int = 0;
	public var p2Score(default, set):Int = 0;

	public function set_p1Score(x) {
		p1Score = x;
		if(p1Score > 9) {
			Main.fsm.set('menu');
		}
		resetBall();
		updateScoreDisplay();
		return p1Score;
	}

	public function set_p2Score(x) {
		p2Score = x;
		if(p2Score > 9) {
			Main.fsm.set('menu');
		}
		resetBall();
		updateScoreDisplay();
		return p2Score;
	}

	function resetBall() {
		ball.pos = new Vector(Luxe.screen.mid.x, Luxe.screen.mid.y);

		// pick a starting direction
		var angle:Float = (Math.random() - 0.5) * Math.PI / 2;
		if(Math.random() < 0.5) {
			angle += Math.PI;
		}

		var speed:Float = 300;
		ball.v = new Vector(speed * Math.cos(angle), speed * Math.sin(angle));
	}

	function updateScoreDisplay() {
		scoreText.text = p1Score + ":" + p2Score;
	}

	public function new() {
		super({ name: 'play' });
		instance = this;
	}

	override function onenter<T>(_:T) {
		var beep = Luxe.audio.get('beep');
		scoreFont = Luxe.resources.font('assets/fonts/digital7.fnt');
		scoreText = new Text({
			font: scoreFont,
			text: '0:0',
			depth: 10,
			align: center,
			align_vertical: center,
			point_size: 48,
			letter_spacing: 0,
			pos: new Vector( Luxe.screen.mid.x, 24),
			color: new Color(1, 1, 1, 1),
			sdf: true
		});

		ball = new Ball();

		p1Paddle = new Paddle(new Vector(0, Luxe.screen.mid.y - 30), 200);
		p2Paddle = new CPUPaddle(new Vector(Luxe.screen.w - 20, Luxe.screen.mid.y - 30), 125);

		p1Score = 0;
		p2Score = 0;
	}

	override function onleave<T>(_:T) {
		scoreText.destroy();
		ball.destroy();
		p1Paddle.destroy();
		p2Paddle.destroy();
	}

	override function onmousemove(e:MouseEvent) {
		p1Paddle.setTargetY(e.y - 30);
	} // onmousemove

	override function onkeyup( e:KeyEvent ) {
		if(e.keycode == Key.escape) {
			Main.fsm.set('menu');
		}
	} //onkeyup

	override function update(dt:Float) {

		if(Collision.shapeWithShape(ball.collider, p1Paddle.collider) != null) {
			ball.v.x = Math.abs(ball.v.x);
			Luxe.audio.play("beep");
		}

		if(Collision.shapeWithShape(ball.collider, p2Paddle.collider) != null) {
			ball.v.x = -Math.abs(ball.v.x);
			Luxe.audio.play("beep");
		}
	}
}