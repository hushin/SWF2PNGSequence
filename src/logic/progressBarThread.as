package logic
{
	import flash.utils.getTimer;
	import org.libspark.thread.Thread;
	import org.libspark.thread.utils.IProgress;

	public class progressBarThread extends Thread
	{
		public function progressBarThread(progress:IProgress, window:MyProgressWindow, fileName:String)
		{
			_progress = progress;
			_window = window;
			_fileName = fileName;
			_window.button.label = "キャンセル";
			_startTime = getTimer();
		}
		private var _progress:IProgress;
		private var _window:MyProgressWindow;
		private var _fileName:String;
		private var _startTime:int;

		override protected function run():void
		{
			_window.progressBar.setProgress(_progress.current, _progress.total);
			_window.progressBar.label = _fileName + "を変換中 (" + int(_progress.percent * 100) + "%) :" + _progress.current + "/" + _progress.total;
			_window.labelTime.text = pastTimeStr()  + " : 予想終了時間 残り" + restTimeStr();
			if (_progress.isCompleted) {
				_window.progressBar.label = "変換が完了しました";
				_window.labelTime.text = pastTimeStr();
				_window.button.label = "OK";
				return;
			} else if (_progress.isFailed || _progress.isCanceled) {
				_window.progressBar.label = "えらー!";
				return;
			}
			next(run);
		}

		private function pastTime():int
		{
			return getTimer() - _startTime;
		}

		private function pastTimeStr():String
		{
			return convertSecond(Math.floor(pastTime() / 100) / 10) + "経過";
		}

		private function restTimeStr():String
		{
			return convertSecond(Math.floor((pastTime() * (1 / (_progress.percent) - 1)) / 100) / 10);
		}

		private function convertSecond(totalSecond:Number):String
		{
			var hour:int = Math.floor(totalSecond / 3600);
			var minute:int = Math.floor((totalSecond / 60) % 60);
			var second:Number = Math.floor(totalSecond % 60 * 10) / 10;
			var text:String = "";
			text += (hour == 0) ? "" : hour.toString() + "時間";
			text += (minute == 0) ? "" : minute.toString() + "分";
			text += second.toFixed(1) + "秒";
			return text;
		}
	}
}
