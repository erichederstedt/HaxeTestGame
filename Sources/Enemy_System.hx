package;

import Renderer.Draw_Call;
import kha.Color;
import kha.ScreenCanvas;
import differ.Collision;
import differ.shapes.Circle;
import kha.math.FastVector2;
import kha.Image;
import kha.math.Vector2;
import kha.math.Vector2i;

enum Enemy_State {
    Idle;
    Walk;
    Run;
    Hit;
    Death;
    Attack1;
    Attack2;
    Attack3;
}

@:struct
class Enemy
{
    public var position: Vector2;
    public var state: Enemy_State;
    public var old_state: Enemy_State;
    public var time: Float;
    public var current_frame: Int;
    public var direction: Vector2;
    public var health: Float;
    public var max_health: Float;

    public function new() {
        position = new Vector2();
        state = Enemy_State.Idle;
        old_state = Enemy_State.Idle;
        time = 0.0;
        current_frame = 0;
        direction = new Vector2();
        max_health = 100.0; 
        health = max_health; 
    }
}

class Enemy_System
{
    var player_system: Player_System = null;
    static final sprite_dimensions = [ 
        new Vector2i(4, 4),
        new Vector2i(5, 4),
        new Vector2i(6, 4),
        new Vector2i(5, 4),
        new Vector2i(6, 4),
        new Vector2i(6, 4),
        new Vector2i(6, 5),
        new Vector2i(6, 4)
    ];

    var enemies: Array<Enemy> = new Array<Enemy>();

    function enemy_switch_state(enemy: Enemy, state: Enemy_State) {
        enemy.old_state = enemy.state;
        enemy.state = state;
        enemy.current_frame = 0;
        enemy.time = 0;
        trace("enemy_switch_state: " + state);
    }

    public function collide_with_enemies(pos1: FastVector2, rad1: Float): Array<Enemy> {
        var hit_enemies = new Array<Enemy>();
        for (enemy in enemies)
        {
            if(Game.collides(pos1, rad1, new FastVector2(enemy.position.x, enemy.position.y), 25.0))
                hit_enemies.push(enemy);
        }
        return hit_enemies;
    }

    public function enemy_hit(enemy: Enemy, damage: Float) {
        enemy.health -= damage;

        if (enemy.health > 0.0 && enemy.state != Hit)
        {
            enemy_switch_state(enemy, Hit);
        }
        else if (enemy.health <= 0.0 && enemy.state != Death)
        {
            enemy_switch_state(enemy, Death);
        }
        else
        {
            enemy.health = 0.0;
        }
    }

    function should_seek(enemy: Enemy) {
        var player_pos = Game.get_player_pos();

        trace("player.x: " + player_pos.x + ", player.y: " + player_pos.y);
        trace("enemy.x: " + enemy.position.x + ", enemy.y: " + enemy.position.y);

        if (Game.collides(player_pos, 25.0,
            new FastVector2(enemy.position.x, enemy.position.y), 150.0))
        {
            trace("seek");
            enemy_switch_state(enemy, Enemy_State.Walk);
        }
    }
    function should_stop_seek(enemy: Enemy) {
        var player_pos = Game.get_player_pos();

        if (!Game.collides(player_pos, 25.0,
            new FastVector2(enemy.position.x, enemy.position.y), 150.0))
        {
            trace("stop seek");
            enemy_switch_state(enemy, Enemy_State.Idle);
        }
    }
    function should_attack(enemy: Enemy) {
        var player_pos = Game.get_player_pos();

        if (Game.collides(player_pos, 25.0,
            new FastVector2(enemy.position.x, enemy.position.y), 50.0))
        {
            trace("attack");
            enemy_switch_state(enemy, Enemy_State.Attack1);
        }
    }
    function should_stop_attack(enemy: Enemy) {
        var player_pos = Game.get_player_pos();

        if (!Game.collides(player_pos, 25.0,
            new FastVector2(enemy.position.x, enemy.position.y), 50.0))
        {
            trace("stop attack");
            enemy_switch_state(enemy, enemy.old_state);
        }
    }
    function enemy_move(enemy: Enemy, move_distance: Float) {
        enemy.position.x += enemy.direction.x * move_distance;
        enemy.position.y += enemy.direction.y * move_distance;
    }

    function update_idle(enemy: Enemy, dt: Float) {
        should_seek(enemy);
    }
    function update_walk(enemy: Enemy, dt: Float) {
        var player_pos = new Vector2(Game.get_player_pos().x, Game.get_player_pos().y);
        
        enemy.direction = player_pos.sub(enemy.position).normalized();
        enemy_move(enemy, 50.0 * dt);

        should_attack(enemy);
        should_stop_seek(enemy);
    }
    function update_run(enemy: Enemy, dt: Float) {
    }
    function update_hit(enemy: Enemy, dt: Float) {
    }
    function update_death(enemy: Enemy, dt: Float) {
    }
    function update_attack(enemy: Enemy, dt: Float) {
        var player_pos = new Vector2(Game.get_player_pos().x, Game.get_player_pos().y);

        enemy.direction = player_pos.sub(enemy.position).normalized();
        should_stop_attack(enemy);
    }

    public function update(dt: Float) {
        final frame_time = 0.03333;

        for (i in 0 ... enemies.length)
        {
            var enemy: Enemy = enemies[i];
            enemy.time += dt;
            while (enemy.time >= frame_time)
            {
                enemy.time -= frame_time;
                enemy.current_frame++;

                switch (enemy.state)
                {
                    case Idle:
                        update_idle(enemy, dt);
                    case Walk:
                        update_walk(enemy, dt);
                    case Run:
                        update_run(enemy, dt);
                    case Hit:
                        update_hit(enemy, dt);
                    case Death:
                        update_death(enemy, dt);
                    case Attack1:
                        update_attack(enemy, dt);
                    case Attack2:
                        update_attack(enemy, dt);
                    case Attack3:
                        update_attack(enemy, dt);
                }

                if (enemy.current_frame >= (sprite_dimensions[enemy.state.getIndex()].x * sprite_dimensions[enemy.state.getIndex()].y))
                {
                    switch (enemy.state)
                    {
                        case Hit:
                            enemy_switch_state(enemy, enemy.old_state);
                        case Death:
                            enemy.current_frame--;
                        default:
                            enemy.current_frame = 0;
                    }
                }
            }
        }
    }

    function is_zero(number: Float): Bool {
        return number > -0.5 && number < 0.5;
    }
    public function render(camera_pos: FastVector2) {
        for (i in 0 ... enemies.length)
        {
            var enemy: Enemy = enemies[i];
            var texture: Image = null;
            static var dir_name: String = "000";

            if (is_zero(enemy.direction.x) && enemy.direction.y <= -0.5) // Up
            {
                dir_name = "000";
            }
            if (enemy.direction.x >= 0.5 && enemy.direction.y <= -0.5) // Up-Right
            {
                dir_name = "045";
            }
            if (enemy.direction.x >= 0.5 && is_zero(enemy.direction.y)) // Right
            {
                dir_name = "090";
            }
            if (enemy.direction.x >= 0.5 && enemy.direction.y >= 0.5) // Down-Right
            {
                dir_name = "135";
            }
            if (is_zero(enemy.direction.x) && enemy.direction.y >= 0.5) // Down
            {
                dir_name = "180";
            }
            if (enemy.direction.x <= -0.5 && enemy.direction.y >= 0.5) // Down-Left
            {
                dir_name = "225";
            }
            if (enemy.direction.x <= -0.5 && is_zero(enemy.direction.y)) // Left
            {
                dir_name = "270";
            }
            if (enemy.direction.x <= -0.5 && enemy.direction.y <= -0.5) // Up-Left
            {
                dir_name = "315";
            }

            switch (enemy.state)
            {
                case Idle: 
                    texture = Renderer.get_texture("Orc_Idle_Body_"+dir_name);
                case Walk:
                    texture = Renderer.get_texture("Orc_Walk_Body_"+dir_name);
                case Run:
                    texture = Renderer.get_texture("Orc_Run_Body_"+dir_name);
                case Hit:
                    texture = Renderer.get_texture("Orc_Hit_Body_"+dir_name);
                case Death:
                    texture = Renderer.get_texture("Orc_Death_Body_"+dir_name);
                case Attack1:
                    texture = Renderer.get_texture("Orc_Attack_01_Body_"+dir_name);
                case Attack2:
                    texture = Renderer.get_texture("Orc_Attack_02_Body_"+dir_name);
                case Attack3:
                    texture = Renderer.get_texture("Orc_Attack_03_Body_"+dir_name);
            }

            final spritesheet_dimension: Vector2i = sprite_dimensions[enemy.state.getIndex()];

            var sub_image_size = new FastVector2();
            sub_image_size.x = texture.width / spritesheet_dimension.x;
            sub_image_size.y = texture.height / spritesheet_dimension.y;

            var sub_image_pos = new FastVector2();
            sub_image_pos.x = Std.int((enemy.current_frame % spritesheet_dimension.x)) * (sub_image_size.x);
            sub_image_pos.y = Std.int((enemy.current_frame / spritesheet_dimension.x)) * (sub_image_size.y);

            var draw_call = new Draw_Call();
            draw_call.texture = texture;
            draw_call.position.x = enemy.position.x - camera_pos.x;
            draw_call.position.y = enemy.position.y - camera_pos.y / 2;
            draw_call.size = new FastVector2(128, 128);
            draw_call.is_sub_image = true;
            draw_call.sub_image_position = sub_image_pos;
            draw_call.sub_image_size = sub_image_size;

            var blink: Int = Std.int(enemy.current_frame / 6);
            if (blink % 2 == 0 && enemy.state == Hit)
            {
                draw_call.color = Color.Red;
            }

            Renderer.draw_quad(draw_call);

            var draw_pos = new FastVector2();
            draw_pos.x = (enemy.position.x - camera_pos.x / 2) - enemy.position.x / 2;
            draw_pos.y = (enemy.position.y - camera_pos.y / 4) - enemy.position.y / 2;
            Renderer.draw_circle(draw_pos, 50.0);
            Renderer.draw_circle(draw_pos, 150.0, Color.Yellow);
        }
    }

    public function new() {
        var enemy = new Enemy();
        enemy.position = new Vector2(400, 400);
        enemies.push(enemy);
    }
    public function init(player_system: Player_System) {
        this.player_system = player_system;
    }
}