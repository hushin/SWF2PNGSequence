package org.libspark.thread
{
	import flash.events.Event;
	import org.libspark.as3unit.assert.*;
	import org.libspark.as3unit.before;
	import org.libspark.as3unit.after;
	import org.libspark.as3unit.test;
	import org.libspark.as3unit.test_expected;
	
	use namespace before;
	use namespace after;
	use namespace test;
	use namespace test_expected;
	
	public class EventTest
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
		 * イベントハンドラが正しく動作するか。
		 * イベントハンドラが設定された場合かつ next が設定されていない場合は、自動的に待機状態になる。
		 * イベントが来るとスレッドは起床し、指定されたイベントハンドラを次の実行関数に設定する。
		 * 複数のイベントハンドラが設定されていた場合、最初に起きたイベントのみ有効となる。
		 * 次の実行関数が実行される際に、イベントハンドラの設定はリセットされる。
		 */
		test function event():void
		{
			Static.log = '';
			
			var e:EventTestThread = new EventTestThread();
			var t:TesterThread = new TesterThread(e);
			
			t.addEventListener(Event.COMPLETE, async(function(ev:Event):void
			{
				assertEquals('run dispatch hoge finalize ', Static.log);
				assertNotNull(e.e);
				assertSame(e.ev.type, e.e.type);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 既に wait している状態でもイベントハンドラを仕掛けることが出来るか
		 */
		test function waitAndEvent():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new WaitAndEventTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(ev:Event):void
			{
				assertEquals('run dispatch event finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * イベントハンドラが設定されている場合でも、 next が設定された場合は待機状態にならずに動作することができるか
		 */
		test function nextAndEvent():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new NextAndEventTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run run run dispatch event finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
	}
}

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.utils.setTimeout;
import org.libspark.thread.Thread;
import org.libspark.thread.ThreadState;

class Static
{
	public static var log:String;
}

class EventTestThread extends Thread
{
	public var dispatcher:IEventDispatcher = new EventDispatcher();
	public var ev:Event = new Event('hoge');
	public var e:Event;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		event(dispatcher, 'hoge', hogeEvent);
		event(dispatcher, 'fuga', fugaEvent);
		
		setTimeout(dispatch, 100);
	}
	
	private function hogeEvent(e:Event):void
	{
		Static.log += 'hoge ';
		
		this.e = e;
	}
	
	private function fugaEvent(e:Event):void
	{
		Static.log += 'fuga ';
	}
	
	private function dispatch():void
	{
		Static.log += 'dispatch ';
		
		dispatcher.dispatchEvent(ev);
		dispatcher.dispatchEvent(new Event('fuga'));
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class WaitAndEventTestThread extends Thread
{
	private var _dispatcher:IEventDispatcher = new EventDispatcher();
	
	override protected function run():void 
	{
		Static.log += 'run ';
		
		event(_dispatcher, 'myEvent', myEventHandler);
		wait();
		
		setTimeout(dispatch, 100);
	}
	
	private function myEventHandler(e:Event):void
	{
		Static.log += 'event ';
	}
	
	override protected function finalize():void 
	{
		Static.log += 'finalize ';
	}
	
	private function dispatch():void
	{
		Static.log += 'dispatch ';
		
		_dispatcher.dispatchEvent(new Event('myEvent'));
	}
}

class NextAndEventTestThread extends Thread
{
	private var _dispatcher:IEventDispatcher = new EventDispatcher();
	private var _count:uint = 0;
	
	override protected function run():void 
	{
		Static.log += 'run ';
		
		event(_dispatcher, 'myEvent', myEventHandler);
		next(run);
		
		if (++_count == 3) {
			new EventFireThread(_dispatcher).start();
		}
	}
	
	private function myEventHandler(e:Event):void
	{
		Static.log += 'event ';
	}
	
	override protected function finalize():void 
	{
		Static.log += 'finalize ';
	}
}

class EventFireThread extends Thread
{
	public function EventFireThread(dispatcher:IEventDispatcher)
	{
		_dispatcher = dispatcher;
	}
	
	private var _dispatcher:IEventDispatcher;
	
	override protected function run():void
	{
		Static.log += 'dispatch ';
		
		_dispatcher.dispatchEvent(new Event('myEvent'));
	}
}