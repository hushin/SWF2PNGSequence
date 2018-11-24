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
package org.libspark.thread.threads.tweener
{
	import caurina.transitions.Tweener;
	import flash.display.DisplayObject;
	import org.libspark.thread.IMonitor;
	import org.libspark.thread.Monitor;
	import org.libspark.thread.Thread;
	import flash.utils.getTimer;

	/**
	 * Tweener を実行するためのスレッドです.
	 * 
	 * <p>スレッドが開始されると、コンストラクタで指定されたターゲットと引数を用いて Tweener の実行を開始し、
	 * トゥイーンが終了するとスレッドの実行も終了します。</p>
	 * 
	 * <p>スペシャルプロパティとして、以下のプロパティが拡張されています。</p>
	 * <ul>
	 * <li>show: true にすると、トゥイーン開始時に visible プロパティを true にします</li>
	 * <li>hide: true にすると、トゥイーン開始時に visible プロパティを false にします</li>
	 * </ul>
	 * 
	 * @author	yossy:beinteractive
	 */
	public class TweenerThread extends Thread
	{
		/**
		 * 新しい TweenerThread クラスのインスタンスを作成します.
		 * 
		 * @param	target	Tweener に渡す、トゥイーンのターゲット
		 * @param	args	Tweener に渡す、トゥイーンの引数
		 */
		public function TweenerThread(target:Object, args:Object)
		{
			_target = target;
			_args = args;
			_specialArgs = splitSpecialArgs(args);
			_startTime = 0;
			_monitor = new Monitor();
			
			args.onComplete = completeHandler;
		}
		
		private var _target:Object;
		private var _args:Object;
		private var _specialArgs:Object;
		private var _startTime:uint;
		private var _monitor:IMonitor;
		
		/**
		 * トゥイーンが開始されてからの経過時間を返します.
		 * 
		 * <p>まだトゥイーンが開始されていない場合は 0 を返します。</p>
		 */
		public function get time():uint
		{
			return _startTime != 0 ? getTimer() - _startTime : 0;
		}
		
		/**
		 * トゥイーンの実行をキャンセルします.
		 * 
		 * <p>トゥイーンのキャンセルは、 Tweener.removeTweens の呼び出しによって実現されます。</p>
		 */
		public function cancel():void
		{
			interrupt();
		}
		
		/**
		 * @private
		 */
		private function splitSpecialArgs(args:Object):Object
		{
			var result:Object = new Object();
			
			moveSpecialArg('show', args, result);
			moveSpecialArg('hide', args, result);
			
			return result;
		}
		
		/**
		 * @private
		 */
		private function moveSpecialArg(name:String, from:Object, to:Object):void
		{
			if (name in from) {
				to[name] = from[name];
				delete from[name];
			}
		}
		
		/**
		 * @private
		 */
		override protected function run():void
		{
			if ('show' in _specialArgs && _specialArgs.show) {
				if (_target is DisplayObject) {
					DisplayObject(_target).visible = true;
				}
				else {
					if ('visible' in _target) {
						_target.visible = true;
					}
				}
			}
			
			_startTime = getTimer();
			
			Tweener.addTween(_target, _args);
			
			waitTween();
		}
		
		/**
		 * @private
		 */
		private function waitTween():void
		{
			_monitor.wait();
			interrupted(interruptedHandler);
		}
		
		/**
		 * @private
		 */
		private function completeHandler():void
		{
			if ('hide' in _specialArgs && _specialArgs.hide) {
				if (_target is DisplayObject) {
					DisplayObject(_target).visible = false;
				}
				else {
					if ('visible' in _target) {
						_target.visible = false;
					}
				}
			}
			
			_monitor.notifyAll();
		}
		
		/**
		 * @private
		 */
		private function interruptedHandler():void
		{
			if (Tweener.isTweening(_target)) {
				Tweener.removeTweens(_target);
			}
		}
	}
}
