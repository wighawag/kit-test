package;

import loka.asset.Image;
import loka.asset.Loader;
import egg.Assets;
import egg.Batch;
import egg.ImageLoader;
import egg.TextLoader;
import glee.GPUBuffer;
import glee.GPUTexture;
import korrigan.NormalTexturedProgram;
import haxe.Json;
import jsloka.Window;
import korrigan.SpriteLibrary;
import korrigan.TextureAtlas;
import korrigan.TransformationContext;
import kala.Runnable;
import kala.Runner;

import loka.gl.GL;

import glee.GPU;
import glee.GPUTexture;


class BoxTest2 implements Runnable{

	var textureAtlas : TextureAtlas;
	var spriteLibrary : SpriteLibrary;
	var runner : Runner;
	var program : NormalTexturedProgram;
	var buffer  : GPUBuffer<NormalTexturedProgram>;

	var window : Window;
	var gpu : GPU;

	var context : TransformationContext;

	var _texture : GPUTexture;

	public static function main() : Void{
		new BoxTest2();
	}

	public function new(){
		context = new TransformationContext();
		window = Window.createWindow();
		gpu = new GPU(window.gl); 
		program = NormalTexturedProgram.upload(gpu);		
		buffer = new GPUBuffer<NormalTexturedProgram>(gpu, GL.DYNAMIC_DRAW);

		
		Assets.load(["texture.json","sprites.json"],[]).handle( function(outcome : AssetsOutcome){
			switch(outcome){
				case Success(assets):textLoaded(assets.texts);
				case Failure(error):trace("Error", error);
			}
			} );
	}

	function textLoaded(texts : Batch<String>){
		textureAtlas = Json.parse(texts.get("texture.json"));
		var json : SpriteDataSet = Json.parse(texts.get("sprites.json"));
		spriteLibrary = new SpriteLibrary();
		spriteLibrary.loadSprites(json,textureAtlas);
		var imageLoader = new ImageLoader();
		imageLoader.load(textureAtlas.bitmapId).handle(imageLoaded);	
	}

	function imageLoaded(imageOutcome : ImageOutcome){
		switch(imageOutcome){
			case Success(image): 
				_texture = gpu.uploadTexture(image);
				runner = new Runner(this);
				runner.start();

			case Failure(error):trace(error);
		}
	}

	public function start(now : Float) : Void{
		
	}

	public function update(now : Float, dt : Float):Void{
		context.save();
		context.setAlpha(0.9);
		window.resize();//todo on resize event

		window.gl.enable(GL.BLEND);
		window.gl.blendFunc(GL.ONE, GL.ONE_MINUS_SRC_ALPHA);

		var width = Std.int(window.width);
		var height = Std.int(window.height);
		window.gl.viewport(0, 0, width , height);//window.gl.drawingBufferWidth, window.gl.drawingBufferHeight);
		context.ortho(0, width, height,0,-1,1);
		context.translate(width/2, height/2);
		context.scale(0.5,0.5);

		gpu.clearWith(0.1,0.1,0.1, 0.0);

		buffer.rewind();
		spriteLibrary.draw(buffer,context,"SpaceShipEvilOne.blend","idle",1,0,0,0);

		spriteLibrary.draw(buffer,context,"SpaceShipEvilOne.blend","idle",1,200,0,0);
		
		
		program.set_lightPos(200, 200, 0.075);
		program.set_lightColor(1,1,1,1);
		program.set_ambientColor(0,0,0,0);
		program.set_resolution(width,height);
		program.set_falloff(0.2,0.6,1.2); //TODO? would clear cache and set values to be uploaded only
		program.set_tex(_texture);

		
		program.draw(buffer); //TODO should be able to specify the number of indices/vertices
		//TODO? should be able to specify gpu state ?


		context.restore();
	}



}