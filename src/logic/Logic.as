package logic
{
	import mx.core.IMXMLObject;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;

	/**
	 * 各Logicクラスで共通の機能を実装する
	 */
	public class Logic implements IMXMLObject
	{
		/** MXMLファイルを参照するクラス */
		private var _document:UIComponent;
		/** MXMLファイル上で指定されたid */
		private var _id:String;

		public function initialized(document:Object, id:String):void
		{
			_document = document as UIComponent;
			_id = id;
			_document.addEventListener(FlexEvent.CREATION_COMPLETE, onCreationCompleteHandler, false, 0, true);
		}

		/**
		 * 初期化処理
		 *
		 * @param event FlexEvent
		 */
		protected function onCreationCompleteHandler(event:FlexEvent):void
		{
		}

		/**
		 * document を取得する
		 *
		 * @return document
		 */
		public final function get document():UIComponent
		{
			return _document;
		}

		/**
		 * id を取得する
		 *
		 * @return id
		 */
		public final function get id():String
		{
			return _id;
		}
	}
}
