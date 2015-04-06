import haxe.ds.StringMap;
import luxe.Audio;
import luxe.collision.Collision;
import luxe.collision.CollisionData;
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

class Velocity extends Component {
	public var v:Vector = new Vector();

	public function new(vx:Float, vy:Float) {
		super({name: 'velocity'});
		v.x = vx;
		v.y = vy;
	}

	override function update(dt:Float) {
		pos.x += v.x * dt;
		pos.y += v.y * dt;
	}
}

class BounceTopBottom extends Component {
	public function new() {
		super({name: 'BounceTopBottom'});
	}

	override function update(dt:Float) {
		if(pos.y <= 0 || pos.y + 15 >= Luxe.screen.h) {
			var velocity = cast get('velocity');
			velocity.v.y *= -1;
		}
	}
}

class BindToPlayArea extends Component {
	public function new() {
		super({name: 'bindToPlayArea'});
	}

	override function update(dt:Float) {
		if(pos.y <= 0) {
			pos.y = 0;
		}
		else if(pos.y + 60 >= Luxe.screen.h) {
			pos.y = Luxe.screen.h - 60;
		}
	}
}

class FollowEntityAI extends Component {
	var target:Entity;
	var speed:Float = 0;
	var vel:Velocity = null;

	public function new(target:Entity, speed:Float) {
		super({name: 'FollowEntity'});
		this.target = target;
		this.speed = speed;
	}

	override function update(dt:Float) {
		if(vel == null) {
			vel = cast(get('velocity'), Velocity);
		}

		var targetPos:Float = target.pos.y - 30;
		if(Math.abs(targetPos - pos.y) >= 20) {
			vel.v.y = speed * (targetPos < pos.y + 30 ? -1 : 1);
		}
		else {
			vel.v.y = 0;
		}
	}
}

class Score extends Component {
	var play:Play;

	public function new(play:Play) {
		super({name: 'score'});
		this.play = play;
	}

	override function update(dt:Float) {
		if(pos.x <= 0) {
			play.p2Score++;
		}
		else if(pos.x >= Luxe.screen.w - 15) {
			play.p1Score++;
		}
	}
}

class Play extends State {
	var scoreText:Text;
	var scoreFont:BitmapFont;

	var p1Paddle:Visual;
	var p2Paddle:Visual;
	var ball:Visual;

	public var p1Score(default, set):Int = 0;
	public var p2Score(default, set):Int = 0;

	var p1Collider:Polygon;
	var p2Collider:Polygon;
	var ballCollider:Circle;

	var beepReady:Bool = false;

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
		var vel:Velocity = cast(ball.get('velocity'), Velocity);
		var speed:Float = 300;
		vel.v = new Vector(speed * Math.cos(angle), speed * Math.sin(angle));
	}

	function updateScoreDisplay() {
		scoreText.text = p1Score + ":" + p2Score;
	}

	public function new() {
		super({ name: 'play' });
	}

	override function onenter<T>(_:T) {
		var beep = Luxe.resources.find_sound('beeep');

		scoreFont = Luxe.resources.find_font('assets/fonts/digital7.fnt');
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

		ball = new Visual({
			pos: Luxe.screen.mid,
			size: new Vector(15, 15),
			color: new Color(1, 1, 1, 1)
		});
		ball.add(new Velocity(0, 0));
		ball.add(new BounceTopBottom());
		ball.add(new Score(this));
		ballCollider = new Circle(ball.pos.x, ball.pos.y, 7.5);

		p1Paddle = new Visual({
			pos: new Vector(0, Luxe.screen.mid.y - 30),
			size: new Vector(20, 60),
			color: new Color(1, 1, 1, 1)
		});
		p1Paddle.add(new Velocity(0, 0));
		p1Paddle.add(new BindToPlayArea());
		p1Collider = Polygon.rectangle(0, Luxe.screen.mid.y - 30, 20, 60, false);

		p2Paddle = new Visual({
			pos: new Vector(Luxe.screen.w - 20, Luxe.screen.mid.y - 30),
			size: new Vector(20, 60),
			color: new Color(1, 1, 1, 1)
		});
		p2Paddle.add(new Velocity(0, 0));
		p2Paddle.add(new BindToPlayArea());
		p2Paddle.add(new FollowEntityAI(ball, 200));
		p2Collider = Polygon.rectangle(Luxe.screen.w - 20, Luxe.screen.mid.y - 30, 20, 60, false);

		p1Score = 0;
		p2Score = 0;

		Luxe.audio.on("beep", "load", function(_) {
			beepReady = true;
		});
	}

	override function onleave<T>(_:T) {
		scoreText.destroy();
		ball.destroy();
		p1Paddle.destroy();
		p2Paddle.destroy();
	}

	override function onmousemove(e:MouseEvent) {
		var targetPos:Float = e.y - 30;
		if(Math.abs(targetPos - p1Paddle.pos.y) >= 20) {
			cast(p1Paddle.get('velocity'), Velocity).v.y = 200 * (targetPos < p1Paddle.pos.y + 30 ? -1 : 1);
		}
		else {
			cast(p1Paddle.get('velocity'), Velocity).v.y = 0;
		}
	} // onmousemove

	override function onkeyup( e:KeyEvent ) {
		if(e.keycode == Key.escape) {
			Main.fsm.set('menu');
		}
	} //onkeyup

	override function update(dt:Float) {
		ballCollider.position = ball.pos;
		p1Collider.position = p1Paddle.pos;

		// test collision with p1 paddle
		if(Collision.test(ballCollider, p1Collider) != null) {
			//ball.pos.x = 20;
			cast(ball.get('velocity'), Velocity).v.x = Math.abs(cast(ball.get('velocity'), Velocity).v.x);
			if(beepReady) {
				Luxe.audio.play("beep");
			}
		}

		// test collision with p2 paddle
		if(Collision.test(ballCollider, p2Collider) != null) {
			//ball.pos.x = Luxe.screen.w - 20;
			cast(ball.get('velocity'), Velocity).v.x = -Math.abs(cast(ball.get('velocity'), Velocity).v.x);
			if(beepReady) {
				Luxe.audio.play("beep");
			}
		}
	}
}