package
{
	import flash.display.Sprite;
	import org.libspark.as3unit.runner.AS3UnitCore;

	public class RunTests extends Sprite
	{
		public function RunTests()
		{
			AS3UnitCore.main(AllTests);
		}
	}
}