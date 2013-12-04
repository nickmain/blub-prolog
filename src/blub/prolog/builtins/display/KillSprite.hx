package blub.prolog.builtins.display;

import blub.prolog.PrologException;
import blub.prolog.async.AsyncQuery;
import blub.prolog.async.AsyncResultsImpl;
import blub.prolog.terms.Term;

import blub.prolog.terms.ClauseTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;
import blub.prolog.Marshal;

import blub.prolog.builtins.objects.ObjectWrapper;

/**
 * Kill a sprite
 */
class KillSprite extends BuiltinPredicate {

    public function new() {
		super( "kill_sprite", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var atom = args[0].toValue(env).dereference().asAtom();
				
        if( atom == null ) {
            engine.raiseException( 
                RuntimeError.typeError( 
                    TypeError.VALID_TYPE_atom, atom, engine.context ) );
        }
		
		var obj = atom.object;
		if( obj == null || ! Std.is( obj, ObjectWrapper )) {
			engine.fail();
			return;
		}
		 
		var wrapper:ObjectWrapper = cast obj;
		obj = wrapper.getObject(); 

        if( obj == null || ! Std.is( obj, flash.display.Sprite )) {
            engine.fail();
            return;
        }
		 
		var sprite:flash.display.Sprite = cast obj;

        if( sprite.parent != null ) {
			sprite.parent.removeChild( sprite );		
		}
	}
}
