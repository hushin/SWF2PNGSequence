package logic
{
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.geom.Point;

	public class ExportSetting
	{
		public function ExportSetting()
		{
			_scaleMatrix = new Matrix();
			_scaleMatrix.identity(); //正規化
			_canvasSize = new Point();
		}
		private var _scaleMatrix:Matrix; //拡大行列
		private var _startFrame:int;
		private var _endFrame:int;
		private var _canvasSize:Point;
//		private var _outputPath:File;
		private var _fileName:String;
		private var _folderURL:String; //pngを書きだすフォルダ
		private var _canvasTransparent:Boolean;
		private var _canvasColor:uint;
		private var _headFileName:String;
		private var _canDrawOutFrame:Boolean;

		public function get canvasTransparent():Boolean
		{
			return _canvasTransparent;
		}

		public function set canvasTransparent(value:Boolean):void
		{
			_canvasTransparent = value;
		}

		public function get folderURL():String
		{
			return _folderURL;
		}

		public function set folderURL(value:String):void
		{
			_folderURL = value;
		}

		public function get canvasColor():uint
		{
			return _canvasColor;
		}

		public function set canvasColor(value:uint):void
		{
			_canvasColor = value;
		}

		public function get canDrawOutFrame():Boolean
		{
			return _canDrawOutFrame;
		}

		public function set canDrawOutFrame(value:Boolean):void
		{
			_canDrawOutFrame = value;
		}

		public function get headFileName():String
		{
			return _headFileName;
		}

		public function set headFileName(value:String):void
		{
			_headFileName = value;
		}

		public function get fileName():String
		{
			return _fileName;
		}

		public function set fileName(value:String):void
		{
			_fileName = value;
		}

//
//		public function get outputPath():File
//		{
//			return _outputPath;
//		}
//
//		public function set outputPath(value:File):void
//		{
//			_outputPath = value;
//		}
		public function get canvasSize():Point
		{
			return _canvasSize;
		}

		public function set canvasSize(value:Point):void
		{
			_canvasSize = value;
		}

		public function get endFrame():int
		{
			return _endFrame;
		}

		public function set endFrame(value:int):void
		{
			_endFrame = value;
		}

		public function get startFrame():int
		{
			return _startFrame;
		}

		public function set startFrame(value:int):void
		{
			_startFrame = value;
		}

		public function get scaleMatrix():Matrix
		{
			return _scaleMatrix;
		}

		public function set scaleMatrix(value:Matrix):void
		{
			_scaleMatrix = value;
		}

		public function getPngFolderName(parentfolderURL:String, num:int = 0):String
		{
			var folderName:String;
			if (num == 0) {
				folderName = parentfolderURL + "/" + _fileName + "_pngs/";
			} else {
				folderName = parentfolderURL + "/" + _fileName + "_pngs_" + String(num) + "/";
			}
			if (new File(folderName).exists) {
				folderName = getPngFolderName(parentfolderURL, num + 1);
			}
			return folderName;
		}

		private function getNumberString(n:int):String
		{
			return String(1000000 + n).substring(1);
		}

		public function getFileName(num:int):File
		{
			return (new File(_folderURL)).resolvePath(_headFileName + getNumberString(num) + ".png");
		}
	}
}