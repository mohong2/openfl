package openfl.text._internal;

#if hudtext_profile
/**
 * hudtext_profile-only cumulative counters shared by TextEngine / TextLayout.
 *
 * flixel's HudTextProf snapshots these before and after a single FlxText rebuild, so the
 * difference is exactly the layout work that rebuild paid for - including the layout that
 * happens before renderText() (TextField.textHeight).
 *
 * Everything here compiles away when hudtext_profile is off.
 */
class TextProf
{
	/** Number of TextEngine.update() calls (each one is a full TextField layout). */
	public static var engineUpdates:Int = 0;
	/** Seconds spent inside TextEngine.update(). */
	public static var tEngine:Float = 0;

	/** Number of TextLayout.__position() calls (one per ShapeCache miss). */
	public static var positionCalls:Int = 0;
	public static var positionChars:Int = 0;

	/** TextLayout.__position() sub-segments, seconds (cumulative). */
	public static var tSetSize:Float = 0;
	public static var tAdd:Float = 0;
	public static var tShape:Float = 0;
	public static var tInfo:Float = 0;
	public static var tLoop:Float = 0;

	public static inline function reset():Void
	{
		engineUpdates = 0;
		tEngine = 0;
		positionCalls = 0;
		positionChars = 0;
		tSetSize = 0;
		tAdd = 0;
		tShape = 0;
		tInfo = 0;
		tLoop = 0;
	}
}
#end
