package logic
{
	import flash.display.BitmapData;
	import flash.errors.IOError;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import by.blooddy.crypto.image.PNG24Encoder;
	import org.libspark.thread.Thread;

	public class SavePNGFileThread extends Thread
	{
		public function SavePNGFileThread(canvas:BitmapData, file:File)
		{
			_canvas = canvas;
			_file = file;
		}
		private var _file:File;
		private var _canvas:BitmapData;
		private var _ba:ByteArray;

		override protected function run():void
		{
			_ba = by.blooddy.crypto.image.PNG24Encoder.encode(_canvas);
			next(saveImage);
		}

		private function saveImage():void
		{
			var stream:FileStream = new FileStream();
			try {
				stream.open(_file, FileMode.WRITE);
				stream.writeBytes(_ba);
			} catch (error:IOError) {
				throw error;
			} finally {
				stream.close();
			}
		}

		override protected function finalize():void
		{
			_canvas.dispose();
			_ba.clear();
		}
	}
}
