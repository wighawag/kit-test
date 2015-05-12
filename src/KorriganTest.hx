import boot.Runner;
import boot.Runnable;
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

class KorriganTest implements Runnable{

	var gpu : GPU;
	var loader : Loader;

	var colorProgram : ColorProgram;
	var colorBuffer  : GPUBuffer<ColorProgram>;
	var secondColorBuffer  : GPUBuffer<ColorProgram>;

	var program : NormalTexturedProgram;
	var buffer  : GPUBuffer<NormalTexturedProgram>;
	var context : TransformationContext;
	var spriteLibrary : SpriteLibrary;

	var _diffuse : GPUTexture;
	var _normal: GPUTexture;
	var proj : Mat4;
	var view: Mat4;
	var viewproj : Mat4;

	//model
	var _runner : Runner;
	var spaceshipAngle : Float;
	var spaceshipX : Float;
	var spaceshipY : Float;
	var lightBoxX : Float;
	var lightBoxY : Float;


	var focusWidth = 600;
	var focusHeight = 400;

	var worldWidth = 1000;
	var worldHeight = 1000;


	var visibleWidth : Float;
	var visibleHeight : Float;

	static function main() : Void{
		trace("korrigan test");
		new KorriganTest();
	}

	public function new( ){
		loader = new Loader();
		gpu = GPU.init({viewportType : Fill /*KeepRatioUsingBorder(focusWidth, focusHeight)*/, viewportPosition: Center, maxHDPI:1});
		program = NormalTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<NormalTexturedProgram>(gpu, GL.DYNAMIC_DRAW); 

		colorProgram = ColorProgram.upload(gpu);
		colorBuffer = new GPUBuffer<ColorProgram>(gpu, GL.DYNAMIC_DRAW);


		secondColorBuffer = new GPUBuffer<ColorProgram>(gpu, GL.DYNAMIC_DRAW);

		context = new TransformationContext();
		proj = new Mat4();
		view = new Mat4();
		viewproj = new Mat4();
		
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

				_runner = new Runner(this);
				_runner.start(30);
			case Failure(e):
				trace(e);
		}
		
	}


	var scale : Float = 1;
	function onViewportChanged(x : Int, y : Int, width : Int, height : Int){
		proj.ortho(0, width, height,0,-1,1);
		//if Fill 
		var widthRatio = width/focusWidth;
		var heightRatio = height/focusHeight;
		//var scale : Float = 1;
		if(widthRatio > heightRatio){
			scale = heightRatio; 
		}else{
			scale = widthRatio; 
		}
		//TODO support light when scale =1 (while the drawingbuffer has a different scale)
		//proj.scale(proj,scale, scale, 1);
		visibleWidth = width / scale;
		visibleHeight = height / scale;
		//else
		// proj.scale(proj,width/logicalWidth, height/logicalHeight, 1);
		// visibleWidth = logicalWidth;
		// visibleHeight = logicalHeight;
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
		view.identity();
		view.scale(view,scale,scale,1);
		view.translate(view, visibleWidth/2 -spaceshipX,visibleHeight/2 -spaceshipY, 0);
		viewproj.multiply(proj, view);

		//TODO limit the side

		//TODO support zooming

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
		colorProgram.set_viewproj(viewproj);
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

		program.set_viewproj(viewproj);
		program.set_ambientColor(0.2,0.2,0.2,0.2);
		var lightPosVec = new Vec3(lightBoxX,lightBoxY,0.075);
		lightPosVec.transformMat4(lightPosVec, view);
		program.set_lightPos(lightPosVec.x + gpu.viewportX, lightPosVec.y + gpu.viewportY, lightPosVec.z);
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