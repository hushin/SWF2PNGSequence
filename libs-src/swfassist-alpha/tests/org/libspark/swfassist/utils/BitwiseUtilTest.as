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

package org.libspark.swfassist.utils
{
	import org.libspark.as3unit.assert.*;
	import org.libspark.as3unit.test;
	
	use namespace test;
	
	public class BitwiseUtilTest
	{
		test function getMinBits():void
		{
			var a:uint = uint(parseInt("100000", 2));
			var b:uint = uint(parseInt("000100", 2));
			var c:uint = uint(parseInt("010010", 2));
			assertEquals(7, BitwiseUtil.getMinBits(a, b, c));
		}
	}
}