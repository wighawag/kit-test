import boot.Runner;
import boot.Runnable;
import haxe.Json;
import loka.asset.Video;
import loka.asset.Loader;
import boot.Assets;
import glee.GPUBuffer;
import glee.GPUTexture;

import tri.SimpleTexturedProgram;

using glmat.Mat4;
import glmat.Vec2;
import glmat.Vec3;
import glmat.Vec4;

import loka.gl.GL;
import loka.App;

import glee.GPU;
import glee.GPUTexture;

class VideoTest{

	inline static var FOCUS_WIDTH = 600;
	inline static var FOCUS_HEIGHT = 400;

	var gpu : GPU;
	var loader : Loader;

	var program : SimpleTexturedProgram;
	var buffer  : GPUBuffer<SimpleTexturedProgram>;

	var _texture : GPUTexture;
	var _video : Video;

	static function main() : Void{
		trace("video test");
		new VideoTest();
	}

	public function new( ){
		loader = new Loader();
		gpu = GPU.init({viewportType : Fill /*KeepRatioUsingBorder(FOCUS_WIDTH, FOCUS_HEIGHT)*/, viewportPosition: Center, maxHDPI:1});
		
		program = SimpleTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<SimpleTexturedProgram>(gpu, GL.DYNAMIC_DRAW); 

		initialised();
	}

	function initialised() : Void{
		_texture = GPUTexture.create(gpu);
		_video = cast js.Browser.document.createElement('video');
		if (_video.canPlayType('video/mp4').length > 0) {
 			_video.src = 'loop1.mp4';
			untyped _video.autoPlay = true;
			_video.loop = true;
			untyped _video.oncanplay = ready;
			_video.play();
		}else{
			trace("cannot play the video (mp4 not supported)");
		}
		
	}

	function ready() : Void{
		gpu.setRenderFunction(render);   
	}


	function render(now : Float) {
		//centering
		
		gpu.clearWith(0,0,0,1);
		try
		{
			_texture.uploadVideo(_video);
		}
		catch(e: Dynamic)
		{
		
		}

		buffer.rewind();
		

		buffer.write_position(-1,-1,0);
		buffer.write_texCoords(0, 1);
		buffer.write_position(-1,1,0);
		buffer.write_texCoords(0,0);
		buffer.write_position(1,1,0);
		buffer.write_texCoords(1,0);

		buffer.write_position(1,1,0);
		buffer.write_texCoords(1,0);
		buffer.write_position(1,-1,0);
		buffer.write_texCoords(1,1);
		buffer.write_position(-1,-1,0);
		buffer.write_texCoords(0,1);
		
  		buffer.upload();

		program.set_tex(_texture);
		program.draw(buffer);	
		
		
	}
}