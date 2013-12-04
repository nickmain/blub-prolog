package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * The cut
 */
class Cut extends BuiltinPredicate {
    public function new() {
		super( "!", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		engine.cut();
	}
}
