package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * clear/0
 * 
 * Clear the trace output
 */
class Clear extends BuiltinPredicate {
	
    public function new() {
		super( "clear", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
        // haxe.Log.clear();
	}
}
