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

	public static var BALL_RADIUS:Float = 7.5;

	public function new()  {
		super({
	            pos: Luxe.screen.mid,
	            size: new Vector(BALL_RADIUS * 2, BALL_RADIUS * 2), 
	            depth:2,
	            texture: Luxe.resources.texture('assets/textures/ball.png'),
	            centered:true
	        });
		collider = new Circle(pos.x, pos.y, BALL_RADIUS);
	}

	override function update(dt:Float) {
		pos.x += v.x * dt;
		pos.y += v.y * dt;

		// Bounce off the top and bottom of the screen

		if(pos.y - BALL_RADIUS <= 0 || pos.y + BALL_RADIUS >= Luxe.screen.h) {
			v.y *= -1;
		}

		// Score if hitting the edge of the screen

		if(pos.x <= -BALL_RADIUS) {
			Play.instance.p2Score++;
		}
		else if(pos.x >= Luxe.screen.w + BALL_RADIUS) {
			Play.instance.p1Score++;
		}

		collider.position = pos;

		// Advice from chat:
		// "or update geometry.transform"
		// "My sage advice is to make a hard and fast rule to always use entity.transform"

		transform.dirty = true;
	}
}

class Paddle extends GameEntity {
	public static var PADDLE_WIDTH:Float = 20;
	public static var PADDLE_HEIGHT:Float = 60;

	private var targetY:Float = 0;
	private var speed:Float = 200;

	public function new(startPos:Vector, speed:Float) {
		super({
			pos: startPos,
			size: new Vector(PADDLE_WIDTH, PADDLE_HEIGHT),
			color: new Color(1, 1, 1, 1),
			centered: false
		});
		
		this.speed = speed;

		targetY = Luxe.screen.h / 2 - PADDLE_HEIGHT / 2;

		collider = Polygon.rectangle(startPos.x, startPos.y, PADDLE_WIDTH, PADDLE_HEIGHT, false);
	}

	public function setTargetY(y:Float) {
		targetY = y;
	}

	override function update(dt:Float) {
		pos.x += v.x * dt;
		pos.y += v.y * dt;

		// Move the paddle toward the target position

		if(Math.abs(targetY - pos.y) >= 5) {
			v.y = speed * (targetY < pos.y ? -1 : 1);
		}
		else {
			v.y = 0;
		}

		// Keep the paddle on the screen

		if(pos.y <= 0) {
			pos.y = 0;
		}
		else if(pos.y + PADDLE_HEIGHT >= Luxe.screen.h) {
			pos.y = Luxe.screen.h - PADDLE_HEIGHT;
		}

		collider.position = pos;
		transform.dirty = true;
	}
}

class CPUPaddle extends Paddle {
	override function update(dt:Float) {
		setTargetY(Play.instance.ball.pos.y - Paddle.PADDLE_HEIGHT / 2);
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

		p1Paddle = new Paddle(new Vector(0, Luxe.screen.mid.y - Paddle.PADDLE_HEIGHT / 2), 200);
		p2Paddle = new CPUPaddle(new Vector(Luxe.screen.w - Paddle.PADDLE_WIDTH, Luxe.screen.mid.y - Paddle.PADDLE_HEIGHT / 2), 125);

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
		p1Paddle.setTargetY(e.y - Paddle.PADDLE_HEIGHT / 2);
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