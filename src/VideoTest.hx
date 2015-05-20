import boot.Runner;
import boot.Runnable;
import boot.VideoLoader;
import boot.VideoLoader.VideoOutcome;
import control.Input;
import haxe.Json;
import loka.asset.Video;
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
	var mouse : control.Mouse;
	var keyboard : control.Keyboard;

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
		gpu = GPU.init({viewportType : KeepRatioUsingBorder(FOCUS_WIDTH, FOCUS_HEIGHT), viewportPosition: Center, maxHDPI:1});
		mouse = Input.initMouse();
		keyboard = Input.initKeyboard();
		keyboard.isDown(loka.input.Key.B);
		_perspectiveCamera = new PerspectiveCamera(gpu);
		_orthoCamera = new OrthoCamera(gpu, FOCUS_WIDTH, FOCUS_HEIGHT);
		program = SimpleTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<SimpleTexturedProgram>(gpu, GL.DYNAMIC_DRAW); 

		initialised();
	}

	function initialised() : Void{
		_texture = GPUTexture.create(gpu);
		var videoLoader = new VideoLoader();
		videoLoader.load("loop1.mp4").handle(videoLoaded);
		
	}


	function videoLoaded(outcome : VideoOutcome) : Void{
		switch(outcome){
			case Success(video):
				_video = video;
				_video.loop = true;
				_video.play();
				gpu.setRenderFunction(render);   
			case Failure(error): trace(error);
		}
	}


	function render(now : Float) {
		//centering
		var centerX = _video.videoWidth / 2 + (mouse.x - gpu.windowWidth/2) * ( _video.videoWidth / gpu.windowWidth);
		var centerY = _video.videoHeight / 2 + (mouse.y - gpu.windowHeight/2) * (_video.videoHeight / gpu.windowHeight);
		
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