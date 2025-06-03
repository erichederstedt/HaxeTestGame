package;

import kha.Assets;
import kha.Image;
import kha.math.FastVector2;
import kha.Framebuffer;
import kha.Color;

@:struct
class Draw_Call
{
    public var texture: Image;
    public var color: Color;
    public var position: FastVector2;
    public var size: FastVector2;
    public var post_rotation_scale: FastVector2;
    public var origin: FastVector2; // 0,0 == middle
    public var rotation: Float;
    public var is_sub_image: Bool;
    public var sub_image_position: FastVector2;
    public var sub_image_size: FastVector2;
    public var is_circle: Bool;
    public var radius: Float; // Only used when circle

    public function new() {
        texture = null;
        color = Color.White;
        position = new FastVector2(0, 0);
        size = new FastVector2(1.0, 1.0);
        post_rotation_scale = new FastVector2(1.0, 1.0);
        origin = new FastVector2(0.5, 0.5);
        rotation = 0.0;
        is_sub_image = false;
        sub_image_position = new FastVector2(0.0, 0.0);
        sub_image_size = new FastVector2(1.0, 1.0);
        is_circle = false;
        radius = 0.0;
    }
}
class Frame_Buffer
{
    public var draw_calls: Array<Draw_Call>;

    public function new() {
        this.draw_calls = new Array<Draw_Call>();
    }
}

class Renderer
{
    static var frame_buffers: Array<Frame_Buffer> = [ new Frame_Buffer(), new Frame_Buffer() ];
    static var frame_index = 0;

    public static function draw_quad(draw_call :Draw_Call): Void {
        frame_buffers[frame_index].draw_calls.push(draw_call);
    }
    public static function draw_circle(position: FastVector2, radius: Float, color: Color = Color.White): Void {
        var draw_call = new Draw_Call();
        draw_call.position = position;
        draw_call.is_circle = true;
        draw_call.radius = radius;
        draw_call.color = color;
        frame_buffers[frame_index].draw_calls.push(draw_call);
    }

    public static function get_texture(name: String): Image {
        return Assets.images.get(name);
    }

    static function render_circle(g2: kha.graphics2.Graphics, position: FastVector2, radius: Float, segments: Int = 64) {
        var angleStep = Math.PI * 2 / segments;
        var prevX = position.x + Math.cos(0) * radius;
        var prevY = position.y + Math.sin(0) * radius;

        for (i in 1...segments + 1) {
            var angle = i * angleStep;
            var x = position.x + Math.cos(angle) * radius;
            var y = position.y + Math.sin(angle) * radius;
            g2.drawLine(prevX, prevY, x, y);
            prevX = x;
            prevY = y;
        }
    }

    public static function render_frame(frame: Framebuffer): Void {
		final g2: kha.graphics2.Graphics = frame.g2;
        g2.begin(true, Color.fromBytes(0, 95, 106));

        final frame_buffer = frame_buffers[frame_index];
        
		for (draw_call_index in 0...frame_buffer.draw_calls.length) {
            final draw_call = frame_buffer.draw_calls[draw_call_index];
            g2.color = draw_call.color;
		    g2.pushTranslation(draw_call.position.x, draw_call.position.y);
            g2.pushRotation(draw_call.rotation, draw_call.position.x, draw_call.position.y);

            if (draw_call.is_circle)
            {
                render_circle(g2, draw_call.position, draw_call.radius);
            }
            else 
            {    
                if (draw_call.texture == null)
                {
                    g2.fillRect(-draw_call.origin.x * draw_call.size.x, -draw_call.origin.y * draw_call.size.y, draw_call.size.x, draw_call.size.y);
                }
                else 
                {
                    g2.pushScale(draw_call.post_rotation_scale.x, draw_call.post_rotation_scale.y);
                    if (draw_call.is_sub_image)
                    {
                        g2.drawScaledSubImage(draw_call.texture, draw_call.sub_image_position.x, draw_call.sub_image_position.y, draw_call.sub_image_size.x, draw_call.sub_image_size.y, -draw_call.origin.x * draw_call.size.x, -draw_call.origin.y * draw_call.size.y, draw_call.size.x, draw_call.size.y);
                    }
                    else 
                    {
                        g2.drawScaledImage(draw_call.texture, -draw_call.origin.x * draw_call.size.x, -draw_call.origin.y * draw_call.size.y, draw_call.size.x, draw_call.size.y);
                    }
                    g2.popTransformation();
                }
            }
            
		    g2.popTransformation();
		    g2.popTransformation();
		}

		g2.end();
	}

    public static function flip_buffer(): Void {
        untyped frame_buffers[frame_index].draw_calls.length = 0;
        frame_index = (frame_index + 1) % 2;
    }
}