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
	
	public class ExceptionTest
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
		 * 例外が発生した場合に終了フェーズに移行して終了することができるか。
		 */
		test function exception():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * キャッチされない例外が発生した場合に uncaughtErrorHandler が呼び出されるか。
		 */
		test function uncaughtException():void
		{
			Static.log = '';
			
			var u:UncaughtExceptionTestThread = new UncaughtExceptionTestThread();
			var t:TesterThread = new TesterThread(u, false);
			var e:Object;
			var th:Thread;
			
			Thread.uncaughtErrorHandler = function(ee:Object, tt:Thread):void
			{
				e = ee;
				th = tt;
			};
			
			t.addEventListener(Event.COMPLETE, async(function(ev:Event):void
			{
				Thread.uncaughtErrorHandler = null;
				
				assertSame(u.ex, e);
				assertSame(u, th);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 例外が発生した場合に登録されている例外ハンドラを実行できるか。
		 * 例外ハンドラが実行された後は、元の実行関数に戻る。
		 */
		test function exceptionWithHandler():void
		{
			Static.log = '';
			
			var e:ExceptionWithHandlerTestThread = new ExceptionWithHandlerTestThread();
			var t:TesterThread = new TesterThread(e);
			
			t.addEventListener(Event.COMPLETE, async(function(ev:Event):void
			{
				assertEquals('run error run2 finalize ', Static.log);
				assertSame(e.ex, e.e);
				assertSame(e, e.t);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 発生した例外の型によって正しい例外ハンドラを選択することができるか。
		 * 型のマッチはスーパークラスでも有効。
		 */
		test function exceptionHandlerSelect():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionHandlerSelectTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('throw.error error throw.argument argument throw.string string throw.number finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 例外ハンドラ内で次に実行する実行関数を指定した場合、その実行関数に移行することができるか。
		 */
		test function exceptionRecovery():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionRecoveryTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run error run3 finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 次の実行関数に移った際に、前の実行関数で登録された例外ハンドラがリセットされているか。
		 */
		test function exceptionHandlerReset():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionHandlerResetTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run run2 finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * reset = false で例外ハンドラを登録した場合に、リセットされていないか。
		 */
		test function exceptionHandlerNoReset():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionHandlerNoResetTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('run run2 error finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 終了フェーズで例外が発生した場合に親に伝播することができるか。
		 */
		test function exceptionInFinalize():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionInFinalizeTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.finalize p.error p.finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 終了フェーズで例外が発生した場合に例外ハンドラで処理することができるか。
		 */
		test function exceptionInFinalizeWithHandler():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionInFinalizeWithHandlerTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.finalize c.error p.finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 例外ハンドラで例外が発生した場合に親に伝播することができるか。
		 */
		test function exceptionInHandler():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ExceptionInHandlerTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.run c.error p.error ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 子スレッドで発生した例外を親に伝播することができるか。
		 */
		test function childException():void
		{
			Static.log = '';
			
			var c:ChildExceptionTestThread = new ChildExceptionTestThread();
			var t:TesterThread = new TesterThread(c);
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.run p.error c.finalize p.finalize ', Static.log);
				assertSame(c.child.ex, c.e);
				assertSame(c.child, c.t);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 親スレッドが待機中に子スレッドで発生した例外を親に伝播することができるか。
		 */
		test function childExceptionWhileWaiting():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ChildExceptionWhileWaitingTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.run c.run2 p.error c.finalize p.finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 子スレッドで発生した例外を子スレッドの例外ハンドラで処理することができるか。
		 */
		test function childExceptionHandler():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new ChildExceptionHandlerTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.run p.run2 c.error p.finalize c.finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
		
		/**
		 * 孫スレッドで発生した例外を伝播することができるか。
		 */
		test function grandchildException():void
		{
			Static.log = '';
			
			var t:TesterThread = new TesterThread(new GrandchildExceptionTestThread());
			
			t.addEventListener(Event.COMPLETE, async(function(e:Event):void
			{
				assertEquals('p.run c.run p.run2 g.run c.run2 p.run2 g.run2 c.finalize p.error p.finalize g.finalize ', Static.log);
			}, 1000));
			
			t.start();
		}
	}
}

import org.libspark.thread.Thread;
import org.libspark.thread.ThreadState;

class Static
{
	public static var log:String;
}

class ExceptionTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		
		throw new Error();
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class UncaughtExceptionTestThread extends Thread
{
	public var ex:Error = new Error();
	
	override protected function run():void
	{
		throw ex;
	}
}

class ExceptionWithHandlerTestThread extends Thread
{
	public var ex:Error = new Error();
	public var e:Error;
	public var t:Thread;
	
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		error(Error, runError);
		
		throw ex;
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'error ';
		
		this.e = e;
		this.t = t;
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class ExceptionHandlerSelectTestThread extends Thread
{
	override protected function run():void
	{
		error(Error, runError, false);
		error(ArgumentError, runArgumentError, false);
		error(String, runString, false);
		
		next(throwError);
	}
	
	private function throwError():void
	{
		Static.log += 'throw.error ';
		
		throw new Error();
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'error ';
		
		next(throwArgumentError);
	}
	
	private function throwArgumentError():void
	{
		Static.log += 'throw.argument ';
		
		throw new ArgumentError();
	}
	
	private function runArgumentError(e:Error, t:Thread):void
	{
		Static.log += 'argument ';
		
		next(throwString);
	}
	
	private function throwString():void
	{
		Static.log += 'throw.string ';
		
		throw new String('hoge');
	}
	
	private function runString(e:String, t:Thread):void
	{
		Static.log += 'string ';
		
		next(throwNumber);
	}
	
	private function throwNumber():void
	{
		Static.log += 'throw.number ';
		
		throw new Number(1.0);
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class ExceptionRecoveryTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		error(Error, runError);
		
		throw new Error();
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'error ';
		
		next(run3);
	}
	
	private function run3():void
	{
		Static.log += 'run3 ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class ExceptionHandlerResetTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		error(Error, runError);
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
		
		throw new Error();
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'error ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class ExceptionHandlerNoResetTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'run ';
		
		next(run2);
		error(Error, runError, false);
	}
	
	private function run2():void
	{
		Static.log += 'run2 ';
		
		throw new Error();
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'error ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'finalize ';
	}
}

class ExceptionInFinalizeTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		new ExceptionInFinalizeTestChildThread().start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run2);
		error(Error, runError);
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'p.error ';
		
		next(null);
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class ExceptionInFinalizeTestChildThread extends Thread
{
	override protected function finalize():void
	{
		Static.log += 'c.finalize ';
		
		throw new Error();
	}
}

class ExceptionInFinalizeWithHandlerTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		new ExceptionInFinalizeWithHandlerTestChildThread().start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run3);
		error(Error, runError);
	}
	
	private function run3():void
	{
		next(run4);
		error(Error, runError);
	}
	
	private function run4():void
	{
		error(Error, runError);
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'p.error ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class ExceptionInFinalizeWithHandlerTestChildThread extends Thread
{
	override protected function finalize():void
	{
		Static.log += 'c.finalize ';
		
		error(Error, runError);
		
		throw new Error();
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'c.error ';
	}
}

class ExceptionInHandlerTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		new ExceptionInHandlerTestChildThread().start();
		
		next(run2);
	}
	
	private function run2():void
	{
		next(run2);
		error(Error, runError);
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'p.error ';
		
		next(null);
	}
}

class ExceptionInHandlerTestChildThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'c.run ';
		
		error(Error, runError);
		
		throw new Error();
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'c.error ';
		
		throw new Error();
	}
}

class ChildExceptionTestThread extends Thread
{
	public var child:ChildExceptionTestChildThread = new ChildExceptionTestChildThread();
	public var e:Error;
	public var t:Thread;
	
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		child.start();
		
		error(Error, runError);
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'p.error ';
		
		this.e = e;
		this.t = t;
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class ChildExceptionTestChildThread extends Thread
{
	public var ex:Error = new Error();
	
	override protected function run():void
	{
		Static.log += 'c.run ';
		
		throw ex;
	}
	
	override protected function finalize():void
	{
		Static.log += 'c.finalize ';
	}
}

class ChildExceptionWhileWaitingTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		new ChildExceptionWhileWaitingTestChildThread().start();
		
		error(Error, runError);
		wait();
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'p.error ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class ChildExceptionWhileWaitingTestChildThread extends Thread
{
	public var ex:Error = new Error();
	
	override protected function run():void
	{
		Static.log += 'c.run ';
		
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'c.run2 ';
		
		throw ex;
	}
	
	override protected function finalize():void
	{
		Static.log += 'c.finalize ';
	}
}

class ChildExceptionHandlerTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		new ChildExceptionHandlerTestChildThread().start();
		
		error(Error, runError);
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'p.run2 ';
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'p.error ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class ChildExceptionHandlerTestChildThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'c.run ';
		
		error(Error, runError);
		
		throw new Error();
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'c.error ';
	}
	
	override protected function finalize():void
	{
		Static.log += 'c.finalize ';
	}
}

class GrandchildExceptionTestThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'p.run ';
		
		new GrandchildExceptionTestChildThread().start();
		
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'p.run2 ';
		
		next(run2);
		error(Error, runError);
	}
	
	private function runError(e:Error, t:Thread):void
	{
		Static.log += 'p.error ';
		
		next(null);
	}
	
	override protected function finalize():void
	{
		Static.log += 'p.finalize ';
	}
}

class GrandchildExceptionTestChildThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'c.run ';
		
		new GrandchildExceptionTestGrandchildThread().start();
		
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'c.run2 ';
		
		next(run2);
	}
	
	override protected function finalize():void
	{
		Static.log += 'c.finalize ';
	}
}

class GrandchildExceptionTestGrandchildThread extends Thread
{
	override protected function run():void
	{
		Static.log += 'g.run ';
		
		next(run2);
	}
	
	private function run2():void
	{
		Static.log += 'g.run2 ';
		
		throw new Error();
	}
	
	override protected function finalize():void
	{
		Static.log += 'g.finalize ';
	}
}