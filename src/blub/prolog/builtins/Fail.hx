package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * fail
 */
class Fail extends BuiltinPredicate {
    public function new() {
		super( "fail", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		engine.fail();
	}
}
