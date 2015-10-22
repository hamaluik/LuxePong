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

class Constants {
	public static var PADDLE_WIDTH:Float = 20;
 	public static var PADDLE_HEIGHT:Float = 60;
 	public static var BALL_RADIUS:Float = 7.5;
}

class BaseComponent extends Component {
	public function getVelocityComponent() {
		return cast(get('Velocity'), Velocity);
	}
}

class Velocity extends BaseComponent {
	public var v:Vector;

	public function new(initialVelocity:Vector) {
		super({name: 'Velocity'});

		if(initialVelocity == null) {
			initialVelocity = new Vector(0,0);
		}

		v = initialVelocity;
	}

	override function update(dt:Float) {
		pos.x += v.x * dt;
		pos.y += v.y * dt;
	}
}

class BounceTop extends BaseComponent {
	private var velocity:Velocity;

	override function update(dt:Float) {
		if(velocity == null) {
			velocity = getVelocityComponent();
		}

		// Bounce off the top and bottom of the screen

		if(pos.y - Constants.BALL_RADIUS <= 0 || pos.y + Constants.BALL_RADIUS >= Luxe.screen.h) {
			velocity.v.y *= -1;
		}
	}
}

class BallScore extends BaseComponent {
	override function update(dt:Float) {
		// Score if hitting the edge of the screen
		if(pos.x <= -Constants.BALL_RADIUS) {
			Play.instance.p2Score++;
		}
		else if(pos.x >= Luxe.screen.w + Constants.BALL_RADIUS) {
			Play.instance.p1Score++;
		}
	}
}

class PaddleMover extends BaseComponent {
	private var targetY:Float = 0;
	private var speed:Float = 200;

	private var velocity:Velocity;

	public function new(speed:Float) {
		super({name: 'PaddleMover'});
		this.speed = speed;
	}

	override function update(dt:Float) {
		if(velocity == null) {
			velocity = getVelocityComponent();
		}

		if(Math.abs(targetY - pos.y) >= 5) {
			velocity.v.y = speed * (targetY < pos.y ? -1 : 1);
		}
		else {
			velocity.v.y = 0;
		}
	}

	public function setTargetY(y:Float) {
		targetY = y;
	}
}

class PaddleFollowsBall extends Component {
	private var paddleMover:PaddleMover;

	public function new() {
		super({name: 'PaddleFollowsBall'});
	}

	override function update(dt:Float) {
		if(paddleMover == null) {
			paddleMover = cast(get("PaddleMover"), PaddleMover);
		}

		paddleMover.setTargetY(Play.instance.ball.pos.y - Constants.PADDLE_HEIGHT / 2);
	}
}

class BoundToScreen extends Component {
	override function update(dt:Float) {
		if(pos.y <= 0) {
			pos.y = 0;
		}
		else if(pos.y + Constants.PADDLE_HEIGHT >= Luxe.screen.h) {
			pos.y = Luxe.screen.h - Constants.PADDLE_HEIGHT;
		}
	}
}

class GameEntity extends Sprite {
	public var velocity:Velocity;
	public var collider:Shape;

	public function setCollider(collider:Shape) {
		this.collider = collider;
	}
	
	public function addVelocityComponent(velocityComponent:Velocity) {
		this.velocity = velocityComponent;
		add(velocityComponent);
	}

	override function update(dt:Float) {
		if(collider != null)
			collider.position = pos;

		// Advice from chat:
		// "or update geometry.transform"
		// "My sage advice is to make a hard and fast rule to always use entity.transform"

		transform.dirty = true;
	}
}

class Play extends State {

	var scoreText:Text;
	
	var scoreFont:BitmapFont;

	var p1Paddle:GameEntity;
	var p2Paddle:GameEntity;
	var playerPaddleMover:PaddleMover;

	public var ball:GameEntity;

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
		ball.velocity.v = new Vector(speed * Math.cos(angle), speed * Math.sin(angle));
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

		ball = new GameEntity({
	            pos: Luxe.screen.mid,
	            size: new Vector(Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2), 
	            depth:2,
	            texture: Luxe.resources.texture('assets/textures/ball.png'),
	            centered:true
	        });
		
		ball.addVelocityComponent(new Velocity(new Vector(0,0)));
		ball.add(new BallScore());
		ball.add(new BounceTop());
		ball.setCollider(new Circle(ball.pos.x, ball.pos.y, Constants.BALL_RADIUS));

		p1Paddle = new GameEntity({
			pos: new Vector(0, Luxe.screen.mid.y - Constants.PADDLE_HEIGHT / 2),
			size: new Vector(Constants.PADDLE_WIDTH, Constants.PADDLE_HEIGHT),
			color: new Color(1, 1, 1, 1),
			centered: false
		});

		var v:Velocity = new Velocity(new Vector(0,0));
		p1Paddle.addVelocityComponent(v);
		playerPaddleMover = new PaddleMover(200);
		p1Paddle.add(playerPaddleMover);
		p1Paddle.setCollider(Polygon.rectangle(p1Paddle.pos.x, p1Paddle.pos.y, Constants.PADDLE_WIDTH, Constants.PADDLE_HEIGHT, false));

		p2Paddle = new GameEntity({
			pos: new Vector(Luxe.screen.w - Constants.PADDLE_WIDTH, Luxe.screen.mid.y - Constants.PADDLE_HEIGHT / 2),
			size: new Vector(Constants.PADDLE_WIDTH, Constants.PADDLE_HEIGHT),
			color: new Color(1, 1, 1, 1),
			centered: false
		});

		var v:Velocity = new Velocity(new Vector(0,0));
		p2Paddle.addVelocityComponent(v);
		p2Paddle.add(new PaddleMover(125));
		p2Paddle.add(new PaddleFollowsBall());
		p2Paddle.setCollider(Polygon.rectangle(p2Paddle.pos.x, p2Paddle.pos.y, Constants.PADDLE_WIDTH, Constants.PADDLE_HEIGHT, false));

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
		playerPaddleMover.setTargetY(e.y - Constants.PADDLE_HEIGHT / 2);
	} // onmousemove

	override function onkeyup( e:KeyEvent ) {
		if(e.keycode == Key.escape) {
			Main.fsm.set('menu');
		}
	} //onkeyup

	override function update(dt:Float) {

		if(Collision.shapeWithShape(ball.collider, p1Paddle.collider) != null) {
			ball.velocity.v.x = Math.abs(ball.velocity.v.x);
			Luxe.audio.play("beep");
		}

		if(Collision.shapeWithShape(ball.collider, p2Paddle.collider) != null) {
			ball.velocity.v.x = -Math.abs(ball.velocity.v.x);
			Luxe.audio.play("beep");
		}
	}
}