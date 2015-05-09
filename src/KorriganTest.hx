import haxe.Json;
import korrigan.TransformationContext;
import loka.asset.Image;
import loka.asset.Loader;
import boot.Assets;
import glee.GPUBuffer;
import glee.GPUTexture;

using glmat.Mat4;
import glmat.Vec2;
import glmat.Vec3;
import glmat.Vec4;
import korrigan.SpriteLibrary;
import korrigan.NormalTexturedProgram;

import loka.gl.GL;
import loka.App;

import glee.GPU;
import glee.GPUTexture;
import tri.ColorProgram;

class KorriganTest{

	var logicalWidth = 600;
	var logicalHeight = 400;
	var gpu : GPU;
	var loader : Loader;

	var colorProgram : ColorProgram;
	var colorBuffer  : GPUBuffer<ColorProgram>;

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
		loader = new Loader();
		gpu = GPU.init({viewportType : FillUpToRatios(1/4,4), viewportPosition: Center, maxHDPI:1});
		program = NormalTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<NormalTexturedProgram>(gpu, GL.DYNAMIC_DRAW); 

		colorProgram = ColorProgram.upload(gpu);
		colorBuffer = new GPUBuffer<ColorProgram>(gpu, GL.DYNAMIC_DRAW);

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

		        //gpu.setWindowResizeCallback(onWindowResized);
		        //onWindowResized(gpu.windowWidth, gpu.windowHeight);
		        gpu.setViewportChangeCallback(onViewportChanged);
		        onViewportChanged(gpu.viewportX, gpu.viewportY, gpu.viewportWidth, gpu.viewportHeight);
				gpu.setRenderFunction(render);
			case Failure(e):
				trace(e);
		}
		
	}

	// function onWindowResized(width : Float, height : Float){
	// 	mat.ortho(0, logicalWidth, logicalHeight,0,-1,1);
	// }

	function onViewportChanged(x : Int, y : Int, width : Int, height : Int){
		mat.ortho(0, width, height,0,-1,1);
		//if Fill 
		//todo centering
		var widthRatio = width/logicalWidth;
		var heightRatio = height/logicalHeight;
		var scale : Float = 1;
		if(widthRatio > heightRatio){
			scale = heightRatio; 
		}else{
			scale = widthRatio; 
		}
		mat.scale(mat,scale, scale, 1);
		//else
		//mat.scale(mat,width/logicalWidth, height/logicalHeight, 1);
	}

	function render(now : Float) {

		var width = logicalWidth;
		var height = logicalHeight;

		gpu.clearWith(0,0,0,1);

		var r = 0.5;
		var g = 0;
		var b = 0.5;
		var a = 1;
		colorBuffer.rewind();
		colorBuffer.write_position(-1,-1,0);
		colorBuffer.write_color(r,g,b,a);
		colorBuffer.write_position(-1,1,0);
		colorBuffer.write_color(r,g,b,a);
		colorBuffer.write_position(1,1,0);
		colorBuffer.write_color(r,g,b,a);

		colorBuffer.write_position(1,1,0);
		colorBuffer.write_color(r,g,b,a);
		colorBuffer.write_position(1,-1,0);
		colorBuffer.write_color(r,g,b,a);
		colorBuffer.write_position(-1,-1,0);
		colorBuffer.write_color(r,g,b,a);
		colorProgram.draw(colorBuffer);

		gpu.gl.enable(GL.BLEND);
		gpu.gl.blendFunc(GL.ONE, GL.ONE_MINUS_SRC_ALPHA);

		buffer.rewind();
		context.save();

		var angle = now;
		context.translate(width/2 + Math.cos(angle) * width/3, height/2  + Math.sin(angle) * height/3);
		context.rotateZ(angle);
		context.scale( Math.cos(angle), Math.sin(angle));

		spriteLibrary.draw(buffer,context,"SpaceShipEvilOne.blend", "idle",0, 0,0,0, 100, 100, true);
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
		

		// //split screen test
		// var numSplit : Int = 2;
		// //to keep same size:
		// //mat.ortho(0, width/numSplit, height,0,-1,1);
		// for (i in 0...numSplit){
		// 	//this is like using Fill
		// 	gpu.setViewPort((gpu.windowWidth/numSplit) * i,0,gpu.windowWidth/numSplit, gpu.windowHeight);
		// 	program.set_view(mat);
		// 	program.draw(buffer);	
		// }

		program.draw(buffer);	
		
		
	}
}