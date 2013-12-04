package blub.prolog.async;

import blub.prolog.terms.Term;

/**
 * AsyncResults implementation that traces all calls - for debug purposes
 */
class AsyncResultTracer implements AsyncResults {
	var prefix:String;
	
    public function new( prefix:String ) {
		this.prefix = prefix;
	}
	
	/** AsyncResults */
    public function asyncSolution( query:AsyncQuery, bindings:Map<String,Term> ) {
		trace( prefix + " solution " + Std.string( bindings ) );
	}
    
    /** AsyncResults */
    public function asyncFail( query:AsyncQuery ) { trace( prefix + " fail" ); }
    
    /** AsyncResults */
    public function asyncDone( query:AsyncQuery ) { trace( prefix + " done" ); }
    
    /** AsyncResults */
    public function asyncOperation( query:AsyncQuery ) { 
		trace( prefix + " async-op: " + query.engine.getCurrentAsyncOp() ); 
	}
    
    /** AsyncResults */
    public function asyncHalt( query:AsyncQuery ) { trace( prefix + " HALT" ); }
}
