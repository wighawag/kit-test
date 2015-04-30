
//jsloka setup example

using glmat.Mat4;
import loka.asset.Image;
import loka.asset.Loader;
import glee.GPUBuffer;
import haxe.Timer;
import loka.Window;

import korrigan.SimpleTexturedProgram;

import loka.gl.GL;

import glee.GPU;
import glee.GPUTexture;

class BoxTest{

	var program : SimpleTexturedProgram;
	var buffer  : GPUBuffer<SimpleTexturedProgram>;

	var window : Window;
	var gpu : GPU;
	var loader : Loader;

	var _texture : GPUTexture;

	static function main() : Void{
		new BoxTest();
	}

	public function new( ){
		window = Window.createWindow(); //js specific
		loader = new Loader();
		gpu = new GPU(window.gl); //TODO call it GPUState ?
		program = SimpleTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<SimpleTexturedProgram>(gpu, GL.DYNAMIC_DRAW); //gpu.createBuffer(TexturedQuadProgram);

		lastTime = Timer.stamp();
		loader.loadImage("test.png",assetLoaded , errorLoading);
	}

	function errorLoading(msg : String) : Void{
		trace(msg);
	}

	function assetLoaded(image : Image) : Void{
		_texture = gpu.uploadTexture(image);

		js.Browser.window.requestAnimationFrame(render);
	}

	var lastTime : Float;
	function render(t : Float) : Bool{
		var now = Timer.stamp();
		var delta = now - lastTime;
		lastTime = now;

		gpu.clearWith(0.5,0.5,0,1);

		buffer.rewind();

		//TODO buffer.write_vertice(0,0,0,1);
		//for(i in 0...4){
		//	buffer.write_position(0.5 * i, 0.5 * i);	
		//}
		buffer.write_position(0, 0, 0);	
		buffer.write_position(1, 0, 0);	
		buffer.write_position(0, 1, 0);
		buffer.write_position(0, 1, 0);	
		buffer.write_position(1, 1, 0);	
		buffer.write_position(1, 0, 0);	
		
		buffer.write_texCoords(0, 1);
		buffer.write_texCoords(1, 1);
		buffer.write_texCoords(0, 0);
		buffer.write_texCoords(0, 0);
		buffer.write_texCoords(1, 0);
		buffer.write_texCoords(1, 1);	

		buffer.write_alpha(1);
		buffer.write_alpha(1);
		buffer.write_alpha(1);
		buffer.write_alpha(1);
		buffer.write_alpha(1);
		buffer.write_alpha(1);
		buffer.upload(); //TODO could be removed and done automatically in program.draw

		
		// program.set_uColor(1.0,0,0); //TODO? would clear cache and set values to be uploaded only
		
		program.set_tex(_texture);
		var view = new Mat4();
		program.set_view(view.translate(view,-0.5,0,0));
		program.draw(buffer); //TODO should be able to specify the number of indices/vertices
		//TODO? should be able to specify gpu state ?


		js.Browser.window.requestAnimationFrame(render);
		return true;
	}
}