package;

import kha.Assets;
import kha.Scheduler;
import kha.System;

class Main 
{
	public static function main() {
		System.start({title: "Project", width: 1024, height: 768}, function (_) {
			Assets.loadEverything(function () {
				for (i in 0...Assets.images.names.length)
				{
					trace("Asset name: " + Assets.images.names[i]);
				}

				Input.init();
				Game.init();
				
				Scheduler.addTimeTask(function () { Game.update(1 / 60); Input.update(); }, 0, 1 / 60);
				System.notifyOnFrames(function (frames) { Renderer.render_frame(frames[0]); });
			});
		});
	}
}
