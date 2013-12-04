package blub.prolog.builtins.meta;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.Query;
import blub.prolog.engine.QueryEngine;

import blub.prolog.builtins.meta.MetaQuery;

/**
 * Capture the next solution from the query created with query/3 (see MetaQuery).
 * 
 * solution( Query, Soln )
 *     Query is the reference returned from query/3
 *     Soln  is unified with the solution captured via the template in query/3
 *     
 * The next solution from the Query is fetched each time this is called - except
 * that if the solution does not unify with Soln it is cached and used for the
 * next call.
 * 
 * This predicate will fail if the underlying query fails or there are no more 
 * solutions.
 * 
 * TODO: exception handling ??
 */
class MetaSolution extends BuiltinPredicate {

    public function new() {
		super( "solution", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var queryAtom = args[0].toValue(env).dereference().asAtom();
		var soln = args[1].toValue(env).dereference();

        if( queryAtom == null 
		 || queryAtom.object == null 
		 || ! Std.is( queryAtom.object, TemplateQuery ) ) {			
		    engine.fail();
			return;			 
		}
		
		var query:TemplateQuery = cast queryAtom.object;
		
		if( ! query.nextSolution( engine, soln ) ) engine.fail();
	}
}
