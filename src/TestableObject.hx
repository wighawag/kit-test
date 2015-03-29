import belt.ArgumentNameMacro;

class TestableObject{
	
	public function new(){}
	
	macro static public function test(that : haxe.macro.Expr, args : haxe.macro.Expr){
		var expr = ArgumentNameMacro.generateFunctionCall(that,args, "__test__", haxe.macro.Context.typeof(that), haxe.macro.Context.currentPos());
		if(expr == null){
			haxe.macro.Context.error("error", haxe.macro.Context.currentPos());
		}
		return expr;
	}

	#if !display
	@:noComplete //TODO seems to have no effect (need to use if# !display)
	public function __test__(a : Int, b : Int, c : String){

	}
	#end
	
}