package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * ==/2
 */
class Identical extends BuiltinPredicate {
    public function new() {
		super( "==", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		if( ! args[0].toValue(env).equals( args[1].toValue(env) )) {
			engine.fail();
		}
	}
}
