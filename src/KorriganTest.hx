import haxe.Json;
import korrigan.TransformationContext;
import loka.asset.Image;
import loka.asset.Loader;
import boot.Assets;
import glee.GPUBuffer;
import glee.GPUTexture;
import haxe.Timer;
import loka.Window;

using glmat.Mat4;
import glmat.Vec2;
import glmat.Vec3;
import glmat.Vec4;
import korrigan.SpriteLibrary;
import korrigan.NormalTexturedProgram;

import loka.gl.GL;

import glee.GPU;
import glee.GPUTexture;

class KorriganTest{

	var window : Window;
	var gpu : GPU;
	var loader : Loader;

	var program : NormalTexturedProgram;
	var buffer  : GPUBuffer<NormalTexturedProgram>;
	var context : TransformationContext;
	var spriteLibrary : SpriteLibrary;

	var _diffuse : GPUTexture;
	var _normal: GPUTexture;
	var mat : Mat4;

	static function main() : Void{
		trace("korrigan test");
		new KorriganTest();
	}

	public function new( ){
		window = Window.createWindow();
		loader = new Loader();
		gpu = new GPU(window.gl);
		program = NormalTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<NormalTexturedProgram>(gpu, GL.STATIC_DRAW); 
		context = new TransformationContext();
		mat = new Mat4();
		
		Assets.load(["texture.json","sprites.json"],["colors.png","normals.png"]).handle(loadingAssets);
	}

	function errorLoading(msg : String) : Void{
		trace(msg);
	}

	function loadingAssets(outcome : AssetsOutcome) : Void{
		trace(outcome);
		switch (outcome) {
			case Success(assets):
				var textureAtlas = Json.parse(assets.texts.get("texture.json"));
		        var json : SpriteDataSet = Json.parse(assets.texts.get("sprites.json"));
		        spriteLibrary = new SpriteLibrary();
		        spriteLibrary.loadSprites(json,textureAtlas);  
				_diffuse = gpu.uploadTexture(assets.images.get("colors.png"));
		        _normal = gpu.uploadTexture(assets.images.get("normals.png"));
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

		mat.ortho(0, width, height,0,-1,1);

		var now = Timer.stamp();
		var delta = now - lastTime;
		lastTime = now;

		
		gpu.clearWith(0.5,0.5,0,1);


		buffer.rewind();
		context.save();
		//context.rotateZ(Math.PI / 2);
		//context.translate(width/2, height/2);
		//context.rotateZ(Math.PI / 2);
		spriteLibrary.draw(buffer,context,"SpaceShipEvilOne.blend", "idle",0, 0,0,0);
		context.restore();
  		buffer.upload();

		program.set_view(mat);
		program.set_ambientColor(1,1,1,1);
		program.set_lightPos(0, 0, 0.1);
		program.set_lightColor(1,1,1,3);
		
		program.set_resolution(width,height);
		program.set_falloff(0,4,80); //TODO? would clear cache and set values to be uploaded only
		program.set_tex(_diffuse);
		program.set_normal(_normal);
		
		program.draw(buffer);

		//TODO : remove js specific
		js.Browser.window.requestAnimationFrame(render);
		
		return true;
	}
}