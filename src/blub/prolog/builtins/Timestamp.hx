package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.terms.NumberTerm;
import blub.prolog.engine.QueryEngine;
import haxe.Timer;

/**
 * timestamp/1
 */
class Timestamp extends BuiltinPredicate {
    public function new() {
		super( "timestamp", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		engine.unify( args[0].toValue(engine.environment), new NumberTerm( Timer.stamp() ));
	}
}
