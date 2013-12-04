package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * write/1
 * 
 * TODO - operators
 */
class Write extends BuiltinPredicate {
	
    public function new() {
		super( "write", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		
        haxe.Log.trace( args[0].toValue(env).dereference().toString() );
	}
}
