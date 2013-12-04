package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * true
 */
class True extends BuiltinPredicate {
    public function new() {
		super( "true", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		//nothing to do
	}
}
