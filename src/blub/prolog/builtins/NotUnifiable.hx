package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * Not unifiable
 */
class NotUnifiable extends BuiltinPredicate {
    public function new() {
		super( "\\=", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		var a = args[0].toValue(env);
		var b = args[1].toValue(env);
		
		if( a.unify( b, engine ) ) engine.fail();
	}
}
