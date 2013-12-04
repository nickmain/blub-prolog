package blub.prolog.engine;

import blub.prolog.Database;
import blub.prolog.Predicate;
import blub.prolog.Clause;
import blub.prolog.terms.ClauseTerm;

/**
 * The asserts/retracts/abolishes requested during a query.
 * To maintain the ISO standard "logical view" of the database these changes
 * should only be committed once the query has been finished.
 */
class DatabaseTransaction {

    var database:Database;
    var preAsserts:Array<ClauseTerm>;
    var postAsserts:Array<ClauseTerm>;
    var retractions:Array<Clause>;
    var abolitions:Array<Predicate>;

    public function new( database:Database ) {
        this.database = database;
	}

    public function preAssert( term:ClauseTerm ) {
		if( preAsserts == null ) preAsserts = new Array<ClauseTerm>();
		preAsserts.push( term );
	}
	
	public function postAssert( term:ClauseTerm ) {
        if( postAsserts == null ) postAsserts = new Array<ClauseTerm>();
        postAsserts.push( term );
    }
	
	public function retract( clause:Clause ) {
		if( retractions == null ) retractions = new Array<Clause>();
		retractions.push( clause );
	}
	
	public function abolish( pred:Predicate ) {
		if( abolitions == null ) abolitions = new Array<Predicate>();
		abolitions.push( pred );
	}
	
	/** Commit the transaction */
	public function commit() {
		
		if( preAsserts != null ) {
            for( term in preAsserts ) {
                database.assertA( term, true );	
            }
		}

        if( postAsserts != null ) {
            for( term in postAsserts ) {
                database.assertZ( term, true ); 
            }
        }
		
		if( retractions != null ) {
			for( clause in retractions ) {
				clause.retract();
			}
		}
		
		if( abolitions != null ) {
			for( pred in abolitions ) pred.abolish();
		}
	}
}
