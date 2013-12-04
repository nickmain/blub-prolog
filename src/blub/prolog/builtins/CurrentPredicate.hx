package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;

/**
 * current_predicate/1
 */
class CurrentPredicate extends BuiltinPredicate {
	
	var count:Int;
	
    public function new() {
		super( "current_predicate", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		
        haxe.Log.trace( args[0].toValue(env).dereference().toString(), 
		               { methodName  : null,
                       lineNumber  : (count++),
                       fileName    : "",
                       customParams: null,
                       className   : null });
	}
}
