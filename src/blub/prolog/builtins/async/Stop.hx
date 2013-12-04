package blub.prolog.builtins.async;

import blub.prolog.AtomContext;
import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;

/**
 * Stop (halt) an asynchronous QueryEngine. Arg must be an atom returned from
 * spawns/2.
 * 
 * This is NOT an asynchronous predicate.
 */
class Stop extends BuiltinPredicate {

    public function new() {
		super( "stop", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var atom = args[0].toValue(env).asAtom();
		 
		if( atom == null ) {
			engine.raiseException( 
			    RuntimeError.typeError( 
				    TypeError.VALID_TYPE_atom, args[0], engine.context ) );
		}
		
		if( atom.object == null || ! Std.is( atom.object, QueryEngine ) ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "atom must contain a spawned query: " + atom ), 
                    engine.context ));
            return;
		}
		
		var eng2:QueryEngine = cast atom.object;
		eng2.halt();
	}
}
