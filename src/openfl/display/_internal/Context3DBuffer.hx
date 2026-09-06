package openfl.display._internal;

import openfl.utils._internal.Float32Array;
import openfl.utils._internal.UInt16Array;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;

@SuppressWarnings("checkstyle:FieldDocComment")
class Context3DBuffer
{
	private static inline var MAX_INDEX_BUFFER_LENGTH:Int = 0xFFFF;
	private static inline var MAX_QUADS_PER_INDEX_BUFFER:Int = 0x2AAA;
	private static inline var MAX_QUAD_INDEX_BUFFER_LENGTH:Int = 0xFFFC;

	public var dataPerVertex:Int;
	public var elementCount:Int;
	public var elementType:Context3DElementType;
	public var indexBufferData:Array<UInt16Array>;
	public var indexBuffers:Array<IndexBuffer3D>;
	public var indexCount:Int;
	public var vertexBuffer:VertexBuffer3D;
	/** GL buffer capacity in float elements (see `flushVertexBufferData`). */
	public var vertexBufferFloatCapacity:Int = 0;
	/** Float length of the previous flush, used to detect the steady-state case. */
	public var lastFlushLength:Int = -1;
	public var vertexBufferData:Float32Array;
	public var vertexCount:Int;

	private var context3D:Context3D;

	public function new(context3D:Context3D, elementType:Context3DElementType, elementCount:Int, dataPerVertex:Int)
	{
		this.context3D = context3D;
		this.elementType = elementType;
		this.dataPerVertex = dataPerVertex;

		indexCount = 0;
		vertexCount = 0;

		resize(elementCount);
	}

	public function drawElements(start:Int, length:Int = -1):Void
	{
		if (indexCount == 0 || vertexCount == 0) return;

		switch (elementType)
		{
			case QUADS:
				if (length == -1) length = (elementCount * 2);

				if (start < MAX_QUADS_PER_INDEX_BUFFER && length - start < MAX_QUADS_PER_INDEX_BUFFER)
				{
					context3D.drawTriangles(indexBuffers[0], start, length * 2);
				}
				else
				{
					var end = start + length;

					while (start < end)
					{
						var arrayBufferIndex = Math.floor(start / MAX_QUADS_PER_INDEX_BUFFER);

						length = Std.int(Math.min(end - start, MAX_QUADS_PER_INDEX_BUFFER));
						if (length <= 0) break;

						// TODO: Need to advance all vertex buffer bindings past start of 0xFFFF

						context3D.drawTriangles(indexBuffers[arrayBufferIndex], (start - (arrayBufferIndex * MAX_QUADS_PER_INDEX_BUFFER)) * 3, length * 2);
						start += length;
					}
				}

			default:
		}
	}

	public function flushVertexBufferData(usedLength:Int = 0):Void
	{
		var length = vertexBufferData.length;
		if (usedLength <= 0 || usedLength > length) usedLength = length;

		// Shrink the backing array once after a large drop in usage (e.g. after the
		// camera pulls back), so steady-state uploads don't carry a stale tail.
		if (length > 1024 && usedLength * 2 <= length)
		{
			var shrunk = new Float32Array(usedLength);
			shrunk.set(vertexBufferData.subarray(0, usedLength));
			vertexBufferData = shrunk;
			length = usedLength;

			if (vertexBuffer != null)
			{
				vertexBuffer.dispose();
				vertexBuffer = null;
				vertexBufferFloatCapacity = 0;
			}
		}

		if (vertexBuffer == null || length > vertexBufferFloatCapacity)
		{
			vertexCount = length;
			vertexBuffer = context3D.createVertexBuffer(length, dataPerVertex, DYNAMIC_DRAW);
			vertexBufferFloatCapacity = length;
			vertexBuffer.uploadFromTypedArray(vertexBufferData);
			lastFlushLength = usedLength;
			return;
		}

		if (usedLength == lastFlushLength)
		{
			// Steady state: the same byte count as the previous flush fully
			// overwrites the used region — update without re-allocating the GPU
			// buffer (gl.bufferData reallocates on every call).
			vertexBuffer.uploadSubFromTypedArray(vertexBufferData.subarray(0, usedLength));
		}
		else
		{
			// Used size changed since the last flush — redefine the buffer with the
			// full backing array (fits: vertexBufferFloatCapacity >= length).
			vertexBuffer.uploadFromTypedArray(vertexBufferData);
			lastFlushLength = usedLength;
		}
	}

	public function resize(elementCount:Int, dataPerVertex:Int = -1):Void
	{
		this.elementCount = elementCount;

		if (dataPerVertex == -1) dataPerVertex = this.dataPerVertex;

		if (dataPerVertex != this.dataPerVertex)
		{
			vertexBuffer = null;
			vertexCount = 0;

			this.dataPerVertex = dataPerVertex;
		}

		var numVertices = 0;

		switch (elementType)
		{
			case QUADS:
				numVertices = elementCount * 4;

			case TRIANGLES:
				numVertices = elementCount * 3;

			case TRIANGLE_INDICES:
				// TODO: Different index/triangle buffer lengths
				numVertices = elementCount * 3;

			default:
		}

		var vertexLength = numVertices * dataPerVertex;

		#if lime
		if (vertexBufferData == null)
		{
			vertexBufferData = new Float32Array(vertexLength);
		}
		else if (vertexLength > vertexBufferData.length)
		{
			var cacheBufferData = vertexBufferData;
			vertexBufferData = new Float32Array(vertexLength);
			vertexBufferData.set(cacheBufferData);
		}
		#end
	}
}

enum Context3DElementType
{
	QUADS;
	TRIANGLES;
	TRIANGLE_INDICES;
}
