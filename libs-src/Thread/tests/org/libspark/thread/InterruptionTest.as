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
	
	public class InterruptionTest
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
		 * 割り込みフラグが正しく設定されるか。
		 * 待機中でない場合は、割り込みハンドラが実行されたり InterruptedError が発生したりすることはない。
		 * 一度 checkInterrupted を呼び出すと、割り込みフラグがクリアされる。
		 */
		test function interrupt():void
		{
			Static.log = '';
			
			var i:InterruptTestThread = new InterruptTestThread();
			var t:TesterThread = new TesterThread(i);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run run2 finalize ', Static.log);
				assertTrue(i.flag1);
				assertTrue(i.flag2);
				assertFalse(i.flag3);
				assertFalse(i.flag4);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * スレッドが待機中に割り込み、かつ割り込みハンドラが設定されている場合、割り込みハンドラが実行されるか。
		 * 割り込みハンドラが実行される場合、割り込みフラグは設定されない。
		 */
		test function interruptedHandler():void
		{
			Static.log = '';
			
			var i:InterruptedHandlerTestThread = new InterruptedHandlerTestThread();
			var t:TesterThread = new TesterThread(i);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run interrupt interrupted finalize ', Static.log);
				assertFalse(i.flag);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * スレッドが待機中に割り込み、かつ割り込みハンドラが設定されていない場合、InterruptedError が発生するか。
		 * InterruptedError が発生する場合、割り込みフラグは設定されない。
		 */
		test function interruptedException():void
		{
			Static.log = '';
			
			var i:InterruptedExceptionTestThread = new InterruptedExceptionTestThread();
			var t:TesterThread = new TesterThread(i);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run interrupt interrupted finalize ', Static.log);
				assertFalse(i.flag);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 割り込みハンドラが実行のたびにリセットされているかどうか
		 */
		test function clearInterruptedHandler():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ClearInterruptedHandlerTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run interrupt runInterrupted interrupt runInterrupted2 finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
	}
}

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.utils.setTimeout;
import org.libspark.thread.errors.InterruptedError;
import org.libspark.thread.Thread;
import org.libspark.thread.ThreadState;

class Static
{
	public static var log:String;
}

class InterruptTestThread extends Thread
{
	public var flag1:Boolean;
	public var flag2:Boolean;
	public var flag3:Boolean;
	public var flag4:Boolean;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		interrupted(runInterrupted);
		
		interrupt();
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
		
		flag1 = isInterrupted;
		flag2 = checkInterrupted();
		flag3 = isInterrupted;
		flag4 = checkInterrupted();
	}
	
	private function runInterrupted():void
	{
		Static.log += 'interrupted ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class InterruptedHandlerTestThread extends Thread
{
	public var flag:Boolean;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		interrupted(runInterrupted);
		
		wait();
		
		setTimeout(doInterrupt, 100);
	}
	
	private function doInterrupt():void
	{
		Static.log += 'interrupt ';
		
		interrupt();
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
	}
	
	private function runInterrupted():void
	{
		Static.log += 'interrupted ';
		
		flag = checkInterrupted();
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class InterruptedExceptionTestThread extends Thread
{
	public var flag:Boolean;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		error(InterruptedError, runInterrupted);
		
		wait();
		
		setTimeout(doInterrupt, 100);
	}
	
	private function doInterrupt():void
	{
		Static.log += 'interrupt ';
		
		interrupt();
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
	}
	
	private function runInterrupted(e:Error, t:Thread):void
	{
		Static.log += 'interrupted ';
		
		flag = checkInterrupted();
		
		next(null);
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class ClearInterruptedHandlerTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'run ';
		
		interrupted(runInterrupted);
		wait();
		
		setTimeout(doInterrupt, 10);
	}
	
	private function doInterrupt():void
	{
		Static.log += 'interrupt ';
		
		interrupt();
	}
	
	private function runInterrupted():void
	{
		Static.log += 'runInterrupted ';
		
		error(InterruptedError, runInterrupted2);
		wait();
		
		setTimeout(doInterrupt, 10);
	}
	
	private function runInterrupted2(e:Error, t:Thread):void
	{
		Static.log += 'runInterrupted2 ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}