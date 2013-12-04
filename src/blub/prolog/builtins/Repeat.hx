package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.RepeatingChoicePoint;

/**
 * repeat
 */
class Repeat extends BuiltinPredicate {
    public function new() {
		super( "repeat", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		//push a choice point that always returns to the point after the call to this
		new RepeatingChoicePoint( engine );
	}
}

