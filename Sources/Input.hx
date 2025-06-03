package;

import kha.input.Keyboard;
import kha.input.KeyCode;

enum Key_State {
    Up;
    Down;
    Held;
}

class Input
{
    static var input_buffer: Array<Key_State> = new Array<Key_State>();
    static var temp_input_buffer: Array<{ key: KeyCode, state: Key_State }> = new Array<{ key: KeyCode, state: Key_State }>();

    public static function get_key_down(key_code: KeyCode): Bool {
        return input_buffer[key_code] == Key_State.Down;
    }
    public static function get_key_up(key_code: KeyCode): Bool {
        return input_buffer[key_code] == Key_State.Up;
    }
    public static function get_key_held(key_code: KeyCode): Bool {
        return input_buffer[key_code] == Key_State.Held;
    }

    static function on_key_down(key_code: KeyCode):Void {
        // trace("Key down: " + key_code);
        temp_input_buffer.push({ key: key_code, state: Key_State.Down });
    }
    
    static function on_key_up(key_code: KeyCode):Void {
        // trace("Key up: " + key_code);
        temp_input_buffer.push({ key: key_code, state: Key_State.Up });
	}

    public static function init(): Void {
        for (i in 0 ... 255)
        {
            input_buffer.push(Key_State.Up);
        }

		Keyboard.get().notify(on_key_down, on_key_up);
	}

    public static function update(): Void {
        for (i in 0 ... 255)
        {
            if (input_buffer[i] == Key_State.Down)
            {
                input_buffer[i] = Key_State.Held;
            }
        }

        for (i in 0 ... temp_input_buffer.length)
        {
            var input = temp_input_buffer.pop();
            input_buffer[input.key] = input.state;
        }
    }
}