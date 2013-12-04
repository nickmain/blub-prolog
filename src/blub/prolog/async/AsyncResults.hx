package blub.prolog.async;

import blub.prolog.terms.Term;

/**
 * Callback interface for AsyncQuery results
 */
interface AsyncResults {

    /**
     * A solution has been found.
     * The bindings will be null if there are no variables in the query.
     */
    public function asyncSolution( query:AsyncQuery, bindings:Map<String,Term> ):Void;
	
	/**
	 * The query failed (there may have been prior solutions). asyncDone will
	 * be called after this.
	 */
	public function asyncFail( query:AsyncQuery ):Void;
	
	/**
	 * The query has completed - there are no more choice points.
	 */
	public function asyncDone( query:AsyncQuery ):Void;
	
	/**
	 * The engine is suspending due to an asynchronous operation
	 */
	public function asyncOperation( query:AsyncQuery ):Void;
	
    /**
     * The query has been halted
     */
    public function asyncHalt( query:AsyncQuery ):Void;
	
}
