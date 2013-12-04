package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.engine.QueryEngine;

/**
 * Create new unique atom (not registered in the Context)
 */
class Gensym extends BuiltinPredicate {
	static var count:Int = 1;
	
    public function new() {
		super( "gensym", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var base = args[0].toValue(env);
		 
		var baseAtom = base.asAtom();
		if( baseAtom == null ) {
			engine.raiseException( 
			    RuntimeError.typeError( 
				    TypeError.VALID_TYPE_atom, base, engine.context ) );
		}
				
		engine.unify( args[1].toValue(env), Atom.unregisteredAtom( baseAtom.text + (count++)) );
	}
}
