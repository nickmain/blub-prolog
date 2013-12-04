package blub.prolog.builtins.meta;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Atom;
import blub.prolog.engine.QueryEngine;
import blub.prolog.Query;

/**
 * Create a new Query and QueryEngine.
 * 
 * query( QueryTerm, Template, QueryRef ) -
 *     QueryTerm is the query to perform - must be a valid query
 *     Template  is the term to construct to capture each solution
 *     QueryRef  must be a variable that will receive a reference to the query
 * 
 * Example -
 *     query(foo(A,B),soln(A,B),Q) - each time a new solution is captured it
 *     will be a clone of soln/2 with copies of the values of A and B.
 */
class MetaQuery extends BuiltinPredicate {

    public function new() {
		super( "query", 3 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var queryTerm = args[0].toValue(env).dereference();
        var template  = args[1].toValue(env).dereference();
	    var queryVar  = args[2].toValue(env).dereference();
	
	    if( queryVar.asReference() == null ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_variable, 
                                        queryVar, 
                                        engine.context ) );
            return; 			
		}
	
	    if( ! Std.is( queryTerm, ClauseTerm ) ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_callable, 
                                        queryTerm, 
                                        engine.context ) );
            return;										
		}
	   
	    var queryClause:ClauseTerm = cast queryTerm;
		
		var query = new TemplateQuery( engine, queryClause, template );
		var atom  = Atom.unregisteredAtom( "query:" );// + queryClause );
		atom.object = query;
		engine.unify( queryVar, atom );
	}
}

class TemplateQuery {
	
	private var query:Query;
	private var template:ValueTerm;
	
	
	public function new(  engine:QueryEngine, queryTerm:ClauseTerm, template:ValueTerm ) {
		var stru = queryTerm.asStructure();
		
		//convert query back into variable form
		if( stru != null ) {		
			queryTerm = stru.variablize();			
		}
		
		this.query = new Query( engine.database, queryTerm );
		this.template = template.asValueTerm();

        /* bind the query term to env of the query and then unify it
         * with the original query.
         * 
         *   foo(Ref1,Ref2)
         *     -variabalize-
         *   foo(Var1,Var2)
         *     -toValue(env)-
         *   foo(QueryRef1,QueryRef2)
         *     -unify-
         *   Ref1->QueryRef1, Ref2->QueryRef2
         *   
         *   Now deref-ing the template will capture the query solution.
         */
        if( stru != null ) {
			var env = query.engine.environment;
			var deref = queryTerm.toValue(env);
			stru.unify(deref,engine);  //point incoming refs at refs in the query
        }		
	}
	
	/** Halt the query engine */
	public function halt() {
		query.engine.halt;
	}
	
    /**
     * Unify the next solution with the given term - return false if no solution
     * or unification fails.
     */
    public function nextSolution( engine:QueryEngine, soln:ValueTerm ):Bool {
		var result = query.nextSolution();
		if( result == null ) return false;
		
		switch( result ) {
            case failure: return false;
            case success: return true;
            case bindings(b): {
                //capture the solution by derefing the template
                var captured = template.dereference();
				
				if( ! soln.unify( captured, engine ) ) {
					query.putBack( result );
					return false;
				}
				
			    return true;
			}
        }
    }	
}
