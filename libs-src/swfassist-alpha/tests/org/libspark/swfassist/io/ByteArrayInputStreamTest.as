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
	import org.libspark.as3unit.test;
	import org.libspark.as3unit.assert.*;
	import flash.utils.ByteArray;
	
	use namespace test;
	
	public class ByteArrayInputStreamTest
	{
		test function readU8():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xa1);
			bytes.writeByte(0xb2);
			bytes.writeByte(0xc3);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(0xa1, input.readU8());
			assertEquals(0xb2, input.readU8());
			assertEquals(0xc3, input.readU8());
		}
		
		test function readFixedPositive():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0x00);
			bytes.writeByte(0x80);
			bytes.writeByte(0x18);
			bytes.writeByte(0x00);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(24.5, input.readFixed());
		}
		
		test function readFixedNegative():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0x00);
			bytes.writeByte(0x80);
			bytes.writeByte(0xe7);
			bytes.writeByte(0xff);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(-24.5, input.readFixed());
		}
		
		test function readFixed8():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0x80);
			bytes.writeByte(0x07);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(7.5, input.readFixed8());
		}
		
		test function readFloat16():void
		{
			// -18.625:
			// = -1 * 10010.101b
			// = -1 * 1.0010101b * 2^4
			// = sign: 1, exp: 10100, fraction: 0010101000
			// = 1101 0000 1010 1000
			// = 0xd0a8
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xa8);
			bytes.writeByte(0xd0);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(-18.625, input.readFloat16());
		}
		
		test function readBit():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xA0);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertTrue(input.readBit());
			assertFalse(input.readBit());
			assertTrue(input.readBit());
		}
		
		test function readUBits():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xfc);
			bytes.writeByte(0xa3);
			// 1111 1100 1010 0011
			// 111, 1, 1, 100 1010 0011
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(0x07, input.readUBits(3));
			assertEquals(0x01, input.readUBits(1));
			assertEquals(0x01, input.readUBits(1));
			assertEquals(0x04a3, input.readUBits(11));
		}
		
		test function readRect():void
		{
			var bytes:ByteArray = new ByteArray();
			// 0x7800055F00000FA000000C
			bytes.writeByte(0x78);
			bytes.writeByte(0x00);
			bytes.writeByte(0x05);
			bytes.writeByte(0x5f);
			bytes.writeByte(0x00);
			bytes.writeByte(0x00);
			bytes.writeByte(0x0f);
			bytes.writeByte(0xa0);
			bytes.writeByte(0x00);
			bytes.writeByte(0x00);
			bytes.writeByte(0x0c);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(15, input.readUBits(5));
			assertEquals(0, input.readUBits(15));
			assertEquals(11000, input.readUBits(15));
			assertEquals(0, input.readUBits(15));
			assertEquals(8000, input.readUBits(15));
			assertEquals(9, input.position);
			assertEquals(0x0c00, input.readU16());
		}
		
		test function readSBitsPositive():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0x4c);
			bytes.writeByte(0xe0);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(2460, input.readSBits(13));
		}
		
		test function readSBitsNegative():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xb3);
			bytes.writeByte(0x20);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(-2460, input.readSBits(13));
		}
		
		test function readFBits():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0x60);
			bytes.writeByte(0x00);
			bytes.writeByte(0x00);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			assertEquals(1.5, input.readFBits(18));
		}
		
		test function readBytes():void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xf1);
			bytes.writeByte(0xf2);
			bytes.writeByte(0xf3);
			bytes.writeByte(0xf4);
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			var expect:ByteArray = new ByteArray();
			expect.writeByte(0xf2);
			expect.writeByte(0xf3);
			var actual:ByteArray = new ByteArray();
			
			input.readU8();
			input.readBytes(actual, 2);
			
			assertByteArrayEquals(expect, actual);
			assertEquals(0xf4, input.readU8());
		}
		
		[Embed(source = 'compressed.binary', mimeType = 'application/octet-stream')]
		private static const CompressedBytes:Class;
		
		[Embed(source = 'uncompressed.binary', mimeType = 'application/octet-stream')]
		private static const UncompressedBytes:Class;
		
		test function uncompress():void
		{
			var bytes:ByteArray = new CompressedBytes();
			var input:ByteArrayInputStream = new ByteArrayInputStream(bytes);
			input.uncompress(8);
			assertByteArrayEquals(new UncompressedBytes(), bytes);
		}
	}
}