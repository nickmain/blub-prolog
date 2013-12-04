package blub.prolog.builtins.async;

import blub.prolog.AtomContext;
import blub.prolog.PrologException;
import blub.prolog.async.AsyncQuery;
import blub.prolog.async.AsyncResultsImpl;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;

/**
 * Spawn an asynchronous query and return the QueryEngine as an atom that can
 * be used with stop/1 to halt the query. Example: A spawns foo(bar) - A
 * receives the engine atom. 
 * 
 * Unbound vars in the query term are copied so
 * that they no longer have the same reference as the original query.
 * 
 * This is an operator - the arg should either be a single predicate call or
 * a multi term query enclosed in curly braces. (Parentheses also suffice).
 * 
 * This is NOT an asynchronous predicate - it returns immediately.
 */
class Spawns extends BuiltinPredicate {

    var count:Int;

    public function new() {
		super( "spawns", 2 );
		count = 0;
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var ref      = args[0].toValue(env).asReference();
		var queryArg = args[1].toValue(env).dereference();
		 		 
        if( ref == null ) {
            engine.raiseException( 
                RuntimeError.typeError( 
                    TypeError.VALID_TYPE_variable, args[0], engine.context ) );							 
		}
				 
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
		
		var atom = Atom.unregisteredAtom( "spawned-query#" + (count++) );
		atom.object = query.engine;
		engine.unify( ref, atom );
	}
}