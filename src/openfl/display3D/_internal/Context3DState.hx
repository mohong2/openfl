package openfl.display3D._internal;

import openfl.display3D._internal.GLBuffer;
import openfl.display3D._internal.GLFramebuffer;
import openfl.display3D._internal.GLRenderbuffer;
import openfl.display3D._internal.GLTexture;
import openfl.display._internal.SamplerState;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DStencilAction;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Program3D;
import openfl.display.Shader;
import openfl.geom.Rectangle;
#if lime
import lime.graphics.opengl.GL;
#end

@SuppressWarnings("checkstyle:FieldDocComment")
class Context3DState
{
	public var backBufferEnableDepthAndStencil:Bool;
	public var blendDestinationAlphaFactor:Context3DBlendFactor;
	public var blendSourceAlphaFactor:Context3DBlendFactor;
	public var blendDestinationRGBFactor:Context3DBlendFactor;
	public var blendSourceRGBFactor:Context3DBlendFactor;
	public var colorMaskRed:Bool;
	public var colorMaskGreen:Bool;
	public var colorMaskBlue:Bool;
	public var colorMaskAlpha:Bool;
	public var culling:Context3DTriangleFace;
	public var depthCompareMode:Context3DCompareMode;
	public var depthMask:Bool;
	// public var fillMode:Context3DFillMode;
	public var program:Program3D;
	// program constants?
	public var renderToTexture:TextureBase;
	public var renderToTextureAntiAlias:Int;
	public var renderToTextureDepthStencil:Bool;
	public var renderToTextureSurfaceSelector:Int;
	public var samplerStates:Array<SamplerState>;
	public var scissorEnabled:Bool;
	public var scissorRectangle:Rectangle;
	public var stencilCompareMode:Context3DCompareMode;
	public var stencilDepthFail:Context3DStencilAction;
	public var stencilFail:Context3DStencilAction;
	public var stencilPass:Context3DStencilAction;
	public var stencilReadMask:UInt;
	public var stencilReferenceValue:UInt;
	public var stencilTriangleFace:Context3DTriangleFace;
	public var stencilWriteMask:UInt;
	public var textures:Array<TextureBase>;
	// vertex buffer at?
	public var shader:Shader; // TODO: Merge shader/program3d

	private var __currentGLArrayBuffer:GLBuffer;
	private var __currentGLElementArrayBuffer:GLBuffer;
	private var __currentGLFramebuffer:GLFramebuffer;
	private var __currentGLTexture2D:GLTexture;
	private var __currentGLTextureCubeMap:GLTexture;

	/**
		Last viewport sent to GL. Invalidated whenever the framebuffer changes, because
		a new framebuffer can share the dimensions but not the clip volume.
	**/
	@:noCompletion public var __viewportValid:Bool = false;
	@:noCompletion public var __viewportX:Int = 0;
	@:noCompletion public var __viewportY:Int = 0;
	@:noCompletion public var __viewportWidth:Int = 0;
	@:noCompletion public var __viewportHeight:Int = 0;

	/**
		Per-unit texture binding cache. GL_TEXTURE0 is the active unit at context creation,
		so the initial value must be 0 (not -1) or the first bind would be skipped.
	**/
	@:noCompletion public var activeTextureUnit:Int = 0;
	@:noCompletion public var textureUnits:Array<GLTexture> = [];
	@:noCompletion public var textureUnitsCube:Array<GLTexture> = [];

	/**
		Bitmap of vertex attribute arrays currently enabled in GL (bit N = index N).

		Vertex attribute array enablement is context-global, not per program, and almost every
		draw leaves it exactly as the previous draw left it: openfl disables the constant
		attributes and re-enables the buffered ones on every draw. Caching it removes the
		redundant `glDisableVertexAttribArray`/`glEnableVertexAttribArray` calls. GL's initial
		state has every array disabled, so 0 is the correct initial value.
	**/
	@:noCompletion public var __vertexAttribArrays:Int = 0;

	private var __enableGLBlend:Bool;
	private var __enableGLCullFace:Bool;
	private var __enableGLDepthTest:Bool;
	private var __enableGLScissorTest:Bool;
	private var __enableGLStencilTest:Bool;
	private var __frontFaceGLCCW:Bool;
	private var __glBlendEquation:Int;
	private var __primaryGLFramebuffer:GLFramebuffer;
	private var __rttDepthGLRenderbuffer:GLRenderbuffer;
	private var __rttGLFramebuffer:GLFramebuffer;
	private var __rttGLRenderbuffer:GLRenderbuffer;
	private var __rttStencilGLRenderbuffer:GLRenderbuffer;

	public function new()
	{
		backBufferEnableDepthAndStencil = false;
		blendDestinationAlphaFactor = ZERO;
		blendSourceAlphaFactor = ONE;
		blendDestinationRGBFactor = ZERO;
		blendSourceRGBFactor = ONE;
		colorMaskRed = true;
		colorMaskGreen = true;
		colorMaskBlue = true;
		colorMaskAlpha = true;
		culling = NONE;
		depthCompareMode = LESS;
		depthMask = true;
		samplerStates = new Array();
		scissorRectangle = new Rectangle();
		stencilCompareMode = ALWAYS;
		stencilDepthFail = KEEP;
		stencilFail = KEEP;
		stencilPass = KEEP;
		stencilReadMask = 0xFF;
		stencilReferenceValue = 0;
		stencilTriangleFace = FRONT_AND_BACK;
		stencilWriteMask = 0xFF;
		textures = new Array();
		__frontFaceGLCCW = true;

		#if lime
		__glBlendEquation = GL.FUNC_ADD;
		#end
	}
}
