package org.libspark.thread
{
	import flash.events.Event;
	import org.libspark.as3unit.assert.*;
	import org.libspark.as3unit.before;
	import org.libspark.as3unit.after;
	import org.libspark.as3unit.test;
	import org.libspark.as3unit.ignore;
	
	use namespace before;
	use namespace after;
	use namespace test;
	use namespace ignore;
	
	public class MonitorTest
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
		 * wait を呼び出して待機しているスレッドが notify の呼び出しで起きるかどうか。
		 * 待機しているスレッドのうち、ひとつだけが起きる。
		 */
		test function notify():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new NotifyTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run wait wait notify wakeup notify wakeup ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * wait を呼び出して待機しているスレッドが notifyAll の呼び出しで起きるかどうか。
		 * 待機しているスレッドのすべてが起きる。
		 */
		test function notifyAll():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new NotifyAllTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run wait wait notifyAll wakeup wakeup ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * wait で待機中のスレッドの state が WAITING になっているかどうか。
		 * スレッドが起きた後は RUNNABLE に戻る。
		 */
		test function state():void
		{
			var s:StateTestThread = new StateTestThread();
			var t:TesterThread = new TesterThread(s);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals(ThreadState.WAITING, s.state1);
				assertEquals(ThreadState.RUNNABLE, s.state2);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 待機時間を設定した wait で指定時間経過後、timeout で指定した実行関数に移行するかどうか。
		 * 
		 */
		test function timeout():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new TimeoutTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run wait wakeup2 notify ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 待機時間を設定した wait で待機中のスレッドの state が TIMED_WAITING になっているかどうか。
		 * スレッドが起きた後は RUNNABLE に戻る。
		 */
		test function timedState():void
		{
			var s:TimedStateTestThread = new TimedStateTestThread();
			var t:TesterThread = new TesterThread(s);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals(ThreadState.TIMED_WAITING, s.state1);
				assertEquals(ThreadState.RUNNABLE, s.state2);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 終了フェーズに入る直前で wait した場合きちんと動作するかどうか。
		 */
		test function waitFinalize():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new WaitFinalizeTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('wait notifyAll finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 終了フェーズに入る直前で wait がタイムアウトした場合きちんと動作するかどうか。
		 */
		test function timeoutFinalize():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new TimeoutFinaizeTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('wait finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 終了直前で wait した場合きちんと動作するかどうか。
		 */
		test function finalizeWait():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new FinalizeWaitTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('finalize notifyAll ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 終了直前で wait がタイムアウトした場合きちんと動作するかどうか。
		 */
		test function finalizeTimeout():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new FinalizeTimeoutTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 終了直前で wait がタイムアウトした場合タイムアウトハンドラを実行して終了できるかどうか。
		 */
		test function finalizeTimeoutHandler():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new FinalizeTimeoutHandlerTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('finalize wakeup ', Static.log);
			}, 1000));
			
			t.start();
		}
	}
}

import flash.events.Event;
import org.libspark.thread.Thread;
import org.libspark.thread.ThreadState;
import org.libspark.thread.IMonitor;
import org.libspark.thread.Monitor;

import flash.utils.setTimeout;

class Static
{
	public static var log:String;
}

class NotifyTestThread extends Thread
{
	private var _monitor:IMonitor;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		_monitor = new Monitor();
		new WaitThread(_monitor).start();
		new WaitThread(_monitor).start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run3);
	}
	
	private function run3():void
	{
		next(run4);
	}
	
	private function run4():void
	{
		Static.log += 'notify ';
		_monitor.notify();
		next(run5);
	}
	
	private function run5():void
	{
		Static.log += 'notify ';
		_monitor.notify();
		next(run6);
	}
	
	private function run6():void
	{
		
	}
}

class NotifyAllTestThread extends Thread
{
	private var _monitor:IMonitor;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		_monitor = new Monitor();
		new WaitThread(_monitor).start();
		new WaitThread(_monitor).start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run3);
	}
	
	private function run3():void
	{
		next(run4);
	}
	
	private function run4():void
	{
		Static.log += 'notifyAll ';
		_monitor.notifyAll();
		next(run5);
	}
	
	private function run5():void
	{
	}
}

class StateTestThread extends Thread
{
	public var thread:Thread;
	public var state1:uint = ThreadState.NEW;
	public var state2:uint = ThreadState.NEW;
	
	private var _monitor:IMonitor;
	
	override protected function run():void
	{
		_monitor = new Monitor();
		
		thread = new WaitThread(_monitor);
		thread.start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run3);
	}
	
	private function run3():void
	{
		state1 = thread.state;
		next(run4);
	}
	
	private function run4():void
	{
		_monitor.notifyAll();
		next(run5);
	}
	
	private function run5():void
	{
		state2 = thread.state;
	}
}

class WaitThread extends Thread
{
	public function WaitThread(monitor:IMonitor)
	{
		_monitor = monitor;
	}
	
	private var _monitor:IMonitor;
	
	override protected function run():void
	{
		Static.log += 'wait ';
		_monitor.wait();
		next(wakeup);
	}
	
	private function wakeup():void
	{
		Static.log += 'wakeup ';
		next(run2);
	}
	
	private function run2():void
	{
		
	}
}

class TimeoutTestThread extends Thread
{
	public var thread:TimedWaitThread;
	
	private var _monitor:IMonitor;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		_monitor = new Monitor();
		
		thread = new TimedWaitThread(_monitor);
		thread.start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run3);
	}
	
	private function run3():void
	{
		if (!thread.wu) {
			next(run3);
		}
		else {
			next(run4);
		}
	}
	
	private function run4():void
	{
		Static.log += 'notify ';
		_monitor.notifyAll();
		next(run5);
	}
	
	private function run5():void
	{
	}
}

class TimedStateTestThread extends Thread
{
	public var thread:TimedWaitThread;
	public var state1:uint;
	public var state2:uint;
	
	private var _monitor:IMonitor;
	
	override protected function run():void
	{
		_monitor = new Monitor();
		
		thread = new TimedWaitThread(_monitor);
		thread.start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run3);
	}
	
	private function run3():void
	{
		state1 = thread.state;
		next(run4);
	}
	
	private function run4():void
	{
		if (!thread.wu) {
			next(run4);
		}
		else {
			next(run5);
		}
	}
	
	private function run5():void
	{
		state2 = thread.state;
	}
}

class TimedWaitThread extends Thread
{
	public function TimedWaitThread(monitor:IMonitor)
	{
		_monitor = monitor;
	}
	
	public var wu:Boolean = false;
	
	private var _monitor:IMonitor;
	
	override protected function run():void
	{
		Static.log += 'wait ';
		_monitor.wait(500);
		next(wakeup);
		timeout(wakeup2);
	}
	
	private function wakeup():void
	{
		wu = true;
		Static.log += 'wakeup ';
		next(run2);
	}
	
	private function wakeup2():void
	{
		wu = true;
		Static.log += 'wakeup2 ';
		next(run2);
	}
	
	private function run2():void
	{
		next(run3);
	}
	
	private function run3():void
	{
		
	}
}

class WaitFinalizeTestThread extends Thread
{
	private var _monitor:IMonitor = new Monitor();
	
	override protected function run():void
	{
		Static.log += 'wait ';
		
		_monitor.wait();
		
		setTimeout(timeoutHandler, 100);
	}
	
	private function timeoutHandler():void
	{
		Static.log += 'notifyAll ';
		
		_monitor.notifyAll();
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class TimeoutFinaizeTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'wait ';
		
		new Monitor().wait(100);
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class FinalizeWaitTestThread extends Thread
{
	private var _monitor:IMonitor = new Monitor();
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
		
		_monitor.wait();
		
		setTimeout(timeoutHandler, 500);
	}
	
	private function timeoutHandler():void
	{
		Static.log += 'notifyAll ';
		
		_monitor.notifyAll();
	}
}

class FinalizeTimeoutTestThread extends Thread
{
	override protected function finalize():void
	{
		Static.log += 'finalize ';
		
		new Monitor().wait(100);
	}
}

class FinalizeTimeoutHandlerTestThread extends Thread
{
	override protected function finalize():void
	{
		Static.log += 'finalize ';
		
		new Monitor().wait(100);
		
		timeout(wakeup);
	}
	
	private function wakeup():void
	{
		Static.log += 'wakeup ';
	}
}