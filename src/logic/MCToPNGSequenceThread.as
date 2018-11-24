package logic
{

	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.libspark.swfassist.swf.structures.Rect;
	import org.libspark.thread.Thread;
	import org.libspark.thread.utils.IProgress;
	import org.libspark.thread.utils.IProgressNotifier;
	import org.libspark.thread.utils.Progress;

	public class MCToPNGSequenceThread extends Thread implements IProgressNotifier
	{
		public function MCToPNGSequenceThread(r:MovieClip, progress:Progress, setting:ExportSetting)
		{
			_root = r;
			_progress = progress;
			_setting = setting;
			_base = new MovieClip();
			_base.width = _root.width;
			_base.height = _root.height;
		}
		private var _root:MovieClip;
		private var _base:MovieClip;
		private var _progress:Progress;
		private var _setting:ExportSetting;

		public function get progress():IProgress
		{
			return _progress;
		}

		override protected function run():void
		{
			// 仕事の開始を通知します
			// 引数には、行うべき仕事量の合計を渡します
			_progress.start(_setting.endFrame - _setting.startFrame + 1);
			event(_root, Event.ENTER_FRAME, initialHandler);
		}

		private function initialHandler(e:Event):void
		{
			//ここまで来たらロード完了らしい
			//Memo  http://wiki.minaco.net/index.php?Flash%2F%E3%83%89%E3%82%AD%E3%83%A5%E3%83%A1%E3%83%B3%E3%83%88%E3%82%AF%E3%83%A9%E3%82%B9%E8%B6%85%E8%A7%A3%E8%AA%AC
			if (_root.currentFrame >= 3)
			{
				next(init);
			}
			else
			{
				_root.play(); // stopを入れるやつを無視 //0.9.3a
				event(_root, Event.ENTER_FRAME, initialHandler);
			}
		}

		private function init():void
		{
			_root.gotoAndStop(1);
			while (_root.currentFrame < _setting.startFrame)
			{
				_root.nextFrame();
			}
			//MCの再生位置を1フレームから再生したように進める
			initFrameAllChildren(_root);
			_root.parent.addChild(_base); //test
			_root.parent.removeChild(_root); //表示されないようにremoveする
			_root.visible = true;  
			_base.addChild(_root);
			next(captureImage);
		}

		private function captureImage():void
		{
			saveCaptureBitmap();
			nextFrameAllChildren(_root); //MC内のフレームを次に進める
			next(captureImageAfter);
			error(IOError, IOErrorHandler);
			error(SecurityError, SecurityErrorHandler);
		}

		private function captureImageAfter():void
		{
			if (checkInterrupted())
			{
				//割り込みが入ったら終了
				return;
			}
			_progress.progress(_root.currentFrame - _setting.startFrame + 1);
			if (_root.currentFrame == _root.totalFrames || _root.currentFrame >= _setting.endFrame)
			{
				trace("complete!!!!");
				_progress.complete();
				next(null);
			}
			else
			{
				_root.nextFrame(); //メインタイムラインのフレームを次に進める
				stopAllChildren(_root); //なぜかStopさせないとMCが勝手に再生される
				next(captureImage);
				error(IOError, IOErrorHandler);
				error(SecurityError, SecurityErrorHandler);
			}
		}

		//--------------------------------------
		// ハンドラ
		//--------------------------------------
		private function IOErrorHandler(e:IOError, t:Thread):void
		{
			throw new IOError(e.getStackTrace());
		}

		private function SecurityErrorHandler(e:SecurityError, t:Thread):void
		{
			throw new SecurityError(e.getStackTrace());
		}

		//--------------------------------------
		// Methods
		//-------------------------------------
		private function saveCaptureBitmap():void
		{
			//traceFrames();
			var canvas:BitmapData = new BitmapData(_setting.canvasSize.x, _setting.canvasSize.y, _setting.canvasTransparent, _setting.canvasColor);
			canvas.draw(_base, _setting.scaleMatrix);
			if (_setting.canDrawOutFrame)
			{
				//黒ベタを追加
				var drawMCSize:Point = new Point(_root.loaderInfo.width * _setting.scaleMatrix.a, _root.loaderInfo.height * _setting.scaleMatrix.d);
				if (_setting.canvasSize.x > drawMCSize.x)
				{
					//左右に黒ベタ追加
					canvas.fillRect(new Rectangle(0, 0, (_setting.canvasSize.x - drawMCSize.x) / 2, _setting.canvasSize.y), 0xFF000000);
					canvas.fillRect(new Rectangle((_setting.canvasSize.x + drawMCSize.x) / 2, 0, (_setting.canvasSize.x - drawMCSize.x) / 2, _setting.canvasSize.y), 0xFF000000);
				}
				if (_setting.canvasSize.y > drawMCSize.y)
				{
					//上下に黒ベタ追加
					canvas.fillRect(new Rectangle(0, 0, _setting.canvasSize.x, (_setting.canvasSize.y - drawMCSize.y) / 2), 0xFF000000);
					canvas.fillRect(new Rectangle(0, (_setting.canvasSize.y + drawMCSize.y) / 2, _setting.canvasSize.x, (_setting.canvasSize.y - drawMCSize.y) / 2), 0xFF000000);
				}
			}
			var t:SavePNGFileThread = new SavePNGFileThread(canvas, _setting.getFileName(_root.currentFrame));
			t.start();
			//t.wait(50); //適当に間を空ける
		}

		private function traceFrames():void
		{
			trace(_root.currentFrame + "/" + _root.totalFrames);
		}

		private function nextFrameAllChildren(obj:DisplayObjectContainer):void
		{
			var i:int;
			var num:int = obj.numChildren;
			for (i = 0; i < num; i++)
			{
				if (obj.getChildAt(i) is DisplayObjectContainer)
				{
					// コンテナであればさらにその子を再帰で探索
					nextFrameAllChildren(obj.getChildAt(i) as DisplayObjectContainer);
				}
				if (obj.getChildAt(i) is MovieClip)
				{
					// MCなら再生
					nextFrameWithLoop(obj.getChildAt(i) as MovieClip);
				}
			}
		}

		private function initFrameAllChildren(obj:DisplayObjectContainer):void
		{
			var i:int;
			var num:int = obj.numChildren;
			for (i = 0; i < num; i++)
			{
				if (obj.getChildAt(i) is DisplayObjectContainer)
				{
					// コンテナであればさらにその子を再帰で探索
					initFrameAllChildren(obj.getChildAt(i) as DisplayObjectContainer);
				}
				if (obj.getChildAt(i) is MovieClip)
				{
					// MCであれば1フレームから再生
					(obj.getChildAt(i) as MovieClip).gotoAndStop(1);
				}
			}
		}

//		private function playAllChildren(obj:DisplayObjectContainer):void
//		{
//			var i:int;
//			var num:int = obj.numChildren;
//			for (i = 0; i < num; i++) {
//				if (obj.getChildAt(i) is DisplayObjectContainer) {
//					// コンテナであればさらにその子を再帰で探索
//					playAllChildren(obj.getChildAt(i) as DisplayObjectContainer);
//				}
//				if (obj.getChildAt(i) is MovieClip) {
//					(obj.getChildAt(i) as MovieClip).play();
//				}
//			}
//		}
//
		private function stopAllChildren(obj:DisplayObjectContainer):void
		{
			var i:int;
			var num:int = obj.numChildren;
			for (i = 0; i < num; i++)
			{
				if (obj.getChildAt(i) is DisplayObjectContainer)
				{
					// コンテナであればさらにその子を再帰で探索
					stopAllChildren(obj.getChildAt(i) as DisplayObjectContainer);
				}
				if (obj.getChildAt(i) is MovieClip)
				{
					(obj.getChildAt(i) as MovieClip).stop();
				}
			}
		}

		//nextFrameにループ機能を追加
		private function nextFrameWithLoop(mc:MovieClip):void
		{
			if (mc.currentFrame < mc.totalFrames)
			{
				mc.nextFrame();
			}
			else
			{
				mc.gotoAndStop(1);
			}
		}
	}
}
