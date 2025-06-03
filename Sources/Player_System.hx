package;

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

    var player: Player = new Player();

    function player_switch_state(state: Player_State) {
        player.old_state = player.state;
        player.state = state;
        player.current_frame = 0;
        player.time = 0;

        if (state == Attack1 || state == Attack2 || state == Attack3)
            player.is_attacking = true;
        else 
            player.is_attacking = false;


        player.has_attacked = false;
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
    
    var enemy_system: Enemy_System = null;
    function attack() {
        player.has_attacked = true;

        var hit_box_pos = Game.get_player_pos();
        hit_box_pos.x += player.old_direction.x * 15.0;
        hit_box_pos.y += player.old_direction.y * 15.0;
        var hit_enemies = enemy_system.collide_with_enemies(hit_box_pos, 25.0);

        for (enemy in hit_enemies)
        {
            enemy_system.enemy_hit(enemy, 15.0);
        }
    }

    public function update(dt: Float) {
        final move_speed = 75.0;

        if (player.direction.length > 0.0)
            player.old_direction = player.direction;

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

        var old_state = player.state;

        player.time += dt;
        final frame_time = 0.03333;
        while (player.time >= frame_time)
        {
            player.time -= frame_time;
            player.current_frame++;
        }

        switch (player.state) {
            case Idle: 
                if (player.direction.length > 0.0)
                    player_switch_state(Walk);

                player_should_attack();

            case Walk:
                if (player.direction.length == 0.0)
                    player_switch_state(Idle);
                if (Input.get_key_held(KeyCode.Shift))
                    player_switch_state(Run);

                player_should_attack();
                player_move(move_speed * dt);

            case Run:
                if (player.direction.length == 0.0)    
                    player_switch_state(Idle);
                if (!Input.get_key_held(KeyCode.Shift))
                    player_switch_state(Walk);

                player_should_attack();
                player_move(move_speed * 2.0 * dt);

            case Hit:
            case Death:

            case Attack1:
            case Attack2:
            case Attack3:
        }

        if (player.is_attacking && !player.has_attacked)
            attack();

        if (player.current_frame >= (sprite_dimensions[player.state.getIndex()].x * sprite_dimensions[player.state.getIndex()].y))
        {
            switch (player.state) {
                case Death:
                    player.current_frame--;

                case Hit:
                    player_switch_state(player.old_state);
                case Attack1:
                    player_switch_state(player.old_state);
                case Attack2:
                    player_switch_state(player.old_state);
                case Attack3:
                    player_switch_state(player.old_state);
                
                default:
                    player.current_frame = 0;
            }
        }

        if (old_state != player.state)
            trace("player.state: " + player.state);
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

        switch (player.state)
        {
            case Idle: 
                texture = Renderer.get_texture("Player_Idle_Body_"+dir_name);
            case Walk:
                texture = Renderer.get_texture("Player_Walk_Body_"+dir_name);
            case Run:
                texture = Renderer.get_texture("Player_Run_Body_"+dir_name);
            case Hit:
                texture = Renderer.get_texture("Player_Hit_Body_"+dir_name);
            case Death:
                texture = Renderer.get_texture("Player_Death_Body_"+dir_name);
            case Attack1:
                texture = Renderer.get_texture("Player_Attack1_Body_"+dir_name);
            case Attack2:
                texture = Renderer.get_texture("Player_Attack2_Body_"+dir_name);
            case Attack3:
                texture = Renderer.get_texture("Player_Attack3_Body_"+dir_name);
        }

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
}