
//jsloka setup example

using glmat.Mat4;
import loka.asset.Image;
import loka.asset.Loader;
import glee.GPUBuffer;
import haxe.Timer;
import loka.App;

import korrigan.SimpleTexturedProgram;

import loka.gl.GL;

import glee.GPU;
import glee.GPUTexture;

class BoxTest{

	var program : SimpleTexturedProgram;
	var buffer  : GPUBuffer<SimpleTexturedProgram>;

	var gpu : GPU;
	var loader : Loader;

	var _texture : GPUTexture;

	static function main() : Void{
		new BoxTest();
	}

	public function new( ){
		loader = new Loader();
		gpu = GPU.init(); 
		program = SimpleTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<SimpleTexturedProgram>(gpu, GL.DYNAMIC_DRAW);

		loader.loadImage("test.png",assetLoaded , errorLoading);
	}

	function errorLoading(msg : String) : Void{
		trace(msg);
	}

	function assetLoaded(image : Image) : Void{
		_texture = gpu.uploadTexture(image);

		gpu.setRenderFunction(render);
	}

	function render(now : Float) {
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
	}
}