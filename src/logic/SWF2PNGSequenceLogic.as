package logic
{
	import flash.desktop.ClipboardFormats;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	
	import mx.collections.ArrayList;
	import mx.controls.Alert;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.managers.DragManager;
	import mx.managers.PopUpManager;
	
	import org.libspark.thread.EnterFrameThreadExecutor;
	import org.libspark.thread.Thread;

	public class SWF2PNGSequenceLogic extends Logic
	{
		//--------------------------------------
		// Const
		//--------------------------------------

		//--------------------------------------
		// Constructor
		//--------------------------------------
		public function SWF2PNGSequenceLogic()
		{
			super();
		}
		private var _settingWindow:SettingWindow;

		//--------------------------------------
		// Initialization
		//--------------------------------------
		public function get settingWindow():SettingWindow
		{
			return _settingWindow;
		}

		override protected function onCreationCompleteHandler(event:FlexEvent):void
		{
			_settingWindow = new SettingWindow();
			PopUpManager.addPopUp(settingWindow, view);
			PopUpManager.removePopUp(settingWindow);
			Thread.initialize(new EnterFrameThreadExecutor());
			var main:MainThread = new MainThread(this);
			main.start();
		}

		//--------------------------------------
		// Method
		//--------------------------------------
		public function log(text:String):void
		{
			_settingWindow.logArea.appendText(view.dateTimeFormatter.format(new Date()) + text + "\n");
		}
		//--------------------------------------
		// View-Logic Binding
		//--------------------------------------
		/** 画面 */
		public var _view:SWF2PNGSequence;

		/**
		 * 画面を取得します
		 */
		public function get view():SWF2PNGSequence
		{
			if (_view == null) {
				_view = super.document as SWF2PNGSequence;
			}
			return _view;
		}

		/**
		 * 画面をセットします
		 *
		 * @param view セットする画面
		 */
		public function set view(view:SWF2PNGSequence):void
		{
			_view = view;
		}
	}
}
