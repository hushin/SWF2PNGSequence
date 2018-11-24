package logic
{

	import flash.display.DisplayObject;
	import flash.display.MovieClip;

	public class BasicExportSettingFactory
	{
		public function BasicExportSettingFactory()
		{
		}

		static public function create(root:DisplayObject, filePath:String, isAVM1Movie:Boolean = false):ExportSetting
		{
			var reg:RegExp = /(.*)[\/\\](.*?)\.swf$/i; //ファイル名を抜き取る正規表現
			var setting:ExportSetting = new ExportSetting();
//			var scaleW:Number;
//			var scaleH:Number;
			var originalW:Number = root.loaderInfo.width;
			var originalH:Number = root.loaderInfo.height;
			setting.scaleMatrix.scale(1, 1);
			setting.canvasSize.x = originalW;
			setting.canvasSize.y = originalH;
			setting.startFrame = 1;
			setting.endFrame = (isAVM1Movie) ? (root as MovieClip).totalFrames - 2 : (root as MovieClip).totalFrames;
			setting.fileName = filePath.replace(reg, "$2");
			setting.folderURL = setting.getPngFolderName(filePath.replace(reg, "$1"));
			setting.canDrawOutFrame = false;
			setting.headFileName = "pic";
			setting.canvasTransparent = false;
			setting.canvasColor = 0xFFFFFF;
			return setting;
		}
	}
}
