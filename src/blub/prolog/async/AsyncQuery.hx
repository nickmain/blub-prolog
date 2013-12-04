package blub.prolog.async;

import blub.prolog.terms.ClauseTerm;
import blub.prolog.Query;
import blub.prolog.engine.QueryEngine;

/**
 * An asynchronous query.
 * 
 * This allows asynchronous predicates to be used and solutions to be passed
 * asynchronously to an implementation of AsyncResults.
 * 
 * If the query does not involve any asynchronous predicates then it will
 * execute entirely synchronously.
 */
class AsyncQuery extends Query {

    /**
     * @param database the database to operate on
     * @param term the query to execute
     * @param autocommit true (default) to commit the query once all 
     * solutions have been explored, otherwise commit() needs
     * to be called to add assert/retract/abolish changes to the database
     */
    public function new( database:Database, term:ClauseTerm, ?autocommit:Bool = true ) {
		super( database, term, autocommit );		
	}

    /**
     * Execute the query and pass results to the callback. The callback can be
     * omitted if solutions are not required and the query is only used for
     * side-effects.
     * 
     * The query will execute synchronously until the first asynchronous
     * operation (predicate call) is encountered, at which point this method
     * will return.
     */
    public function execute( ?resultCallback:AsyncResults ) {	
		if( resultCallback == null ) {
			engine.executeAsync();
			return;
		}
		
	    engine.executeAsync( function( eng:QueryEngine, type:AsyncCallbackType ):Void {
			switch( type ) {
				case asyncStart: resultCallback.asyncOperation( this );
				case asyncHalt:  resultCallback.asyncHalt( this );
				case asyncDone:  resultCallback.asyncDone( this );
				case asyncSoln:	{
				    if( ! engine.solutionFound ) {
                        resultCallback.asyncFail( this );
                    }
                    else {
                        resultCallback.asyncSolution( this, makeBindings() );
                    }		
				}
			}			
		});		
	}
}
