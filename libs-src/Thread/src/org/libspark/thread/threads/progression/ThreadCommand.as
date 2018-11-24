/*
 * ActionScript Thread Library
 * 
 * Licensed under the MIT License
 * 
 * Copyright (c) 2008 BeInteractive! (www.be-interactive.org) and
 *                    Spark project  (www.libspark.org)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
package org.libspark.thread.threads.progression
{
	import flash.events.Event;
	import jp.progression.core.commands.Command;
	import org.libspark.thread.Thread;

	/**
	 * Thread を Progression の Command として実行するためのクラスです.
	 * 
	 * <p>コマンドの実行が開始されると、コンストラクタで指定されたスレッドの実行を開始し、
	 * スレッドの実行が終了するとコマンドの実行も終了します。</p>
	 * 
	 * <p>このコマンドに対して割り込みを掛けると、スレッドの interrupt メソッドを呼び出した上で
	 * スレッドの終了を待ちます。</p>
	 * 
	 * <p>スレッド内で例外が発生した場合はコマンドエラーとなります。</p>
	 * 
	 * @author	yossy:beinteractive
	 */
	public class ThreadCommand extends Command
	{
		/**
		 * <p>新しい ThreadCommand クラスのインスタンスを作成します.</p>
		 * <p>Create a new instance of the ThreadCommand class.</p>
		 * 
		 * @param	t	<p>実行するスレッド</p><p>A Thread will be execute</p>
		 * @param	initObject	<p>設定したいプロパティを含んだオブジェクト</p><p>A object contains properties</p>
		 * @langversion	3.0
		 * @playerversion	Flash 9.0.45.0
		 */
		public function ThreadCommand(t:Thread, initObject:Object = null)
		{
			super(_execute, _interrupt, initObject);
			
			_adapterThread = new AdapterThread(t);
		}
		
		private var _adapterThread:AdapterThread;
		
		/**
		 * 実行されるコマンドの実装です.
		 * 
		 * @private
		 */
		private function _execute():void
		{
			_adapterThread.dispatcher.addEventListener(Event.COMPLETE, _complete);
			_adapterThread.start();
		}
		
		/**
		 * 中断実行されるコマンドの実装です.
		 * 
		 * @private
		 */
		private function _interrupt():void
		{
			if (_adapterThread.dispatcher.hasEventListener(Event.COMPLETE)) {
				_adapterThread.dispatcher.removeEventListener(Event.COMPLETE, _complete);
				_adapterThread.dispatcher.addEventListener(Event.COMPLETE, _completeInterrupt);
				_adapterThread.cancel();
			}
			else {
				interruptComplete();
			}
		}
		
		/**
		 * スレッドの実行が完了すると送出されます.
		 * 
		 * @private
		 */
		private function _complete(e:Event):void
		{
			_adapterThread.dispatcher.removeEventListener(Event.COMPLETE, _complete);
			
			if (_adapterThread.err != null) {
				catchError(this, _adapterThread.err as Error);
			}
			else {
				executeComplete();
			}
		}
		
		/**
		 * スレッドの実行が完了すると送出されます.
		 * 
		 * @private
		 */
		private function _completeInterrupt(e:Event):void
		{
			_adapterThread.dispatcher.removeEventListener(Event.COMPLETE, _completeInterrupt);
			
			if (_adapterThread.err != null) {
				catchError(this, _adapterThread.err as Error);
			}
			else {
				interruptComplete();
			}
		}
		
		/**
		 * <p>この ThreadCommand インスタンスのコピーを作成して、各プロパティの値を元のプロパティの値と一致するように設定します.</p>
		 * <p>Create a copy of this instance of the ThreadCommand and set each properties to same as original.</p>
		 * 
		 * @return	<p>この ThreadCommand インスタンスのコピー</p><p>A copy of this instance of the ThreadCommand</p>
		 * @langversioin	3.0
		 * @playerversion	Flash 9.0.45.0
		 */
		override public function clone():Command
		{
			return new ThreadCommand(_adapterThread.thread, this);
		}
	}
}

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import org.libspark.thread.Thread;
import flash.utils.setTimeout;
import org.libspark.thread.ThreadState;

class AdapterThread extends Thread
{
	public function AdapterThread(t:Thread)
	{
		thread = t;
		err = null;
		dispatcher = new EventDispatcher();
	}
	
	public var thread:Thread;
	public var err:Object;
	public var dispatcher:IEventDispatcher;
	
	public function cancel():void
	{
		thread.interrupt();
	}
	
	override protected function run():void
	{
		error(Object, errorHandler);
		if (thread.state == ThreadState.NEW) {
			thread.start();
		}
		thread.join();
	}
	
	private function errorHandler(e:Object, t:Thread):void
	{
		err = e;
		next(null);
	}
	
	override protected function finalize():void
	{
		setTimeout(completeHandler, 1);
	}
	
	private function completeHandler():void
	{
		dispatcher.dispatchEvent(new Event(Event.COMPLETE));
	}
}