package org.libspark.thread
{
	import flash.events.Event;
	import org.libspark.as3unit.assert.*;
	import org.libspark.as3unit.before;
	import org.libspark.as3unit.after;
	import org.libspark.as3unit.test;
	
	use namespace before;
	use namespace after;
	use namespace test;
	
	public class TesterThreadTest
	{
		/**
		 * テストに相互作用が出ないようにテスト毎にスレッドライブラリを初期化。
		 * 通常であれば、initializeの呼び出しは一度きり。
		 */
		before function initialize():void
		{
			Thread.initialize(new EnterFrameThreadExecutor());
		}
		
		/**
		 * 念のため、終了処理もしておく
		 */
		after function finalize():void
		{
			Thread.initialize(null);
		}
		
		/**
		 * TesterThread が終了した際に Event.COMPLETE が配信されるかどうか。
		 */
		test function tester():void
		{
			var t:TesterThread = new TesterThread(null);
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertTrue(true);
			}, 1000));
			t.start();
		}
	}
}