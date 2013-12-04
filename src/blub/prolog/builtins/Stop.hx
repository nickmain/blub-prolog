package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * stop/0 - stop the current query in its tracks.
 * Will cancel any async operation underway and release all choice-point resources.
 */
class Stop extends BuiltinPredicate {
    public function new() {
		super( "stop", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		engine.halt();
	}
}
