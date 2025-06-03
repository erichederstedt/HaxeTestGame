package;

import kha.Color;
import Renderer.Draw_Call;
import kha.ScreenCanvas;
import kha.Image;
import kha.input.KeyCode;
import kha.math.FastVector2;
import kha.math.Vector2;
import kha.math.Vector2i;

enum Player_State {
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
class Player {
    public var position: Vector2;
    public var state: Player_State;
    public var old_state: Player_State;
    public var time: Float;
    public var current_frame: Int;
    public var direction: Vector2;
    public var old_direction: Vector2;
    public var is_attacking: Bool;
    public var has_attacked: Bool;
    public var health: Float;
    public var max_health: Float;

    public function new() {
        position = new Vector2();
        state = Player_State.Idle;
        old_state = Player_State.Idle;
        time = 0.0;
        current_frame = 0;
        direction = new Vector2();
        old_direction = new Vector2();
        is_attacking = false;
        has_attacked = false;
        max_health = 100.0; 
        health = max_health;
    }
}

class Player_System
{
    static final sprite_dimensions = [ 
        new Vector2i(6, 4),
        new Vector2i(4, 4),
        new Vector2i(6, 4),
        new Vector2i(4, 4),
        new Vector2i(6, 4),
        new Vector2i(6, 4),
        new Vector2i(6, 4),
        new Vector2i(6, 4)
    ];
    static final sprite_names = [ 
        "Player_Idle_Body_",
        "Player_Walk_Body_",
        "Player_Run_Body_",
        "Player_Hit_Body_",
        "Player_Death_Body_",
        "Player_Attack1_Body_",
        "Player_Attack2_Body_",
        "Player_Attack3_Body_"
    ];

    var player: Player = new Player();
    final move_speed = 75.0;

    function player_switch_state(state: Player_State) {
        player.old_state = player.state;
        player.state = state;
        player.current_frame = 0;
        player.time = 0;

        player.is_attacking = false;
        player.has_attacked = false;
        if (state == Attack1 || state == Attack2 || state == Attack3)
            player.is_attacking = true;
    }

    function player_should_attack() {
        if (Input.get_key_down(KeyCode.J))
            player_switch_state(Attack1);
        if (Input.get_key_down(KeyCode.K))
            player_switch_state(Attack2);
        if (Input.get_key_down(KeyCode.L))
            player_switch_state(Attack3);
    }
    function player_move(move_distance: Float) {
        player.position.x += player.direction.x * move_distance;
        player.position.y += player.direction.y * move_distance;
    }
    public function player_hit(damage: Float) {
        player.health -= damage;

        if (player.health > 0.0 && player.state != Hit)
        {
            player_switch_state(Hit);
        }
        else if (player.health <= 0.0 && player.state != Death)
        {
            player_switch_state(Death);
        }
        else
        {
            player.health = 0.0;
        }
    }
    
    var enemy_system: Enemy_System = null;
    function attack() {
        player.has_attacked = true;

        var hit_box_pos = Game.get_player_pos();
        hit_box_pos.x += player.old_direction.x * 15.0;
        hit_box_pos.y += player.old_direction.y * 15.0;
        var hit_enemies = enemy_system.collide_with_enemies(hit_box_pos, 25.0);

        for (enemy in hit_enemies)
        {
            enemy_system.enemy_hit(enemy, 50.0);
        }
    }

    function update_idle(dt: Float) {
        if (player.direction.length > 0.0)
            player_switch_state(Walk);

        player_should_attack();
    }
    function update_walk(dt: Float) {
        if (player.direction.length == 0.0)
            player_switch_state(Idle);
        if (Input.get_key_held(KeyCode.Shift))
            player_switch_state(Run);

        player_should_attack();
        player_move(move_speed * dt);
    }
    function update_run(dt: Float) {
        if (player.direction.length == 0.0)    
            player_switch_state(Idle);
        if (!Input.get_key_held(KeyCode.Shift))
            player_switch_state(Walk);

        player_should_attack();
        player_move(move_speed * 2.0 * dt);
    }
    function update_hit(dt: Float) {

    }
    function update_death(dt: Float) {

    }
    function update_attack(dt: Float) {

    }

    public function update(dt: Float) {
        if (player.direction.length > 0.0)
            player.old_direction = player.direction;

        if (player.state != Death)
        {
            player.direction = new Vector2();
            if (Input.get_key_held(KeyCode.W)) {
                player.direction.y -= 1.0;
            }
            if (Input.get_key_held(KeyCode.S)) {
                player.direction.y += 1.0;
            }
            if (Input.get_key_held(KeyCode.A)) { 
                player.direction.x -= 1.0;
            }
            if (Input.get_key_held(KeyCode.D)) { 
                player.direction.x += 1.0;
            }
        }

        player.time += dt;
        final frame_time = 0.03333;
        while (player.time >= frame_time)
        {
            player.time -= frame_time;
            player.current_frame++;
        }

        switch (player.state) {
            case Idle: 
                update_idle(dt);
            case Walk:
                update_walk(dt);
            case Run:
                update_run(dt);
            case Hit:
                update_hit(dt);
            case Death:
                update_death(dt);
            case Attack1:
                update_attack(dt);
            case Attack2:
                update_attack(dt);
            case Attack3:
                update_attack(dt);
        }

        if (player.is_attacking && !player.has_attacked)
            attack();

        if (player.current_frame >= (sprite_dimensions[player.state.getIndex()].x * sprite_dimensions[player.state.getIndex()].y))
        {
            switch (player.state) {
                case Death:
                    player.current_frame--;

                case Hit:
                    player_switch_state(Idle);
                case Attack1:
                    player_switch_state(Idle);
                case Attack2:
                    player_switch_state(Idle);
                case Attack3:
                    player_switch_state(Idle);
                
                default:
                    player.current_frame = 0;
            }
        }
    }

    public function render() {
        var texture: Image = null;

        static var dir_name: String = "000";

        if (player.direction.x == 0.0 && player.direction.y == -1.0) // Up
        {
            dir_name = "000";
        }
        if (player.direction.x == 1.0 && player.direction.y == -1.0) // Up-Right
        {
            dir_name = "045";
        }
        if (player.direction.x == 1.0 && player.direction.y == 0.0) // Right
        {
            dir_name = "090";
        }
        if (player.direction.x == 1.0 && player.direction.y == 1.0) // Down-Right
        {
            dir_name = "135";
        }
        if (player.direction.x == 0.0 && player.direction.y == 1.0) // Down
        {
            dir_name = "180";
        }
        if (player.direction.x == -1.0 && player.direction.y == 1.0) // Down-Left
        {
            dir_name = "225";
        }
        if (player.direction.x == -1.0 && player.direction.y == 0.0) // Left
        {
            dir_name = "270";
        }
        if (player.direction.x == -1.0 && player.direction.y == -1.0) // Up-Left
        {
            dir_name = "315";
        }

        texture = Renderer.get_texture(sprite_names[player.state.getIndex()]+dir_name);

        final spritesheet_dimension: Vector2i = sprite_dimensions[player.state.getIndex()];

        var sub_image_size = new FastVector2();
        sub_image_size.x = texture.width / spritesheet_dimension.x;
        sub_image_size.y = texture.height / spritesheet_dimension.y;

        var sub_image_pos = new FastVector2();
        sub_image_pos.x = Std.int((player.current_frame % spritesheet_dimension.x)) * (sub_image_size.x);
        sub_image_pos.y = Std.int((player.current_frame / spritesheet_dimension.x)) * (sub_image_size.y);

        var draw_call = new Draw_Call();
        draw_call.texture = texture;
        draw_call.position.x = ScreenCanvas.the.width / 2.0;
        draw_call.position.y = ScreenCanvas.the.height / 2.0;
        draw_call.size = new FastVector2(128, 128);
        draw_call.is_sub_image = true;
        draw_call.sub_image_position = sub_image_pos;
        draw_call.sub_image_size = sub_image_size;

        var blink: Int = Std.int(player.current_frame / 6);
        if (blink % 2 == 0 && player.state == Hit)
        {
            draw_call.color = Color.Red;
        }

        Renderer.draw_quad(draw_call);

        {
            var draw_pos = new FastVector2();
            draw_pos.x = ScreenCanvas.the.width / 4.0;
            draw_pos.y = ScreenCanvas.the.height / 4.0;
            Renderer.draw_circle(draw_pos, 25.0);
        }

        if (player.is_attacking)
        {
            var draw_pos = new FastVector2();
            draw_pos.x = player.old_direction.x * 15.0 + ScreenCanvas.the.width / 4.0;
            draw_pos.y = player.old_direction.y * 15.0 + ScreenCanvas.the.height / 4.0;
            Renderer.draw_circle(draw_pos, 25.0);
        }
    }

    public function new() {
        player.position = new Vector2();
        player.state = Player_State.Idle;
        player.time = 0.0;
        player.current_frame = 0;
    }

    public function init(enemy_system: Enemy_System) {
        this.enemy_system = enemy_system;
    }

    public function get_player_position(): FastVector2 {
        return player.position.fast();
    }
    public function is_player_dead(): Bool {
        return player.state == Death;
    }
}