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

package org.libspark.swfassist.io
{
	import flash.utils.ByteArray;
	
	import org.libspark.as3unit.assert.*;
	import org.libspark.as3unit.test;
	
	use namespace test;
	
	public class ByteArrayOutputStreamTest
	{
		test function writeU8():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeU8(0xa1);
			output.writeU8(0xb2);
			output.writeU8(0xc3);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0xa1);
			expected.writeByte(0xb2);
			expected.writeByte(0xc3);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeFixedPositive():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeFixed(24.5);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0x00);
			expected.writeByte(0x80);
			expected.writeByte(0x18);
			expected.writeByte(0x00);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeFixedNegative():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeFixed(-24.5);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0x00);
			expected.writeByte(0x80);
			expected.writeByte(0xe7);
			expected.writeByte(0xff);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeFixed8():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeFixed8(7.5);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0x80);
			expected.writeByte(0x07);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeFloat16():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeFloat16(-18.625);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0xa8);
			expected.writeByte(0xd0);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeBit():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeBit(true);
			output.writeBit(false);
			output.writeBit(true);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0xa0);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeUBits():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeUBits(3, 0x07);
			output.writeUBits(1, 0x01);
			output.writeUBits(1, 0x01);
			output.writeUBits(11, 0x04a3);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0xfc);
			expected.writeByte(0xa3);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeRect():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeUBits(5, 15);
			output.writeUBits(15, 0);
			output.writeUBits(15, 11000);
			output.writeUBits(15, 0);
			output.writeUBits(15, 8000);
			output.writeU16(0x0c00);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0x78);
			expected.writeByte(0x00);
			expected.writeByte(0x05);
			expected.writeByte(0x5f);
			expected.writeByte(0x00);
			expected.writeByte(0x00);
			expected.writeByte(0x0f);
			expected.writeByte(0xa0);
			expected.writeByte(0x00);
			expected.writeByte(0x00);
			expected.writeByte(0x0c);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeSBitsPositive():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeSBits(13, 2460);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0x4c);
			expected.writeByte(0xe0);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeSBitsNegative():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeSBits(13, -2460);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0xb3);
			expected.writeByte(0x20);
			assertByteArrayEquals(expected, bytes);
		}
		
		test function writeFBits():void
		{
			var bytes:ByteArray = new ByteArray();
			var output:ByteArrayOutputStream = new ByteArrayOutputStream(bytes);
			output.writeFBits(18, 1.5);
			var expected:ByteArray = new ByteArray();
			expected.writeByte(0x60);
			expected.writeByte(0x00);
			expected.writeByte(0x00);
			assertByteArrayEquals(expected, bytes);
		}
	}
}