import boot.Runner;
import boot.Runnable;
import haxe.Json;
import loka.asset.Video;
import loka.asset.Loader;
import boot.Assets;
import glee.GPUBuffer;
import glee.GPUTexture;

import tri.PerspectiveCamera;
using tri.Quad;
import tri.SimpleTexturedProgram;

using glmat.Mat4;
import glmat.Vec2;
import glmat.Vec3;
import glmat.Vec4;

import loka.gl.GL;
import loka.App;

import glee.GPU;
import glee.GPUTexture;

import korrigan.OrthoCamera;

class VideoTest{

	inline static var FOCUS_WIDTH = 1200;
	inline static var FOCUS_HEIGHT = 400;

	var gpu : GPU;
	var loader : Loader;

	var program : SimpleTexturedProgram;
	var buffer  : GPUBuffer<SimpleTexturedProgram>;

	var _perspectiveCamera : PerspectiveCamera;
	var _orthoCamera : OrthoCamera;

	var _texture : GPUTexture;
	var _video : Video;

	static function main() : Void{
		trace("video test");
		new VideoTest();
	}

	public function new( ){
		loader = new Loader();
		gpu = GPU.init({viewportType : KeepRatioUsingBorder(FOCUS_WIDTH, FOCUS_HEIGHT), viewportPosition: Center, maxHDPI:1});
		_perspectiveCamera = new PerspectiveCamera(gpu);
		_orthoCamera = new OrthoCamera(gpu, FOCUS_WIDTH, FOCUS_HEIGHT);
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
			untyped _video.onloadedmetadata = function () {
		        trace("loadedmetadat");
		    };
			_video.play();
		}else{
			trace("cannot play the video (mp4 not supported)");
		}



		js.Browser.document.addEventListener('mousemove', function(e){ 
		    mouseX = e.clientX == null ? e.clientX : e.pageX; 
		    mouseY = e.clientY == null ? e.clientX :  e.pageY;
		}, false);
		
	}
	var mouseX : Int;
	var mouseY : Int;

	function ready() : Void{
		gpu.setRenderFunction(render);   
	}


	function render(now : Float) {
		//centering
		var centerX = _video.videoWidth / 2 + (mouseX - gpu.windowWidth/2) * ( _video.videoWidth / gpu.windowWidth);
		var centerY = _video.videoHeight / 2 + (mouseY - gpu.windowHeight/2) * (_video.videoHeight / gpu.windowHeight);
		
		_perspectiveCamera.setCenterPosition(centerX,centerY,0);
		_perspectiveCamera.setEyePosition(0,0,-1);

		if(centerX < - FOCUS_WIDTH){
			centerX += _video.videoWidth;
		}
		if(centerX > _video.videoWidth - FOCUS_WIDTH){
			centerX -= _video.videoWidth;
		}
		if(centerY > (_video.videoHeight - FOCUS_HEIGHT/2)){
			centerY = _video.videoHeight - FOCUS_HEIGHT/2;
		}
		if(centerY < FOCUS_HEIGHT/2){
			centerY = FOCUS_HEIGHT/2;
		}
		_orthoCamera.centerOn(centerX, centerY);

		gpu.clearWith(0,0,0,1);
		try
		{
			_texture.uploadVideo(_video);
		}
		catch(e: Dynamic)
		{
		
		}

		buffer.rewind();
		buffer.writeTexturedQuad(_video.videoWidth, _video.videoHeight);
  		buffer.upload();

  		program.set_viewproj(_orthoCamera.viewproj);
		program.set_tex(_texture);
		program.draw(buffer);	
		
		
	}
}