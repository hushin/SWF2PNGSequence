package logic
{
	import flash.display.Loader;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	import org.libspark.thread.Thread;
	import org.libspark.thread.utils.IProgress;
	import org.libspark.thread.utils.IProgressNotifier;
	import org.libspark.thread.utils.Progress;

	public class ForcibleLoaderThread extends Thread
	{
		public function ForcibleLoaderThread(request:URLRequest, loader:Loader)
		{
			_request = request;
			_loader = loader;
			_floader = new ForcibleLoader(_loader);
		}
		private var _request:URLRequest;
		private var _floader:ForcibleLoader;
		private var _loader:Loader;

		public function get loader():Loader
		{
			return _loader;
		}

		override protected function run():void
		{
			event(_loader.contentLoaderInfo, Event.COMPLETE, completeHandler);
			error(IOError, IOErrorHandler);
			error(SecurityError, SecurityErrorHandler);
			// ロード開始
			_floader.load(_request);
		}

		private function completeHandler(e:Event):void
		{
			// ここでスレッド終了
			trace("this is AVM1Movie");
		}

		private function IOErrorHandler(e:IOError, t:Thread):void
		{
			throw new IOError(e.getStackTrace());
		}

		private function SecurityErrorHandler(e:SecurityError, t:Thread):void
		{
			throw new SecurityError(e.getStackTrace());
		}
	}
}
