package blub.prolog.builtins;

import blub.prolog.Marshal;
import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Reference;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.QueryEngine;

/**
 * Predicates for accessing database global values
 */
class Globals {
	
    public static function get():Array<BuiltinPredicate> {
        return cast [ 
            new GetGlobal(),
            new SetGlobal()         
        ];
    }
}

/**
 * Access a global value - RHS is atom key
 */
class GetGlobal extends BuiltinPredicate {
    
    public function new() { super( "from_global", 2 ); }

    override function execute( engine:QueryEngine, args:Array<Term> ) {
        var env = engine.environment;
        var a = args[0].toValue(env).dereference();
        var b = args[1].toValue(env).dereference();
                
        var key = b.asAtom();
		if( b == null ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "RHS of from_global must be atom key" ), 
                    engine.context ));
            return;			
		}
		
		var value = engine.database.globals.get( b.asAtom().text );
		if( value == null ) value = AtomContext.GLOBALS.getAtom("null");
		
		engine.unify( a, value );
    }   
}

/**
 * Set a global value - RHS is atom key
 */
class SetGlobal extends BuiltinPredicate {
	
	public function new() { super( "to_global", 2 ); }

    override function execute( engine:QueryEngine, args:Array<Term> ) {		
        var env = engine.environment;
        var a = args[0].toValue(env).dereference();
		var b = args[1].toValue(env).dereference();

        var key = b.asAtom();
        if( b == null ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "RHS of to_global must be atom key" ), 
                    engine.context ));
            return;         
        }

        engine.database.globals.set( key.text, a );
    }	
}