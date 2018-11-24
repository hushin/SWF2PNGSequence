package org.libspark.thread
{
	import org.libspark.as3unit.runners.Suite;
	
	public class ThreadAllTests
	{
		public static const RunWith:Class = Suite;
		public static const SuiteClasses:Array = [
			TesterThreadTest,
			ThreadExecutionTest,
			MonitorTest,
			AuxiliaryTest,
			ExceptionTest,
			EventTest,
			InterruptionTest
		];
	}
}