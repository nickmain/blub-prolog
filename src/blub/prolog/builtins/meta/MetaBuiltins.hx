package blub.prolog.builtins.meta;

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
 * Predicates that provide access to the underlying query engine
 */
class MetaBuiltins {
	
    public static function get():Array<BuiltinPredicate> {
        return cast [ 
            new MetaAbort(), 
            new MetaQuery(),
            new MetaSolution() 
        ];
    }
}
