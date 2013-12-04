package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * Unification
 */
class Unify extends BuiltinPredicate {
    public function new() {
		super( "=", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		engine.unify( args[0].toValue(env), args[1].toValue(env) );
	}
}
