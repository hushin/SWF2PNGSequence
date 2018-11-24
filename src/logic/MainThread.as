package logic
{
	import flash.desktop.*;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.utils.unescapeMultiByte;
	
	import flashx.textLayout.events.DamageEvent;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.controls.Alert;
	import mx.managers.DragManager;
	import mx.managers.PopUpManager;
	
	import org.libspark.thread.Thread;
	import org.libspark.thread.utils.Progress;
	import org.libspark.thread.utils.SerialExecutor;

	public class MainThread extends Thread
	{
		private var _flexLogic:SWF2PNGSequenceLogic;
		private var _fileOpen:FileOpenThread;
		private var _progressWindow:MyProgressWindow;
		private var _executor:SerialExecutor;

		public function MainThread(flexLogic:SWF2PNGSequenceLogic)
		{
			_flexLogic = flexLogic;
			_fileOpen = null;
		}

		//--------------------------------------
		// イベント待機
		//--------------------------------------
		override protected function run():void
		{
			event(_flexLogic.view.bt_fileSelect, MouseEvent.CLICK, fileSelect);
			event(_flexLogic.view.bt_fileConvert, MouseEvent.CLICK, fileConvert);
			event(_flexLogic.view.bt_fileClear, MouseEvent.CLICK, fileClear);
			event(_flexLogic.view.bt_selectFileClear, MouseEvent.CLICK, fileSelectClear);
			CONFIG::pro
			{
				event(_flexLogic.view.bt_Option, MouseEvent.CLICK, openOption);
				event(_flexLogic.settingWindow, Event.CLOSE, closeSettingWindow);
			}
			CONFIG::trial
			{
				//
				trace("trial");
			}
//			event(_flexLogic.settingWindow.rgCaptureSize, Event.CHANGE, rgSizeChanged);
//			event(_flexLogic.settingWindow.rgCaptureFrame, Event.CHANGE, rgFrameChanged);
			event(_flexLogic.view.panel_Fileload, NativeDragEvent.NATIVE_DRAG_ENTER, dragHandler);
			event(_flexLogic.view.panel_Fileload, NativeDragEvent.NATIVE_DRAG_DROP, dropHandler);
		}

		//--------------------------------------
		// ファイル選択
		//--------------------------------------
		private function fileSelect(e:MouseEvent):void
		{
			_fileOpen = new FileOpenThread();
			_fileOpen.start();
			_fileOpen.join();
			next(fileSelected);
			error(IOError, fileSelectError);
		}

		private function fileSelectError(e:IOError, t:Thread):void
		{
			_flexLogic.log(e.toString());
			// キャンセル・エラーが起きたら選択画面に戻る
			next(run);
		}

		private function fileSelected():void
		{
			addfileURL(_fileOpen.fileURLList);
			_flexLogic.log("File Selected.");
			next(run);
		}

		private function addfileURL(urlList:Array):void
		{
			var url:Object;
			var reg:RegExp = /.*[\/\\](.*?)$/g; //ファイル名を抜き取る正規表現
			for each (url in urlList) {
				_flexLogic.view.fileURLData.addItem({status: "変換前", fileName: unescapeMultiByte(String(url).replace(reg, "$1")), filePath: String(url)});
			}
			//重複があれば削除
			//TODO: もっとコードを分かりやすく
			var item:Object;
			var uniqueObject:Object = {};
			_flexLogic.view.fileURLData.source.forEach(function(element:*, index:int, arr:Array):void
			{
				uniqueObject[element.fileName] = element;
			});
			_flexLogic.view.fileURLData.removeAll();
			for each (item in uniqueObject) {
				_flexLogic.view.fileURLData.addItem(item);
			}
		}

		private function fileClear(e:MouseEvent):void
		{
			_flexLogic.view.fileURLData.removeAll();
			next(run);
		}

		private function fileSelectClear(e:MouseEvent):void
		{
			if (_flexLogic.view.grid_fileList.selectedIndex != -1) {
				_flexLogic.view.fileURLData.removeItemAt(_flexLogic.view.grid_fileList.selectedIndex);
			}
			next(run);
		}

		private function openOption(e:MouseEvent):void
		{
			PopUpManager.addPopUp(_flexLogic.settingWindow, _flexLogic.view);
//			PopUpManager.centerPopUp(_flexLogic.settingWindow);
			_flexLogic.view.width = 940;
			_flexLogic.settingWindow.x = 520;
			_flexLogic.settingWindow.y = 20;
			next(run);
		}
		
		private function closeSettingWindow(e:Event):void
		{
			PopUpManager.removePopUp(_flexLogic.settingWindow);
			_flexLogic.view.width = 514;
			next(run);
		}

		private function dragHandler(e:NativeDragEvent):void
		{
//			_flexLogic.log(e.toString());
			if (e.clipboard == null) {
				next(run);
				return;
			}
			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
				//get the array of files
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if (files.length >= 1) {
					//accept the drag action
					_flexLogic.log("accept drag drop");
					DragManager.acceptDragDrop(_flexLogic.view.panel_Fileload);
				}
			}
			next(run);
		}

		private function dropHandler(e:NativeDragEvent):void
		{
			_flexLogic.log(e.toString());
			if (e.clipboard == null || e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) == null) {
				next(run);
				return;
			}
			var dropfiles:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			var fileURLList:Array = new Array();
			var file:File;
			for (var i:uint = 0; i < dropfiles.length; i++) {
				_flexLogic.log("dragged:" + dropfiles[i].url);
				file = dropfiles[i];
				if (file.extension == "swf") {
					fileURLList.push(dropfiles[i].url);
				}
			}
			addfileURL(fileURLList);
			next(run);
		}

		//--------------------------------------
		// ラジオボタンイベントハンドラ
		//--------------------------------------
//		private function rgSizeChanged(e:Event):void
//		{
//			//TODO:データバインダーでやればよかった
//			switch (_flexLogic.settingWindow.rgCaptureSize.selectedValue) {
//				case OptionValue.SIZE_SCALE:
//					_flexLogic.settingWindow.txtCaptureScale.enabled = true;
//					_flexLogic.settingWindow.txtCaptureHeight.enabled = false;
//					_flexLogic.settingWindow.txtCaptureWidth.enabled = false;
//					break;
//				case OptionValue.SIZE_SELECTABLE:
//					_flexLogic.settingWindow.txtCaptureScale.enabled = false;
//					_flexLogic.settingWindow.txtCaptureHeight.enabled = true;
//					_flexLogic.settingWindow.txtCaptureWidth.enabled = true;
//					break;
//				default:
//					_flexLogic.settingWindow.txtCaptureScale.enabled = false;
//					_flexLogic.settingWindow.txtCaptureHeight.enabled = false;
//					_flexLogic.settingWindow.txtCaptureWidth.enabled = false;
//			}
//			next(run);
//		}
//
//		private function rgFrameChanged(e:Event):void
//		{
//			//TODO:データバインダーでやればよかった
//			switch (_flexLogic.settingWindow.rgCaptureFrame.selectedValue) {
//				case OptionValue.FRAME_SELECT:
//					_flexLogic.settingWindow.txtStartFrame.enabled = true;
//					_flexLogic.settingWindow.txtEndFrame.enabled = true;
//					break;
//				default:
//					_flexLogic.settingWindow.txtStartFrame.enabled = false;
//					_flexLogic.settingWindow.txtEndFrame.enabled = false;
//			}
//			next(run);
//		}
		//--------------------------------------
		// ファイル変換
		//--------------------------------------
		private function fileConvert(e:MouseEvent):void
		{
			if (_flexLogic.view.fileURLData.length == 0) {
				//ファイルの数が0
				Alert.show("SWFファイルを選択してください。");
				next(run);
			} else if (_flexLogic.settingWindow.cmbSizeOptions.enabled && (_flexLogic.settingWindow.cmbSizeOptions.selectedIndex == -1 || _flexLogic.settingWindow.cmbSizeOptions.selectedItem.data == OptionValue.SIZE_NONE)) {
				Alert.show("サイズを選択してください。");
				next(run);
			} else if (_flexLogic.settingWindow.txtOutputPath.enabled == true && _flexLogic.settingWindow.txtOutputPath.text.length == 0) {
				Alert.show("出力フォルダを選択してください。");
				next(run);
			} else {
				//show window...
				showProgressWindow();
				_executor = new SerialExecutor();
				_flexLogic.view.fileURLData.source.forEach(function(element:*, index:int, arr:Array):void
				{
					//各swfに対して変換実行
					if (element.status == "変換前") {
						_executor.addThread(new ExportThread(_flexLogic, element.filePath, _progressWindow));
					}
				});
				_flexLogic.log("SWF File export START.");
				if (_executor.numThreads == 0) {
					removeProgressWindow();
					Alert.show("SWFファイルは既に変換済みです");
					next(run);
				} else {
					_executor.start();
					_executor.join();
					next(loadComplete);
				}
				error(IOError, IOErrorHandler);
				error(SecurityError, SecurityErrorHandler);
			}
		}

		private function loadComplete():void
		{
			_flexLogic.log("SWF File exported.");
			event(_progressWindow.button, MouseEvent.CLICK, loadCompleteOk);
		}

		private function IOErrorHandler(e:IOError, t:Thread):void
		{
			//例外を出力して終了
			_flexLogic.log(e.getStackTrace());
			Alert.show(e.toString());
			_executor.interrupt();
			PopUpManager.removePopUp(_progressWindow);
			next(run);
		}

		private function SecurityErrorHandler(e:SecurityError, t:Thread):void
		{
			//例外を出力して終了
			_flexLogic.log(e.getStackTrace());
			Alert.show(e.toString());
			_executor.interrupt();
			PopUpManager.removePopUp(_progressWindow);
			next(run);
		}

		//--------------------------------------
		// Progress Window
		//--------------------------------------
		private function showProgressWindow():void
		{
			_progressWindow = PopUpManager.createPopUp(_flexLogic.view, MyProgressWindow, true) as MyProgressWindow;
			event(_progressWindow, Event.REMOVED_FROM_STAGE, progressWindowRemoveHandler);
			event(_progressWindow.button, MouseEvent.CLICK, cancel);
		}

		private function removeProgressWindow():void
		{
			PopUpManager.removePopUp(_progressWindow);
		}

		private function progressWindowRemoveHandler(event:Event):void
		{
			_flexLogic.log(event.toString());
			_progressWindow = null;
			//処理の中断コード
			next(run);
		}

		private function cancel(event:MouseEvent):void
		{
			_flexLogic.log('Canceled');
			_executor.interrupt();
			PopUpManager.removePopUp(_progressWindow);
			next(run);
		}

		private function loadCompleteOk(event:MouseEvent):void
		{
			_flexLogic.log('OK Clicked');
			PopUpManager.removePopUp(_progressWindow);
			next(run);
		}
	}
}
