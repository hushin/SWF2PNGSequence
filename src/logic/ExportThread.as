package logic
{
	import flash.display.AVM1Movie;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import mx.controls.Alert;
	import mx.core.Container;
	import org.libspark.thread.Thread;
	import org.libspark.thread.threads.display.LoaderThread;
	import org.libspark.thread.utils.IProgress;
	import org.libspark.thread.utils.IProgressNotifier;
	import org.libspark.thread.utils.Progress;

	public class ExportThread extends Thread implements IProgressNotifier
	{
		public function ExportThread(flexLogic:SWF2PNGSequenceLogic, filePath:String, window:MyProgressWindow)
		{
			_flexLogic = flexLogic;
			_filePath = filePath;
			_progress = new Progress();
			_window = window;
		}
		private var _filePath:String;
		private var _loader:LoaderThread;
		private var _swfContent:DisplayObject;
		private var _progress:Progress;
		private var _window:MyProgressWindow;
		private var _export:MCToPNGSequenceThread;
		private var _flexLogic:SWF2PNGSequenceLogic;
		[Embed(source = "../assets/swf2pngcontainerMC.swf")]
		private var containerClass:Class;
		private var _setting:ExportSetting;
		private var _stream:URLStream;

		public function get progress():IProgress
		{
			return _progress;
		}

		override protected function run():void
		{
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.allowCodeImport = true;
			_loader = new LoaderThread(new URLRequest(_filePath), loaderContext);
			_loader.start();
			_loader.join();
			next(loadComplete);
			interrupted(loadInterrupted);
			error(IOError, IOErrorHandler);
			error(SecurityError, SecurityErrorHandler);
		}

		private function loadComplete():void
		{
			interrupted(loadInterrupted);
			_swfContent = _loader.loader.content;
			if (_swfContent is MovieClip) {
				CONFIG::pro
				{
					var settingFactory:OptionExportSettingFactory = new OptionExportSettingFactory(_flexLogic);
					_setting = settingFactory.create(_swfContent as MovieClip, _filePath);
				}
				CONFIG::trial
				{
					_setting = BasicExportSettingFactory.create(_swfContent as MovieClip, _filePath);
				}
				next(exportStart);
			} else if (_swfContent is AVM1Movie) {
				//ロードしたものが AVM1Movie (AS2.0以前のswf) ならば、別方法でロードし直す
				var floader:ForcibleLoaderThread = new ForcibleLoaderThread(new URLRequest(_filePath), _loader.loader);
				floader.start();
				floader.join();
				_flexLogic.log("AVM1Movie load start");
				next(loadAVM1Complete);
			} else if (_swfContent is DisplayObject) {
				throw new IOError("このSWFファイルには対応しておりません。");
			} else {
				throw new IOError("このSWFファイルには対応しておりません。");
			}
		}

		private function loadAVM1Complete():void
		{
			interrupted(loadInterrupted);
			_swfContent = _loader.loader.content;
			//hoge
			if (_swfContent is MovieClip) {
				CONFIG::pro
				{
					var settingFactory:OptionExportSettingFactory = new OptionExportSettingFactory(_flexLogic);
					_setting = settingFactory.create(_swfContent as MovieClip, _filePath, true);
				}
				CONFIG::trial
				{
					_setting = BasicExportSettingFactory.create(_swfContent as MovieClip, _filePath, true);
				}
				next(exportStart);
			} else {
				throw new IOError("このSWFファイルには対応しておりません。");
			}
		}

		private function exportStart():void
		{
			_flexLogic.view.stage.addChild(_swfContent);
			//ここが怪しかったけど直った？？？
			_swfContent.visible = false;
			
			
//			switch (_flexLogic.settingWindow.rgOutputMethod.selectedValue) {
//				case OptionValue.METHOD_NORMAL:
//					_swfContent.visible = false;
//					break;
//				case OptionValue.METHOD_SLOW:
//					_swfContent.x = 2000;
//					_swfContent.y = 2000;
//					break;
//			}
			var fileName:String;
			_flexLogic.view.fileURLData.source.forEach(function(element:*, index:int, arr:Array):void
			{
				if (String(element.filePath) == _filePath) {
					fileName = element.fileName;
				}
			});
			new progressBarThread(progress, _window, fileName).start();
			_flexLogic.log(fileName + " export start");
			_export = new MCToPNGSequenceThread(_swfContent as MovieClip, _progress, _setting);
			_export.start();
			_export.join();
			next(exportComplete);
			interrupted(loadInterrupted);
			error(IOError, IOErrorHandler);
			error(SecurityError, SecurityErrorHandler);
		}

		private function exportComplete():void
		{
			//スレッド終わり
			//終ったファイルを識別
			_flexLogic.view.fileURLData.source.forEach(function(element:*, index:int, arr:Array):void
			{
				if (String(element.filePath) == _filePath) {
					element.status = "変換完了";
				}
			});
			//無理矢理更新させる
			_flexLogic.view.fileURLData.addItem({});
			_flexLogic.view.fileURLData.removeItem({});
		}

		override protected function finalize():void
		{
//			_flexLogic.view.stage.removeChild(_swfContent);
			_loader.loader.unloadAndStop();
			_loader = null;
		}

		//--------------------------------------
		// ハンドラ
		//--------------------------------------
		private function loadInterrupted():void
		{
			// Interrupted!! を表示して終了
			_export.interrupt();
			_flexLogic.log('Interrupted!!');
		}

		private function IOErrorHandler(e:IOError, t:Thread):void
		{
			throw new IOError(e.getStackTrace());
			next(finalize);
		}

		private function SecurityErrorHandler(e:SecurityError, t:Thread):void
		{
			throw new SecurityError(e.getStackTrace());
			next(finalize);
		}
	}
}
