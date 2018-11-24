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
	
	public class AuxiliaryTest
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
		 * join によってスレッドの終了を待機できているかどうか。
		 * join の呼び出しによってスレッドが待機状態に入る場合は true それ以外(つまりスレッドがすでに終了している場合)は false が返る。
		 */
		test function join():void
		{
			Static.log = '';
			
			var j:JoinTestThread = new JoinTestThread();
			var t:TesterThread = new TesterThread(j);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run child child child run2 ', Static.log);
				assertTrue(j.join1);
				assertFalse(j.join2);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 待機時間を指定した join で指定時間経過後、timeout で指定した実行関数に移行するかどうか。
		 */
		test function timedJoin():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new TimedJoinTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run joined2 ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 指定した時間以上 sleep できているかどうか。
		 */
		test function sleep():void
		{
			var s:SleepTestThread = new SleepTestThread();
			var t:TesterThread = new TesterThread(s);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertTrue(s.time >= 500);
			}, 1000));
			
			t.start();
		}
	}
}

import org.libspark.thread.Thread;
import flash.utils.getTimer;

class Static
{
	public static var log:String;
}

class JoinTestThread extends Thread
{
	public var join1:Boolean = false;
	public var join2:Boolean = false;
	
	private var _thread:Thread;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		_thread = new JoinChildThread();
		_thread.start();
		
		join1 = _thread.join();
		
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
		
		join2 = _thread.join();
	}
}

class JoinChildThread extends Thread
{
	private var _count:uint = 0;
	
	override protected function run():void
	{
		Static.log += 'child ';
		
		if (++_count < 3) {
			next(run);
		}
	}
}

class TimedJoinTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'run ';
		var t:Thread = new Thread();
		t.start();
		t.join(20);
		next(joined1);
		timeout(joined2);
	}
	
	private function joined1():void
	{
		Static.log += 'joined1 ';
	}
	
	private function joined2():void
	{
		Static.log += 'joined2 ';
	}
}

class SleepTestThread extends Thread
{
	public var time:uint = 0;
	private var _t:uint;
	
	override protected function run():void
	{
		_t = getTimer();
		
		sleep(500);
		next(slept);
	}
	
	private function slept():void
	{
		time = getTimer() - _t;
	}
}