import loka.asset.Image;
import loka.asset.Loader;
import boot.Assets;
import glee.GPUBuffer;
import glee.GPUTexture;
import haxe.Timer;
import loka.Window;

using glmat.Mat4;
import glmat.Vec3;
import tri.Cube;
import tri.SimpleProgram;
import tri.SkyBoxProgram;

import loka.gl.GL;

import glee.GPU;
import glee.GPUCubeTexture;
//import tri.SkyTriangleProgram;

class Test3D{

	var window : Window;
	var gpu : GPU;
	var loader : Loader;

	var program : SkyBoxProgram;
	var buffer  : GPUBuffer<{position:Vec3}>;

	var _texture : GPUCubeTexture;
	var mat : Mat4;
	var proj : Mat4;
	var view : Mat4;
	var eye : Vec3;
	var center : Vec3;
	var up : Vec3;
	var angle : Float;

	var _obj_texture : GPUTexture;
	var _obj_program : SimpleProgram;
	var _obj_buffer : GPUBuffer<{position:Vec3}>;
	var _obj_mat : Mat4;
	var _obj_proj : Mat4;
	var _obj_view : Mat4;
	var _skyBox_view : Mat4;
	var _obj_eye : Vec3;
	var _obj_center : Vec3;
	var _obj_up : Vec3;
	var _obj_angle : Float;

	var _cube : Cube;

	static function main() : Void{
		new Test3D();
	}

	public function new( ){
		window = Window.createWindow();
		loader = new Loader();
		gpu = new GPU(window.gl);
		program = SkyBoxProgram.upload(gpu);		
		buffer = new GPUBuffer<{position:Vec3}>(gpu, GL.STATIC_DRAW); 
		buffer.rewind();
		var cube = new Cube(100,100,100);
		cube.write(buffer);
		buffer.upload();

		_obj_program = SimpleProgram.upload(gpu);		
		_obj_buffer = new GPUBuffer<{position:Vec3}>(gpu, GL.DYNAMIC_DRAW); 

		_obj_proj = new Mat4();
		_obj_view = new Mat4();
		_skyBox_view = new Mat4();
		_obj_eye = new Vec3(0,10,0);
		_obj_center = new Vec3(0,10,0);
		_obj_up = new Vec3(0,1,0);
		_obj_angle = 0;

		_cube = new Cube(10,30,10);
		lastTime = Timer.stamp();
		Assets.load([],["skybox/negx.jpg","skybox/negy.jpg","skybox/negz.jpg","skybox/posx.jpg","skybox/posy.jpg","skybox/posz.jpg"]).handle(loadingAssets);
	}

	function errorLoading(msg : String) : Void{
		trace(msg);
	}

	function loadingAssets(outcome : AssetsOutcome) : Void{

		switch (outcome) {
			case Success(assets):
				_texture = gpu.uploadCubeTexture(
				assets.images.get("skybox/negx.jpg"),
				assets.images.get("skybox/negy.jpg"),
				assets.images.get("skybox/negz.jpg"),
				assets.images.get("skybox/posx.jpg"),
				assets.images.get("skybox/posy.jpg"),
				assets.images.get("skybox/posz.jpg")
					);
				//TODO : remove js specific
				js.Browser.window.requestAnimationFrame(render);

			case Failure(e):
				trace(e);
		}
		
	}

	var lastTime : Float;
	function render(t : Float) : Bool{
		window.resize();//todo on resize event
		var width = Std.int(window.width);
		var height = Std.int(window.height);
		window.gl.viewport(0, 0, width , height);//window.gl.drawingBufferWidth, window.gl.drawingBufferHeight);

		var now = Timer.stamp();
		var delta = now - lastTime;
		lastTime = now;

		_obj_angle += 0.01;
		if (_obj_angle > Math.PI * 2){
			_obj_angle = 0;
		}

		_obj_eye.x = ((30 - _obj_center.x) * Math.cos(_obj_angle)) + _obj_center.x;
		_obj_eye.z = ((30 - _obj_center.z) * Math.sin(_obj_angle)) + _obj_center.z;

		_obj_proj = _obj_proj.perspective(45,window.width/window.height,0.01,1000);
		_obj_view = _obj_view.lookAt(_obj_eye,_obj_center,_obj_up);

		gpu.clearWith(0.5,0.5,0,1);

		program.set_cubeTexture(_texture);
		program.set_P(_obj_proj);
		_skyBox_view =  _skyBox_view.copyFrom(_obj_view);//translate(_obj_view,-_obj_eye.x,-_obj_eye.y,-_obj_eye.z);//_skyBox_view.lookAt(new Vec3(),_obj_center,_obj_up);
		//TODO ? _skyBox_view[12] =0;
		// _skyBox_view[13] =0;
		// _skyBox_view[14] =0;
		// _skyBox_view[15] =1;
		program.set_V(_skyBox_view);
		program.draw(buffer);

		_obj_buffer.rewind();
		_cube.write(_obj_buffer);
  		_obj_buffer.upload();

		
		_obj_program.set_P(_obj_proj);
		_obj_program.set_V(_obj_view);
		_obj_program.draw(_obj_buffer);

		//TODO : remove js specific
		js.Browser.window.requestAnimationFrame(render);
		
		return true;
	}
}