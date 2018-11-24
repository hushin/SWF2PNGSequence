package org.libspark.thread
{
	import org.libspark.thread.Thread;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	
	public class TesterThread extends Thread
	{
		public function TesterThread(t:Thread, handleError:Boolean = true)
		{
			_t = t;
			_e = new EventDispatcher();
			_handleError = handleError;
		}
		
		private var _t:Thread;
		private var _e:EventDispatcher;
		private var _handleError:Boolean;
		
		public function addEventListener(type:String, func:Function):void
		{
			_e.addEventListener(type, func);
		}
		
		protected override function run():void 
		{
			if (_handleError) {
				error(Object, catchError);
			}
			if (_t != null) {
				_t.start();
				_t.join();
			}
		}
		
		private function catchError(e:Object, t:Thread):void
		{
			next(null);
		}
		
		protected override function finalize():void 
		{
			setTimeout(dispatchHandler, 1);
		}
		
		private function dispatchHandler():void
		{
			_e.dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}