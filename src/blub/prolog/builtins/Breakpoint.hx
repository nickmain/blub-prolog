package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * Stops the engine if running under the interactive debugger/stepper, otherwise
 * does nothing.
 */
class Breakpoint extends BuiltinPredicate {
    public function new() {
		super( "break", 0 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		engine.breakpoint();
	}
}
