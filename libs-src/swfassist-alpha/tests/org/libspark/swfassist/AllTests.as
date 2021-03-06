/*
 * Copyright(c) 2007 the Spark project.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
 * either express or implied. See the License for the specific language
 * governing permissions and limitations under the License.
 */

package org.libspark.swfassist
{
	import org.libspark.as3unit.runners.Suite;
	import org.libspark.swfassist.utils.AllTests;
	import org.libspark.swfassist.io.AllTests;
	
	/**
	 * All tests for org.libspark.swfassist package.
	 */
	public class AllTests
	{
		public static const RunWith:Class = Suite;
		public static const SuiteClasses:Array = [
			org.libspark.swfassist.utils.AllTests,
			org.libspark.swfassist.io.AllTests
		];
	}
}