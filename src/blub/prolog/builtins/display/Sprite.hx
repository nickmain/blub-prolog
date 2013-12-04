package blub.prolog.builtins.display;

import blub.prolog.PrologException;
import blub.prolog.async.AsyncQuery;
import blub.prolog.async.AsyncResultsImpl;
import blub.prolog.terms.Term;

import blub.prolog.terms.ClauseTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;
import blub.prolog.Marshal;


/**
 * Create a new sprite and add it to the stage.
 * The arg must be an unbound reference.
 */
class Sprite extends BuiltinPredicate {

    public function new() {
		super( "sprite", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var ref = args[0].toValue(env).dereference().asReference();
		
        if( ref == null ) {
            engine.raiseException( 
                RuntimeError.typeError( 
                    TypeError.VALID_TYPE_variable, ref, engine.context ) );
        }
		
		var sprite = new flash.display.Sprite();
		flash.Lib.current.stage.addChild( sprite );
		var spriteAtom = Marshal.valueToTerm( sprite );

		engine.unify( ref, spriteAtom );		
	}
}
