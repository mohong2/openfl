package openfl.display3D.textures;

#if !flash
import openfl.display._internal.SamplerState;
import openfl.display.BitmapData;
import openfl.utils._internal.ArrayBufferView;
import openfl.utils._internal.UInt8Array;
import openfl.utils.ByteArray;

/**
	The Rectangle Texture class represents a 2-dimensional texture uploaded to a rendering
	context.

	Defines a 2D texture for use during rendering.

	Texture cannot be instantiated directly. Create instances by using Context3D
	`createRectangleTexture()` method.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D.Context3D)
@:access(openfl.display.Stage)
@:final class RectangleTexture extends TextureBase
{
	@:noCompletion private function new(context:Context3D, width:Int, height:Int, format:String, optimizeForRenderToTexture:Bool, opaqueRGB:Bool = false,
			indexFormat:Int = 0)
	{
		// RGB has no alpha channel in VRAM (sampling returns alpha=1.0). The
		// upload rows are still BGRA bytes; GL converts them on upload and drops
		// the alpha component. A non-zero indexFormat selects the 8-bit palette
		// index representation instead; both __internalFormat and __format must
		// be that single-channel GL enum for texImage2D to accept the rows.
		super(context, opaqueRGB && TextureBase.supportsOpaqueRGB() ? context.gl.RGB : 0);

		if (indexFormat != 0)
		{
			__internalFormat = indexFormat;
			__format = indexFormat;
		}

		__width = width;
		__height = height;
		// __format = format;
		__optimizeForRenderToTexture = optimizeForRenderToTexture;

		__textureTarget = __context.gl.TEXTURE_2D;
		uploadFromTypedArray(null);

		if (optimizeForRenderToTexture) __getGLFramebuffer(true, 0, 0);
	}

	/**
		Uploads a texture from a BitmapData object.

		@param	source	a bitmap.
		@throws	TypeError	Null Pointer Error: when `source` is `null`.
		@throws	ArgumentError	Invalid BitmapData Error: when `source` does not contain a
		valid texture. The maximum allowed size in any dimension is 4096 or the size of the
		backbuffer, whichever is greater.
		@throws	Error	3768: The Stage3D API may not be used during background execution.
	**/
	public function uploadFromBitmapData(source:BitmapData):Void
	{
		#if lime
		if (source == null) return;

		var image = __getImage(source);
		if (image == null) return;

		#if (js && html5)
		if (image.buffer != null && image.buffer.data == null && image.buffer.src != null)
		{
			var gl = __context.gl;

			__context.__bindGLTexture2D(__textureID);
			gl.texImage2D(__textureTarget, 0, __internalFormat, __format, gl.UNSIGNED_BYTE, image.buffer.src);
			__context.__bindGLTexture2D(null);
			return;
		}
		#end

		uploadFromTypedArray(image.data);
		#end
	}

	/**
		Uploads a texture from a ByteArray.

		@param	data	a byte array that is contains enough bytes in the textures internal
		format to fill the texture. rgba textures are read as bytes per texel component (1
		or 4). float textures are read as floats per texel component (1 or 4). The
		ByteArray object must use the little endian format.
		@param	byteArrayOffset	the position in the byte array object at which to start
		reading the texture data.
		@throws	TypeError	Null Pointer Error: when `data` is `null`.
		@throws	RangeError	Bad Input Size: if the number of bytes available from
		`byteArrayOffset` to the end of data byte array is less than the amount of data
		required for a texture, or if `byteArrayOffset` is greater than or equal to the
		length of data.
		@throws	Error	3768: The Stage3D API may not be used during background execution.
	**/
	public function uploadFromByteArray(data:ByteArray, byteArrayOffset:UInt):Void
	{
		#if lime
		#if (js && !display)
		if (byteArrayOffset == 0)
		{
			uploadFromTypedArray(@:privateAccess (data : ByteArrayData).b);
			return;
		}
		#end

		uploadFromTypedArray(new UInt8Array(data.toArrayBuffer(), byteArrayOffset));
		#end
	}

	/**
		Upload one 8-bit palette-index row per texel. Returns false when the driver
		rejected the format so the caller can fall back to RGBA before drawing.
	**/
	public function uploadIndexData(data:ArrayBufferView, width:Int, height:Int):Bool
	{
		var gl = __context.gl;
		gl.getError(); // clear any stale error, we only care about this upload

		// One byte per pixel: rows are only naturally aligned when width % 4 == 0.
		// GL's default UNPACK_ALIGNMENT is 4, so a 11097-wide row would be read as
		// 11100 bytes and the driver can walk past the index buffer. Force 1 for
		// this upload (and restore whatever the caller had afterwards).
		var previousAlignment:Int = 4;
		try previousAlignment = cast gl.getParameter(gl.UNPACK_ALIGNMENT) catch (e:Dynamic) {}
		gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);

		__context.__bindGLTexture2D(__textureID);
		gl.texImage2D(__textureTarget, 0, __internalFormat, width, height, 0, __format, gl.UNSIGNED_BYTE, data);
		var error = gl.getError();
		__context.__bindGLTexture2D(null);

		gl.pixelStorei(gl.UNPACK_ALIGNMENT, previousAlignment > 0 ? previousAlignment : 4);
		return error == gl.NO_ERROR;
	}

	/**
		Uploads a texture from an ArrayBufferView.

		@param	data	a typed array that contains enough bytes in the textures internal
		format to fill the texture. rgba textures are read as bytes per texel component (1
		or 4). float textures are read as floats per texel component (1 or 4).
	**/
	public function uploadFromTypedArray(data:ArrayBufferView):Void
	{
		var gl = __context.gl;

		__context.__bindGLTexture2D(__textureID);
		gl.texImage2D(__textureTarget, 0, __internalFormat, __width, __height, 0, __format, gl.UNSIGNED_BYTE, data);
		__context.__bindGLTexture2D(null);
	}

	@:noCompletion private override function __setSamplerState(state:SamplerState):Bool
	{
		if (super.__setSamplerState(state))
		{
			var gl = __context.gl;

			if (Context3D.__glMaxTextureMaxAnisotropy != 0)
			{
				var aniso = switch (state.filter)
				{
					case ANISOTROPIC2X: 2;
					case ANISOTROPIC4X: 4;
					case ANISOTROPIC8X: 8;
					case ANISOTROPIC16X: 16;
					default: 1;
				}

				if (aniso > Context3D.__glMaxTextureMaxAnisotropy)
				{
					aniso = Context3D.__glMaxTextureMaxAnisotropy;
				}

				gl.texParameterf(gl.TEXTURE_2D, Context3D.__glTextureMaxAnisotropy, aniso);
			}

			return true;
		}

		return false;
	}
}
#else
typedef RectangleTexture = flash.display3D.textures.RectangleTexture;
#end
