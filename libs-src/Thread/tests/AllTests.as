package
{
	import org.libspark.as3unit.runners.Suite;
	import org.libspark.thread.ThreadAllTests;
	
	public class AllTests
	{
		public static const RunWith:Class = Suite;
		public static const SuiteClasses:Array = [
			ThreadAllTests
		];
	}
}