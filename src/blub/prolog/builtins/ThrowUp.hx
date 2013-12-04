package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.PrologException;

/**
 * throw_up/1 - throw a native exception (not an ISO standard Prolog exception)
 */
class ThrowUp extends BuiltinPredicate {
	
    public function new() {
		super( "throw_up", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		
		//actually throw a prolog exception - but this is not synced up with
		//any ISO compliant machinery that may be added to the engine in future.
        throw new PrologException( args[0].toValue(env).dereference(), engine.context );
	}
}
