package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * Print listing of current predicates to trace
 */
class Listing extends BuiltinPredicate {
    public function new() {
		super( "listing", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
	    engine.database.listing( function(s:String) { trace(s); });
	}
}
