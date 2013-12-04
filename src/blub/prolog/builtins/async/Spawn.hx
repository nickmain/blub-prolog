package blub.prolog.builtins.async;

import blub.prolog.PrologException;
import blub.prolog.async.AsyncQuery;
import blub.prolog.async.AsyncResultsImpl;
import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;

/**
 * Spawn an asynchronous query. Unbound vars in the query term are copied so
 * that they no longer have the same reference as the original query.
 * 
 * This is an operator - the arg should either be a single predicate call or
 * a multi term query enclosed in curly braces. (Parentheses also suffice).
 * 
 * This is NOT an asynchronous predicate - it returns immediately.
 */
class Spawn extends BuiltinPredicate {

    public function new() {
		super( "spawn", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var queryArg = args[0].toValue(env).dereference();
		 		 
		var stru = queryArg.asStructure();
		if( stru != null ) {
			
			//unwrap braces
		    if( stru.getName().text == "{}" ) {
				queryArg = stru.argAt(0).asValueTerm();
				
				stru = queryArg.asStructure();				
				if( stru != null ) queryArg = stru.variablize();  //turn refs back into vars
			}
			else {
				queryArg = stru.variablize();  //turn refs back into vars
			}
		}

        if( ! Std.is( queryArg, ClauseTerm ) ) {
            engine.raiseException( 
                RuntimeError.typeError( 
                    TypeError.VALID_TYPE_callable, queryArg, engine.context ) );
		}

        var query = new AsyncQuery( engine.database, cast queryArg );
		query.execute();
		
		//assumption - at this point the async QueryEngine is referenced by
		//an async operation (such as an event listener) and it is safe from
		//garbage collection
	}
}