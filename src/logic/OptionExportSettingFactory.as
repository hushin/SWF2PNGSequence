package logic
{
	import flash.filesystem.File;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.errors.IOError;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import mx.controls.Alert;

	public class OptionExportSettingFactory
	{
		private var _flexLogic:SWF2PNGSequenceLogic;
		private var _setting:ExportSetting;

		public function OptionExportSettingFactory(flexLogic:SWF2PNGSequenceLogic)
		{
			_flexLogic = flexLogic;
		}

		public function create(root:DisplayObject, filePath:String, isAVM1Movie:Boolean = false):ExportSetting
		{
			var reg:RegExp = /(.*)[\/\\](.*?)\.swf$/i; //ファイル名を抜き取る正規表現
			_setting = new ExportSetting();
			setFrameSetting(root, isAVM1Movie);
			setScaleSetting(root);
			setBackColor(root);
			_setting.fileName = filePath.replace(reg, "$2");
			_setting.folderURL = _setting.getPngFolderName(getParentFolderURL(filePath));
			_setting.headFileName = getHeadFileName(_setting.fileName);
			return _setting;
		}

		private function getParentFolderURL(filePath:String):String
		{
			var reg:RegExp = /(.*)[\/\\](.*?)\.swf$/i; //ファイル名を抜き取る正規表現
			var url:String;
			//filePath.replace(reg, "$1")
			switch (_flexLogic.settingWindow.rgOutputPath.selectedValue) {
				case OptionValue.PATH_SAME:
					url = filePath.replace(reg, "$1");
					break;
				case OptionValue.PATH_DESKTOP:
					url = File.desktopDirectory.url;
					break;
				case OptionValue.PATH_SELECTABLE:
					url = _flexLogic.settingWindow.txtOutputPath.text;
					if (url.length == 0) {
						throw new IOError("出力フォルダを選択してください。");
					}
					break;
			}
			return url;
		}

		private function getHeadFileName(fileHead:String):String
		{
			var headName:String;
			switch (_flexLogic.settingWindow.rgOutputFileName.selectedValue) {
				case OptionValue.FILENAME_SAME:
					headName = fileHead;
					break;
				case OptionValue.FILENAME_SELECTABLE:
					headName = _flexLogic.settingWindow.txtHeadFileName.text;
					break;
			}
			return headName;
		}

		private function setFrameSetting(root:DisplayObject, isAVM1Movie:Boolean):void
		{
			var start:int;
			var end:int;
			var total:int = (root as MovieClip).totalFrames;
			switch (_flexLogic.settingWindow.rgCaptureFrame.selectedValue) {
				case OptionValue.FRAME_ALL:
					_setting.startFrame = 1;
					_setting.endFrame = (isAVM1Movie) ? total - 2 : total; //AVM1Movieのとき最後の２フレームが上手く書き出せないので減らす
					break;
				case OptionValue.FRAME_SELECT:
					start = int(_flexLogic.settingWindow.txtStartFrame.text);
					end = int(_flexLogic.settingWindow.txtEndFrame.text);
					_setting.startFrame = (start < 1) ? 1 : start;
					if (_flexLogic.settingWindow.txtEndFrame.text.length == 0) {
						_setting.endFrame = total;
					} else {
						_setting.endFrame = (end > total) ? total : end;
					}
					break;
			}
		}

		private function setScaleSetting(root:DisplayObject):void
		{
			var scaleW:Number;
			var scaleH:Number;
			var originalW:Number = root.loaderInfo.width;
			var originalH:Number = root.loaderInfo.height;
			_setting.canDrawOutFrame = true;
			switch (_flexLogic.settingWindow.rgCaptureSize.selectedValue) {
				case OptionValue.SIZE_DEFAULT:
					scaleW = 1;
					scaleH = 1;
					break;
				case OptionValue.SIZE_SCALE:
					scaleW = Number(_flexLogic.settingWindow.txtCaptureScale.text) / 100;
					scaleH = Number(_flexLogic.settingWindow.txtCaptureScale.text) / 100;
					break;
				case OptionValue.SIZE_SELECTABLE:
					var sx:int;
					var sy:int;
					var data:String = _flexLogic.settingWindow.cmbSizeOptions.selectedItem.data;
					switch (data) {
						case OptionValue.SIZE_512X384:
						case OptionValue.SIZE_640X360:
						case OptionValue.SIZE_640X480:
						case OptionValue.SIZE_648X486:
						case OptionValue.SIZE_864X486:
						case OptionValue.SIZE_1280X720:
						case OptionValue.SIZE_1920X1080:
							scaleW = OptionValue.SIZE_SETTINGS[data].x / originalW;
							scaleH = OptionValue.SIZE_SETTINGS[data].y / originalH;
							break;
						case OptionValue.SIZE_COSTUME:
							var captureW:int = int(_flexLogic.settingWindow.txtCaptureWidth.text);
							var captureH:int = int(_flexLogic.settingWindow.txtCaptureHeight.text);
							captureW = (captureW < 2) ? 2 : captureW;
							captureH = (captureH < 2) ? 2 : captureH;
							scaleW = captureW / originalW;
							scaleH = captureH / originalH;
							break;
						case OptionValue.SIZE_NONE:
							throw new IOError("サイズを選択してください。");
							break;
					}
					break;
			}
			//上手く整数になるか心配
			var scale:Number;
			switch (_flexLogic.settingWindow.rgCaptureAspect.selectedValue) {
				case OptionValue.ASPECT_DEFAULT:
					scale = (scaleW < scaleH) ? scaleW : scaleH; //小さい幅に合わせる
					_setting.scaleMatrix.scale(scale, scale);
					_setting.canvasSize.x = originalW * scale;
					_setting.canvasSize.y = originalH * scale;
					break;
				case OptionValue.ASPECT_BLACK:
					scale = (scaleW < scaleH) ? scaleW : scaleH; //小さい幅に合わせる
					_setting.scaleMatrix.scale(scale, scale);
					_setting.canvasSize.x = originalW * scaleW;
					_setting.canvasSize.y = originalH * scaleH;
					_setting.scaleMatrix.translate((_setting.canvasSize.x - originalW * scale) / 2, (_setting.canvasSize.y - originalH * scale) / 2);
					break;
				case OptionValue.ASPECT_STRETCH:
					_setting.scaleMatrix.scale(scaleW, scaleH);
					_setting.canvasSize.x = originalW * scaleW;
					_setting.canvasSize.y = originalH * scaleH;
					break;
				case OptionValue.ASPECT_SELECTABLE:
					_setting.canvasSize.x = originalW * scaleW;
					_setting.canvasSize.y = originalH * scaleH;
					scaleW = Number(_flexLogic.settingWindow.txtScaleWidth.text) / 100;
					scaleH = Number(_flexLogic.settingWindow.txtScaleHeight.text) / 100;
					_setting.scaleMatrix.scale(scaleW, scaleH);
					_setting.scaleMatrix.translate((_setting.canvasSize.x - originalW * scaleW) / 2, (_setting.canvasSize.y - originalH * scaleH) / 2);
					_setting.canDrawOutFrame = false;
					break;
			}
			trace("scale", scaleW, scaleH);
			trace("drawsize", _setting.canvasSize.x, _setting.canvasSize.y);
		}

		private function setBackColor(root:DisplayObject):void
		{
			switch (_flexLogic.settingWindow.rgBackGround.selectedValue) {
				case OptionValue.BACK_WHITE:
					_setting.canvasTransparent = false;
					_setting.canvasColor = 0xFFFFFF;
					break;
				case OptionValue.BACK_WHITE:
					_setting.canvasTransparent = false;
					_setting.canvasColor = 0x000000;
					break;
				case OptionValue.BACK_TRANSPARENT:
					_setting.canvasTransparent = true;
					_setting.canvasColor = 0x000000;
					break;
			}
		}
	}
}
