package logic
{
	import flash.errors.IOError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import org.libspark.thread.Thread;

	public class FileOpenThread extends Thread
	{
		private var _file:File;
		private var _txtFilter:FileFilter;
		private var _fileURLList:Array;

		public function FileOpenThread()
		{
			super();
			_file = new File();
			_txtFilter = new FileFilter("Text", "*.swf");
			_fileURLList = null;
		}

		public function get fileURLList():Array
		{
			return _fileURLList;
		}

		override protected function run():void
		{
			trace('File Select Start');
			_file.browseForOpenMultiple("Select a swf file", [_txtFilter]);
			event(_file, FileListEvent.SELECT_MULTIPLE, fileSelecdHandler);
			event(_file, Event.CANCEL, cancelHandler);
			event(_file, ErrorEvent.ERROR, errorHandler);
		}

		private function fileSelecdHandler(event:FileListEvent):void
		{
			_fileURLList = new Array();
			for (var i:uint = 0; i < event.files.length; i++) {
				_fileURLList.push(event.files[i].url);
			}
		}

		private function cancelHandler(event:Event):void
		{
			throw new IOError(event.toString());
		}

		private function errorHandler(error:ErrorEvent):void
		{
			throw new IOError(error.text);
		}
	}
}
