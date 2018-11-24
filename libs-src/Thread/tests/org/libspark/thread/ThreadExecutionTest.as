package org.libspark.thread
{
	import flash.events.Event;
	import org.libspark.as3unit.assert.*;
	import org.libspark.as3unit.before;
	import org.libspark.as3unit.after;
	import org.libspark.as3unit.test;
	import org.libspark.as3unit.test_expected;
	import org.libspark.thread.errors.IllegalThreadStateError;
	import org.libspark.thread.errors.ThreadLibraryNotInitializedError;
	
	use namespace before;
	use namespace after;
	use namespace test;
	use namespace test_expected;
	
	public class ThreadExecutionTest
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
		 * start したら run が実行されるか
		 */
		test function start():void
		{
			Static.run = false;
			
			var t:TesterThread = new TesterThread(new StartTestThread());
			
			assertFalse(Static.run);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertTrue(Static.run);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 既に実行しているスレッドを start したら IllegalThreadStateError がスローされるか。
		 */
		test_expected static const startError:Class = IllegalThreadStateError;
		test function startError():void
		{
			var t:Thread = new Thread();
			t.start();
			t.start();
		}
		
		/**
		 * スレッドライブラリが初期化されていない状態で start したら ThreadLibraryNotInitializedError がスローされるか。
		 */
		test_expected static const initializeError:Class = ThreadLibraryNotInitializedError;
		test function initializeError():void
		{
			Thread.initialize(null);
			
			var t:Thread = new Thread();
			t.start();
		}
		
		/**
		 * currentThread にきちんと現在実行中のスレッドが設定されているか。
		 * 実行中のスレッドが無い(擬似スレッドなのでこういうことが起こりうる)場合は null が設定される。
		 */
		test function currentThread():void
		{
			var c:CurrentThreadTestThread = new CurrentThreadTestThread();
			var t:TesterThread = new TesterThread(c);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertSame(c, c.current);
			}, 1000));
			
			assertNull(Thread.currentThread);
			
			t.start();
		}
		
		/**
		 * next による実行関数の切り替えが行えているか。
		 * next を呼び出さない場合、実行フェーズ → 終了フェーズ → 終了 という順で遷移する。
		 * next は finalize の中(終了フェーズ, state == ThreadState.TERMINATING)でも有効。
		 */
		test function next():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new NextTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run run2 run3 finalize finalize2 ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * state が NEW → RUNNABLE → TERMINATING → TERMINATED という順で切り替わっているか。
		 */
		test function state():void
		{
			var s:StateTestThread = new StateTestThread();
			var t:TesterThread = new TesterThread(s);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals(ThreadState.RUNNABLE, s.state1);
				assertEquals(ThreadState.RUNNABLE, s.state2);
				assertEquals(ThreadState.TERMINATING, s.state3);
				assertEquals(ThreadState.TERMINATING, s.state4);
				assertEquals(ThreadState.TERMINATED, s.state);
			}, 1000));
			
			assertEquals(ThreadState.NEW, s.state);
			
			t.start();
		}
		
		/**
		 * 子スレッドが正しく呼び出されているか。
		 * あるスレッドが別のスレッドの start を呼び出した際、start を呼び出したほうのスレッドを親スレッド、start が呼び出されたほうのスレッドを子スレッドと呼ぶ。
		 * 子スレッドは、その親スレッドよりも前に、start された順で実行されることが保証される。
		 */
		test function childThread():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ChildThreadTestParentThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c1.run c2.run p.run2 c1.run2 c2.run2 p.run3 c1.finalize c2.finalize p.finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 孤児スレッドが正しく呼び出されているか。
		 * 子スレッドの終了より先に親スレッドが終了した場合、子スレッドは孤児スレッドとなる。
		 * 孤児スレッドは親スレッドから切り離され、トップレベルに移されて実行が継続される。
		 */
		test function orphanThread():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new OrphanTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.run p.finalize c.run2 c.finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
	}
}

import org.libspark.thread.Thread;
import org.libspark.thread.ThreadState;

class Static
{
	public static var run:Boolean;
	public static var log:String;
}

class StartTestThread extends Thread
{
	override protected function run():void
	{
		Static.run = true;
	}
}

class CurrentThreadTestThread extends Thread
{
	public var current:Thread = null;
	
	override protected function run():void
	{
		current = currentThread;
	}
}

class NextTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'run ';
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
		next(run3);
	}
	
	private function run3():void
	{
		Static.log += 'run3 ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
		next(finalize2);
	}
	
	private function finalize2():void
	{
		Static.log += 'finalize2 ';
	}
}

class StateTestThread extends Thread
{
	public var state1:uint = ThreadState.NEW;
	public var state2:uint = ThreadState.NEW;
	public var state3:uint = ThreadState.NEW;
	public var state4:uint = ThreadState.NEW;
	
	override protected function run():void
	{
		state1 = state;
		next(run2);
	}
	
	private function run2():void
	{
		state2 = state;
	}
	
	override protected function finalize():void
	{
		state3 = state;
		next(finalize2);
	}
	
	private function finalize2():void
	{
		state4 = state;
	}
}

class ChildThreadTestParentThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		new ChildThreadTestChildThread('c1').start();
		new ChildThreadTestChildThread('c2').start();
		
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'p.run2 ';
		next(run3);
	}
	
	private function run3():void
	{
		Static.log += 'p.run3 ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class ChildThreadTestChildThread extends Thread
{
	public function ChildThreadTestChildThread(name:String)
	{
		_name = name;
	}
	
	private var _name:String;
	
	override protected function run():void
	{
		Static.log += _name + '.run ';
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += _name + '.run2 ';
	}
	
	override protected function finalize():void
	{
		Static.log += _name + '.finalize ';
	}
}

class OrphanTestThread extends Thread
{
	private var _c:OrphanTestChildThread;
	
	override protected function run():void
	{
		var t:OrphanTestParentThread = new OrphanTestParentThread();
		_c = t.child;
		t.start();
		next(waitChild);
	}
	
	private function waitChild():void
	{
		if (!_c.isFinished) {
			next(waitChild);
		}
	}
}

class OrphanTestParentThread extends Thread
{
	public var child:OrphanTestChildThread = new OrphanTestChildThread();
	
	override protected function run():void
	{
		Static.log += 'p.run ';
		child.start();
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class OrphanTestChildThread extends Thread
{
	public var isFinished:Boolean = false;
	
	override protected function run():void
	{
		Static.log += 'c.run ';
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'c.run2 ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'c.finalize ';
		isFinished = true;
	}
}