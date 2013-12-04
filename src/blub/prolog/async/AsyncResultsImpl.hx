package blub.prolog.async;

import blub.prolog.terms.Term;

/**
 * AsyncResults implementation
 */
class AsyncResultsImpl implements AsyncResults {
	
    public function new() {}
	
    public function asyncSolution( query:AsyncQuery, bindings:Map<String,Term> ) {}
    public function asyncFail( query:AsyncQuery ) {}
    public function asyncDone( query:AsyncQuery ) { doneOrHalted(query); }
    public function asyncOperation( query:AsyncQuery ) {}
    public function asyncHalt( query:AsyncQuery ) { doneOrHalted(query); }
	
	/** override */
	function doneOrHalted( query:AsyncQuery ) {}
}
