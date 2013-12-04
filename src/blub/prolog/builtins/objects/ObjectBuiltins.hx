package blub.prolog.builtins.objects;

import blub.prolog.Marshal;
import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Reference;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;

/**
 * Predicates for accessing object fields and functions
 */
class ObjectBuiltins {
	
    public static function get():Array<BuiltinPredicate> {
        return cast [ 
            new DotAccessor(), 
            new ArrowAssigner() //,
			//new PropertyChanges() 
        ];
    }
}

/** TODO
 * Implemented by native objects that provide a dynamic set of properties
 */
interface NativeAccess {
	public function get( name:String ):Dynamic;
	public function set( name:String, value:Dynamic ):Void;
}
