import boot.Runner;
import boot.Runnable;
import haxe.Json;
import korrigan.TransformationContext;
import boot.GenericAssetLoader;
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

import korrigan.OrthoCamera;

class KorriganTest implements Runnable{

	inline static var FOCUS_WIDTH = 600;
	inline static var FOCUS_HEIGHT = 400;

	var gpu : GPU;

	var colorProgram : ColorProgram;
	var colorBuffer  : GPUBuffer<ColorProgram>;
	var secondColorBuffer  : GPUBuffer<ColorProgram>;

	var program : NormalTexturedProgram;
	var buffer  : GPUBuffer<NormalTexturedProgram>;
	var context : TransformationContext;
	var spriteLibrary : SpriteLibrary;

	var _diffuse : GPUTexture;
	var _normal: GPUTexture;

	var _camera : OrthoCamera;

	//model
	var _runner : Runner;
	var worldWidth = 1000;
	var worldHeight = 1000;
	var spaceshipAngle : Float;
	var spaceshipX : Float;
	var spaceshipY : Float;
	var lightBoxX : Float;
	var lightBoxY : Float;
	

	static function main() : Void{
		trace("korrigan test");
		new KorriganTest();
	}

	public function new( ){
		gpu = GPU.init({viewportType : Fill /*KeepRatioUsingBorder(FOCUS_WIDTH, FOCUS_HEIGHT)*/, viewportPosition: Center, maxHDPI:1});
		_camera = new OrthoCamera(gpu, FOCUS_WIDTH, FOCUS_HEIGHT, {scale:true});

		program = NormalTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<NormalTexturedProgram>(gpu, GL.DYNAMIC_DRAW); 

		colorProgram = ColorProgram.upload(gpu);
		colorBuffer = new GPUBuffer<ColorProgram>(gpu, GL.DYNAMIC_DRAW);


		secondColorBuffer = new GPUBuffer<ColorProgram>(gpu, GL.DYNAMIC_DRAW);

		context = new TransformationContext();
		
		var loader = GenericAssetLoader.init();
		loader.load(Assets.ALL).handle(loadingAssets);
	}

	function errorLoading(msg : String) : Void{
		trace(msg);
	}

	function loadingAssets(outcome : AssetsOutcome) : Void{
		trace(outcome);
		switch (outcome) {
			case Success(assets):
				var textureAtlas = Json.parse(assets.get(Assets.texture__json));
		        var json : SpriteDataSet = Json.parse(assets.get(Assets.sprites__json));
		        spriteLibrary = new SpriteLibrary();
		        spriteLibrary.loadSprites(json,textureAtlas);  
				_diffuse = gpu.uploadTexture(assets.get(Assets.colors__png));
		        _normal = gpu.uploadTexture(assets.get(Assets.normals__png));


				gpu.setRenderFunction(render);

				_runner = new Runner(this);
				_runner.start(30);
			case Failure(e):
				trace(e);
		}
		
	}



	public function start(now : Float){
		update(now,0);
	}

	public function update(now : Float, dt : Float){
		spaceshipAngle = now;
		spaceshipX = worldWidth/2 + Math.cos(spaceshipAngle) * worldWidth/3;
		spaceshipY = worldHeight/2  + Math.sin(spaceshipAngle) * worldHeight/3;
		lightBoxX = worldWidth/2;
		lightBoxY = worldHeight/2;
	}

	function render(now : Float) {
		//centering
		_camera.centerOn(spaceshipX, spaceshipY);
		
		gpu.clearWith(0,0,0,1);

		var r = 0.5;
		var g = 0.0;
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
		colorProgram.set_viewproj(new Mat4());
		colorProgram.draw(colorBuffer);

		gpu.enableBlending();
		gpu.setBlendingFunc(GL.ONE, GL.ONE_MINUS_SRC_ALPHA);

		r = 1.0;
		g = 0.2;
		b = 0.1;
		a= 1;
		secondColorBuffer.rewind();
		secondColorBuffer.write_position(lightBoxX-50,lightBoxY-50,0);
		secondColorBuffer.write_color(r,g,b,a);
		secondColorBuffer.write_position(lightBoxX-50,lightBoxY+50,0);
		secondColorBuffer.write_color(r,g,b,a);
		secondColorBuffer.write_position(lightBoxX+50,lightBoxY+50,0);
		secondColorBuffer.write_color(r,g,b,a);

		secondColorBuffer.write_position(lightBoxX+50,lightBoxY+50,0);
		secondColorBuffer.write_color(r,g,b,a);
		secondColorBuffer.write_position(lightBoxX+50,lightBoxY-50,0);
		secondColorBuffer.write_color(r,g,b,a);
		secondColorBuffer.write_position(lightBoxX-50,lightBoxY-50,0);
		secondColorBuffer.write_color(r,g,b,a);
		colorProgram.set_viewproj(_camera.viewproj);
		colorProgram.draw(secondColorBuffer);

		buffer.rewind();
		context.save();

		context.translate(spaceshipX, spaceshipY);
		//TODO TOFIX (rotated normal map fails) : context.rotateZ(Math.PI);
		//context.rotateZ(spaceshipAngle);
		//context.scale( Math.cos(spaceshipAngle), Math.sin(spaceshipAngle));

		spriteLibrary.draw(buffer,context,"SpaceShipEvilOne.blend", "idle",0, 0,0,0, 100, 100, true);
		context.restore();
  		buffer.upload();

		program.set_viewproj(_camera.viewproj);
		program.set_ambientColor(0.2,0.2,0.2,0.2);
		var lightPosVec = new Vec3(lightBoxX,lightBoxY,0.075);
		lightPosVec = _camera.toBufferCoordinates(lightPosVec, lightPosVec);
		program.set_lightPos(lightPosVec.x, lightPosVec.y, lightPosVec.z);
		program.set_lightColor(1,1,1,3);
		
		program.set_resolution(gpu.windowWidth, gpu.windowHeight); //TODO use bufferWidth ...
		program.set_falloff(0.2,0.4,0.8); //TODO? would clear cache and set values to be uploaded only
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