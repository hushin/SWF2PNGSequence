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
package org.libspark.thread.utils
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import org.libspark.thread.utils.events.ProgressEvent;
	
	/**
	 * 保持している進捗状況のうち、どれかひとつでも仕事が進行し、 <code>total</code> プロパティか <code>current</code> プロパティか
	 * <code>percent</code> プロパティのいずれかが更新されると送出されます.
	 * 
	 * @eventType	org.libspark.thread.utils.events.ProgressEvent.UPDATE
	 * @see	org.libspark.thread.utils.IProgress#total
	 * @see	org.libspark.thread.utils.IProgress#current
	 * @see	org.libspark.thread.utils.IProgress#percent
	 */
	[Event(name="update", type="org.libspark.thread.utils.events.ProgressEvent")]
	
	/**
	 * 保持している進捗状況のうち、どれかひとつでも仕事が開始されると送出されます.
	 * 
	 * @eventType	org.libspark.thread.utils.events.ProgressEvent.START
	 * @see	org.libspark.thread.utils.IProgress#isStarted
	 */
	[Event(name="start", type="org.libspark.thread.utils.events.ProgressEvent")]
	
	/**
	 * 保持している全ての進捗状況の仕事が完了すると送出されます.
	 * 
	 * @eventType	org.libspark.thread.utils.events.ProgressEvent.COMPLETED
	 * @see	org.libspark.thread.utils.IProgress#isCompleted
	 */
	[Event(name="completed", type="org.libspark.thread.utils.events.ProgressEvent")]
	
	/**
	 * 保持している進捗状況のうち、どれかひとつでも仕事が失敗すると送出されます.
	 * 
	 * @eventType	org.libspark.thread.utils.events.ProgressEvent.FAILED
	 * @see	org.libspark.thread.utils.IProgress#isFailed
	 */
	[Event(name="failed", type="org.libspark.thread.utils.events.ProgressEvent")]
	
	/**
	 * 保持している進捗状況のうち、どれかひとつでも仕事がキャンセルされると送出されます.
	 * 
	 * @eventType	org.libspark.thread.utils.events.ProgressEvent.CANCELED
	 * @see	org.libspark.thread.utils.IProgress#isCanceled
	 */
	[Event(name="canceled", type="org.libspark.thread.utils.events.ProgressEvent")]
	
	/**
	 * MultiProgress クラスは、複数の進捗状況をひとつにまとめます.
	 * 
	 * <p><code>addProgress</code> メソッドで、進捗状況を追加することができます。</p>
	 * 
	 * @author	yossy:beinteractive
	 * @see	#addProgress()
	 */
	public class MultiProgress extends EventDispatcher implements IProgress
	{
		private var _progresses:Array = [];
		private var _isProgressing:Boolean = false;
		private var _numCompleted:uint = 0;
		private var _isCompleted:Boolean = false;
		private var _isCanceled:Boolean = false;
		private var _isFailed:Boolean = false;
		
		/**
		 * @inheritDoc
		 */
		public function get total():Number
		{
			var total:Number = 0;
			
			for each (var holder:ProgressHolder in _progresses) {
				total += holder.progress.total;
			}
			
			return total;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get current():Number
		{
			var current:Number = 0;
			
			for each (var holder:ProgressHolder in _progresses) {
				current += holder.progress.current;
			}
			
			return current;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get percent():Number
		{
			var percent:Number = 0;
			var factor:Number = 0;
			
			for each (var holder:ProgressHolder in _progresses) {
				percent += holder.progress.percent * holder.factor;
				factor += holder.factor;
			}
			
			percent /= factor != 0 ? factor : 1.0;
			
			return percent;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isStarted():Boolean
		{
			return _isProgressing;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isCompleted():Boolean
		{
			return _isCompleted;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isFailed():Boolean
		{
			return _isFailed;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isCanceled():Boolean
		{
			return _isCanceled;
		}
		
		/**
		 * 進捗状況を追加します.
		 * 
		 * <p><code>factor</code> 引数によって、この仕事の重み付けを設定することができます。デフォルトは <code>1.0</code> で、
		 * 全ての進捗状況の <code>factor</code> が <code>1.0</code> の場合、 <code>MultiProgress</code> クラスの
		 * <code>percent</code> プロパティは、全ての進捗状況の合計を、その個数で等分したもになります。</p>
		 * 
		 * <p><code>factor</code> 引数が <code>1.0</code> 以外に設定される場合、たとえばある進捗状況 A の
		 * <code>factor</code> が <code>1.0</code> で、ある進捗状況 B の <code>factor</code> が
		 * <code>2.0</code> である場合、 <code>MultiProgress</code> クラスの <code>percent</code> プロパティは、
		 * 「<code>(進捗状況 A の percent * 1.0 + 進捗状況 B の percent * 2.0) / (1.0 + 2.0)</code>」という
		 * 計算式で表されることになります。</p>
		 * 
		 * <p><code>total</code> プロパティと <code>current</code> プロパティは <code>factor</code> の影響を受けず、
		 * 単純に全ての進捗状況の該当するプロパティを合計したものになります。</p>
		 * 
		 * @param	progress	追加する進捗状況
		 * @param	factor	進捗状況の重み
		 * @throws	ArgumentError	進捗状況が <code>null</code> の場合
		 */
		public function addProgress(progress:IProgress, factor:Number = 1.0):void
		{
			if (progress == null) {
				throw new ArgumentError('Expected progress is not null.');
			}
			
			registerListener(progress);
			
			_progresses.push(new ProgressHolder(progress, factor));
		}
		
		/**
		 * 追加された進捗状況を削除します.
		 * 
		 * @param	progress	削除する進捗状況
		 * @throws	ArgumentError 指定された <code>progress</code> がこのクラスに追加されたものではない場合
		 */
		public function removeProgress(progress:IProgress):void
		{
			var progresses:Array = _progresses;
			var l:uint = progresses.length;
			for (var i:uint = 0; i < l; ++i) {
				if (ProgressHolder(progresses[i]).progress == progress) {
					unregisterListener(progress);
					progresses.splice(i, 1);
					return;
				}
			}
			
			throw new ArgumentError('Given progress is not added to this class.');
		}
		 
		/**
		 * @private
		 */
		private function registerListener(progress:IProgress):void
		{
			progress.addEventListener(ProgressEvent.START, startHandler);
			progress.addEventListener(ProgressEvent.UPDATE, updateHandler);
			progress.addEventListener(ProgressEvent.COMPLETED, completedHandler);
			progress.addEventListener(ProgressEvent.FAILED, failedHandler);
			progress.addEventListener(ProgressEvent.CANCELED, canceledHandler);
		}
		
		/**
		 * @private
		 */
		private function unregisterListener(progress:IProgress):void
		{
			progress.removeEventListener(ProgressEvent.START, startHandler);
			progress.removeEventListener(ProgressEvent.UPDATE, updateHandler);
			progress.removeEventListener(ProgressEvent.COMPLETED, completedHandler);
			progress.removeEventListener(ProgressEvent.FAILED, failedHandler);
			progress.removeEventListener(ProgressEvent.CANCELED, canceledHandler);
		}
		
		/**
		 * @private
		 */
		private function startHandler(e:Event):void
		{
			// 既に開始されていたら何もしない
			if (_isProgressing) {
				return;
			}
			
			// 初期化
			_isCompleted = false;
			_isCanceled = false;
			_numCompleted = 0;
			// 開始
			_isProgressing = true;
			
			// イベント
			dispatchEvent(new ProgressEvent(ProgressEvent.START));
		}
		
		/**
		 * @private
		 */
		private function updateHandler(e:Event):void
		{
			// 開始されていなければ何もしない
			if (!_isProgressing) {
				return;
			}
			
			// イベント
			dispatchEvent(new ProgressEvent(ProgressEvent.UPDATE));
		}
		
		/**
		 * @private
		 */
		private function completedHandler(e:Event):void
		{
			// 開始されていなければ何もしない
			if (!_isProgressing) {
				return;
			}
			
			// 完了した進捗を追加
			++_numCompleted;
			
			// 全て終わっていなければまだ待つ
			if (_numCompleted < _progresses.length) {
				return;
			}
			
			// 完了
			_isCompleted = true;
			_isCanceled = false;
			_isFailed = false;
			
			// イベント
			dispatchEvent(new ProgressEvent(ProgressEvent.COMPLETED));
		}
		
		/**
		 * @private
		 */
		private function failedHandler(e:Event):void
		{
			// 開始されていなければ何もしない
			if (!_isProgressing) {
				return;
			}
			
			// 失敗
			_isFailed = true;
			_isCompleted = false;
			_isCanceled = false;
			
			// イベント
			dispatchEvent(new ProgressEvent(ProgressEvent.FAILED));
		}
		
		/**
		 * @private
		 */
		private function canceledHandler(e:Event):void
		{
			// 開始されていなければ何もしない
			if (!_isProgressing) {
				return;
			}
			
			// キャンセル
			_isCanceled = true;
			_isCompleted = false;
			_isFailed = false;
			
			// イベント
			dispatchEvent(new ProgressEvent(ProgressEvent.CANCELED));
		}
	}
}

import org.libspark.thread.utils.IProgress;

class ProgressHolder
{
	public function ProgressHolder(progress:IProgress, factor:Number)
	{
		this.progress = progress;
		this.factor = factor;
	}
	
	public var progress:IProgress;
	public var factor:Number;
}