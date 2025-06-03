package;

import kha.ScreenCanvas;
import differ.Collision;
import differ.shapes.Circle;
import Renderer.Draw_Call;
import kha.Color;
import kha.math.FastVector2;

class Game
{
    static var player_system: Player_System = new Player_System();
    static var enemy_system: Enemy_System = new Enemy_System();

    public static function init() {
        player_system.init(enemy_system);
        enemy_system.init(player_system);
    }

    static var angle = 0.0;
    static var camera_pos: FastVector2 = new FastVector2();
    public static function update(dt : Float): Void {
        Renderer.flip_buffer();

        angle += dt;
        var draw_call = new Draw_Call();
        draw_call.color = Color.Red;
        draw_call.position = new FastVector2(0, 0);
        draw_call.size = new FastVector2(64, 64);
        draw_call.post_rotation_scale = new FastVector2(1.0, 1.0);
        draw_call.origin = new FastVector2(0.5, 0.5);
        draw_call.rotation = angle;
        Renderer.draw_quad(draw_call);

        player_system.update(dt);
        camera_pos = player_system.get_player_position();
        enemy_system.update(dt);
        
        for (tile_y in 0...16) {
            for (tile_x in 0...16) {
                var draw_pos = grid_to_draw_coord(new FastVector2(tile_x, tile_y));

                draw_pos.x += 300; // Offset
                draw_pos.y += 300;

                var draw_call = new Draw_Call();
                draw_call.texture = Renderer.get_texture("grass_1");
                draw_call.color = Color.White;
                draw_call.position = draw_pos;
                draw_call.size = new FastVector2(64, 64);
                draw_call.post_rotation_scale = new FastVector2(1.0, 0.5);
                draw_call.origin = new FastVector2(0.5, 0.5);
                draw_call.rotation = Math.PI / 4;
                Renderer.draw_quad(draw_call);
            }
        }

        player_system.render();
        enemy_system.render(camera_pos);
	}

    public static function grid_to_draw_coord(position: FastVector2): FastVector2 {
        var screen_pos = new FastVector2(
            (position.x - position.y) * (64 / 2),
            (position.x + position.y) * (64 / 2)
        );
        var draw_pos = new FastVector2(
            screen_pos.x - camera_pos.x,
            screen_pos.y - camera_pos.y
        );
        return draw_pos;
    }

    public static function collides(pos1: FastVector2, rad1: Float, pos2: FastVector2, rad2: Float): Bool {
        var collider_1 = new Circle(pos1.x, pos1.y, rad1);
        var collider_2 = new Circle(pos2.x, pos2.y, rad2);

        var info = Collision.shapeWithShape(collider_1, collider_2);
        return info != null;
    }

    public static function get_player_pos(): FastVector2 {
        var camera_pos = player_system.get_player_position();
        return new FastVector2(camera_pos.x + ScreenCanvas.the.width / 2.0, camera_pos.y / 2 + ScreenCanvas.the.height / 2.0);
    }
}