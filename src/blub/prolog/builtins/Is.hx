package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.NumberTerm;

/**
 * Arithmetic "is"
 */
class Is extends BuiltinPredicate {

    public function new() {
		super( "is", 2 );
	}

    override function execute( engine:QueryEngine, args:Array<Term> ) {
        var env = engine.environment;
        var a = args[0].toValue(env);
        var b = args[1].toValue(env);
        
        var num = b.asNumber();
        if( num == null ) num = new NumberTerm( engine.arithmetic.evaluate( b ));
        
        engine.unify( a, num );
    }
}

