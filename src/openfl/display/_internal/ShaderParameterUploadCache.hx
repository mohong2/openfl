package openfl.display._internal;

#if (sys && !openfl_disable_uniform_upload_cache)
import Sys;
#end

/**
 * Global state for uniform upload dirty checks.
 *
 * Uniform values persist on the GL program, so identical re-uploads can be skipped.
 * Shader instances may share a program and alternate writes to the same location,
 * therefore each location keeps the sequence number of its last writer and only
 * that writer may skip. NaN never compares equal, so it always re-uploads.
 *
 * Separate non-generic class because ShaderParameter is @:generic and cannot
 * hold static fields.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@SuppressWarnings("checkstyle:Dynamic")
@:access(openfl.display.ShaderParameter)
class ShaderParameterUploadCache
{
	/** Runtime escape switch: FNF_UNIFORM_UPLOAD_CACHE=0 disables caching. */
	public static var enabled:Bool = true;
	#if sys
	private static var envChecked:Bool = false;
	#end
	/** Monotonic upload sequence. */
	public static var uploadSequence:Int = 0;
	/** Uniform location -> last writer sequence. */
	public static var locationWrites:#if js haxe.ds.ObjectMap<Dynamic, Int> #else haxe.ds.IntMap<Int> #end =
		#if js new haxe.ds.ObjectMap<Dynamic, Int>() #else new haxe.ds.IntMap<Int>() #end;

	#if (sys && !openfl_disable_uniform_upload_cache)
	/** Reads the environment variable once on first ShaderParameter creation. */
	public static function checkEnv():Void
	{
		if (!envChecked)
		{
			envChecked = true;

			if (Sys.getEnv("FNF_UNIFORM_UPLOAD_CACHE") == "0")
			{
				enabled = false;
			}
		}
	}
	#end

	#if !openfl_disable_uniform_upload_cache
	@SuppressWarnings("checkstyle:Dynamic") public static inline function locationWriteExists(index:Dynamic):Bool
	{
		#if js
		return locationWrites.exists(index);
		#else
		return locationWrites.exists(cast index);
		#end
	}

	@SuppressWarnings("checkstyle:Dynamic") public static inline function locationWriteGet(index:Dynamic):Int
	{
		#if js
		var seq = locationWrites.get(index);
		#else
		var seq = locationWrites.get(cast index);
		#end
		return seq == null ? 0 : seq;
	}

	@SuppressWarnings("checkstyle:Dynamic") public static inline function locationWriteSet(index:Dynamic, sequence:Int):Void
	{
		#if js
		locationWrites.set(index, sequence);
		#else
		locationWrites.set(cast index, sequence);
		#end
	}
	#end
}
