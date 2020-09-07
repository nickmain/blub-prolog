package blub.prolog.engine;

import blub.prolog.engine.Operations;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Reference;
import blub.prolog.terms.Variable;
import blub.prolog.terms.VariableContext;
import blub.prolog.Database;
import blub.prolog.PrologException;

import blub.prolog.engine.parts.CodeFrame;
import blub.prolog.engine.parts.ChoicePoint;
import blub.prolog.engine.parts.CutPoint;
import blub.prolog.engine.parts.ClauseChoices;


#if (flash11 || flash10)
typedef Arguments = flash.Vector<ValueTerm>;
#else
typedef Arguments = Array<ValueTerm>;
#end

/**
 * Callback for async operation. 
 */
typedef AsyncCallback = QueryEngine -> AsyncCallbackType -> Void;
enum AsyncCallbackType { asyncSoln; asyncDone; asyncHalt; asyncStart; }


typedef CutBarrier = {
	var prev:CutBarrier;
	var choice:ChoicePoint;
}

typedef Binding = {
    var next:Binding;
    var ref:Reference;
	var old:ValueTerm;
}

/**
 * The engine that performs a query
 */
class QueryEngine implements BindingTrail {

    #if query_trace
    public var traceQuery:Bool; //whether to trace query execution
    #end
	
	public var database    (default,null):Database;
    public var arithmetic  (get,null):ArithmeticEvaluator;
    public var isHalted    (default,null):Bool;
	
	/** Whether a breakpoint has been reached */
	public var atBreakpoint(default,null):Bool;
	
	/** If running under the debugger, the exception that caused a break */
	public var exception   (default,null):PrologError;
	
    var logger:String->Void;	
	
	//==== Instructions interact with these vars =========
	
	public var codeStack:CodeFrame; //stack of saved code frames
	
	public var codePointer:OperationList; //instruction to be executed
	
	public var bindings:Binding;
	
	public var cutBarrier:CutBarrier;  //pointer at choicepoint to nuke upon cut
	
	public var choiceStack:ChoicePoint;
	
	public var solutionFound:Bool;
	
	public var arguments:Arguments;
	
	public var environment:TermEnvironment;
		
	public var context:Clause; //used when throwing exceptions
	
	//====================================================
	
	var _arithmetic:ArithmeticEvaluator;
	function get_arithmetic() {
		if( _arithmetic == null ) _arithmetic = new ArithmeticEvaluator( this ); 
		return _arithmetic;
	}
	
	public function new( database:Database, code:OperationList ) {
	    this.database  = database;
		codePointer = code;
		isAsync = false;
		isHalted = false;
		atBreakpoint = false;
	}
	
	public var transaction:DatabaseTransaction; //could be null	
	public function makeTransaction() {
		if( transaction == null ) transaction = new DatabaseTransaction( database );
		return transaction;
	}
	
	/**
     * Find the next solution
     * 
     * @return false if no more solutions
     */
	public function findSolution():Bool {
		if( isHalted ) return false;
		
		isAsync = false;
		
        #if query_trace
        if( traceQuery ) log( "QueryEngine::findSolution()" );
        #end
		
	    if( codePointer == null && ! backtrack() ) {
            #if query_trace
            if( traceQuery ) log( "QueryEngine - no more solutions" );
            #end
			
			return false;
		}
        	  
	    solutionFound = false;
			  
	    //execute instructions until no more
	    while( codePointer != null ) {
			var op = codePointer.op;
			codePointer = codePointer.next;
			op( this );
		}
	   
        #if query_trace
        if( traceQuery ) log( "QueryEngine - solutionFound=" + solutionFound );
        #end

	    return solutionFound;
	}
	
    /**
     * Execute one step at a time - synchronous queries only.
     */
    public function executeStep() {
		clearBreakpoint();		
        if( isHalted ) return;		
        isAsync = false;

        solutionFound = false;
        
        if( codePointer == null ) {
			backtrack(); 
			return;
		}
              
        if( codePointer != null ) {
            var op = codePointer.op;
            codePointer = codePointer.next;
            op( this );			
        }
    }	
	
	/**
	 * Run until a breakpoint is reached or an exception is raised. 
	 */
	public function debugRun() {
		clearBreakpoint();
        if( isHalted ) return;      		
        isAsync = false;

        solutionFound = false;
        
		try {
            if( codePointer == null ) {
                if( ! backtrack() ) return;
            }
				  
            while( codePointer != null ) {
                var op = codePointer.op;
                codePointer = codePointer.next;
                op( this );
				
				if( atBreakpoint ) return;        
            }
		}
		catch( ex:PrologError ) {
			exception = ex;
		}
	}
	
	/**
	 * Clear any breakpoint or raise the pending the exception
	 */
	inline function clearBreakpoint() {
        atBreakpoint = false;
		
        if( exception != null ) {
            var e = exception;
            exception = null;
            throw exception;
        }		
	}
	
	//== Asynchronous operation...
	private var asyncCallback:AsyncCallback;
	private var asyncUnderway:Bool;
	private var asyncOp:blub.prolog.builtins.async.AsyncOperation;  //ref to the async op itself
    
	/** Whether the current code loop can handle asynchronous operations */	
    public var isAsync (default,null):Bool;

	/** The result of the last async operation, if any */
	public var asyncResult(default,null):Dynamic;
	
	/**
	 * Get the async operation - may be null.
	 */
	public function getCurrentAsyncOp():blub.prolog.builtins.async.AsyncOperation {
		return asyncOp;
	}
	
	/**
	 * Execute the query asynchronously and return when the first async operation
	 * is encountered (or the query is complete without any async ops).
	 * 
	 * Optional callback is used to signal solutions (or failure) and any
	 * async pauses.
	 */
	public function executeAsync( ?asyncCallback:AsyncCallback ) {
		this.asyncCallback = asyncCallback;
        continueAsync();		
	}
	
	/**
	 * Called by an async predicate to indicate that it is about to initiate
	 * an asynchronous operation. If the engine is not within executeAsync or
	 * continueAsync then this method will throw an exception.
	 * 
	 * @param operation an opaque reference to the operation 
	 *                  (a place for it to live without being garbage collected)
	 * @param msg indicates the nature of the async operation 
	 */
	public function beginAsync( operation:blub.prolog.builtins.async.AsyncOperation ) {
		if( ! isAsync ) throw new PrologError( "Async predicate can only be used in an async query, op:" + operation.getDescription() );
		asyncOp     = operation;
		asyncResult = null;
		asyncUnderway = true;
	}
	
	/**
	 * Called by an async predicate to indicate that it is ready for query
	 * execution to continue.
	 */
	public function continueAsync( ?result:Dynamic ) {
		if( isHalted ) return;
		
		asyncOp       = null;
		isAsync       = true;
		asyncResult   = result;
		asyncUnderway = false;

        //loop to keep generating solutions - until no more solutions or
        //an async operation starts
        while( true ) {
				
    		if( codePointer == null && ! backtrack() ) {
    			//notify of end of query
                if( asyncCallback != null ) asyncCallback( this, asyncDone );
                return;
            }
                  
            solutionFound = false;
                  
            //execute instructions until no more or an async op has been started
            while( codePointer != null && ! asyncUnderway ) {
                var op = codePointer.op;
                codePointer = codePointer.next;
                op( this );
            }
           
            //notify of solution or async pause
            if( asyncCallback != null ) 
			    asyncCallback( this, if( asyncUnderway ) asyncStart else asyncSoln );
    		
            //stop the loop until async op causes continuation		
    		if( asyncUnderway ) return;
		}
	}

	/** Halt the engine - no more code execution will be done */
	public function halt() {
		log( "*** HALTED ***" );
		codePointer = null;
		codeStack   = null;
		solutionFound = false;
		isHalted = true;
		
		//release any choice points
		if( choiceStack != null ) {			
			var cp = choiceStack;
			while( cp != null ) {
				cp.halt();
				cp = cp.prev;
			}
			
			choiceStack = null;
		}
		
		if( asyncOp != null ) {
			asyncOp.cancel();
		    asyncOp = null;
		}
		
		asyncResult   = null;
		asyncUnderway = false;
		
		//notify of halt
        if( asyncCallback != null ) asyncCallback( this, asyncHalt );		
	}
	
	//backtrack to last choice-point
	function backtrack():Bool {
        #if query_trace
        if( traceQuery ) log( "QueryEngine::backtrack()" );
        #end
		
	    solutionFound = false;	
		codePointer = null;
		codeStack = null;

		//back up through choice points until one has a valid choice
		while( choiceStack != null ) {
			choiceStack.undoBindings();
			if( choiceStack.nextChoice() ) {
                #if query_trace
                if( traceQuery ) log( "QueryEngine - choice found" );
                #end
				
				return true;
			}
		}
		
		return false;
	}
	
	/**
	 * Enact a breakpoint - only has an effect if executing within the 
	 * runDebug() loop.
	 */
	public function breakpoint() {
		atBreakpoint = true;
	}
	
	/** 
	 * Called by built-in preds to start processing of custom choice-points
	 * (as an alternative to calling fail() )
	 */
	public function processBuiltinChoices() {
		backtrack();
	}
	
	/** Log a message */
	inline public function log( msg:String ) {
		if( logger != null ) logger( msg );
	}
	
	/** Set a logger */
	public function setLogger( fn:String->Void ) {
		logger = fn;
	}
	
	/** Raise a prolog exception */
	public function raiseException( exception:PrologException ) {
		//TODO:

        #if query_trace
        if( traceQuery ) log( "QueryEngine::raiseException()" );
        #end

		throw exception;
	}
	
	/**
	 * Unify two terms. If unification failed then call fail() and return
	 * false, otherwise return true (but do not call succeed).
	 */
	public function unify( termA:ValueTerm, termB:ValueTerm ):Bool {
		
        #if query_trace
        if( traceQuery ) log( "QueryEngine::unify( " + termA + ", " + termB + " )" );
        #end		
		
		if( termA.unify( termB, this ) ) {
			return true;
		}
		
		fail();
		return false;
	}
	
	/**
	 * Indicate success and return up to any enclosing code frame
	 */
	public function succeed() {
        #if query_trace
        if( traceQuery ) log( "QueryEngine::succeed()" );
        #end
		
		if( codeStack != null ) {
			popCodeFrame();
			return;
		}
		
		solutionFound = true;
		codePointer = null;
	}

    /**
     * Indicate failure and backtrack
     */
    public function fail() {
        #if query_trace
        if( traceQuery ) log( "QueryEngine::fail()" );
        #end

        backtrack();
    }

    /**
     * Discard all choice points more recent than the current cut-barrier
     */
    public function cut() {
        #if query_trace
        if( traceQuery ) log( "QueryEngine::cut()" );
        #end
				
        if( cutBarrier != null ) {
			choiceStack = cutBarrier.choice.prev;
			cutBarrier = cutBarrier.prev;
		}
		else {
			choiceStack = null;
		}
    }

    /** BindingTrail interface - record a binding that should be undone upon backtracking */
    public function newBinding( ref:Reference, oldValue:ValueTerm ) {
        bindings = { next:bindings, ref:ref, old:oldValue };
    }

    /** BindingTrail interface */
    public function bookmark():Dynamic {
		return bindings;
	}
	
	/** BindingTrail interface */
    public function undo( bookmark:Dynamic ):Void {
		undoBindings( bookmark );
	}

    /** Undo all the bindings made since the given one */
    inline public function undoBindings( prevBind:Binding ) {
        var bind = bindings;
        
        //process all bindings until the one before this choice point
        while( bind != null && bind != prevBind ) {
            bind.ref.unbind( bind.old );          
            bind = bind.next;
        }
        
        //reset the binding pointer
        bindings = prevBind;
    }

    /** drop a cut barrier */
    inline public function pushCutPoint() {
		var cp:ChoicePoint = new CutPoint( this );
        cutBarrier = { prev:cutBarrier, choice:cp };
    }
	
	/** denote a choicepoint that is a cut barrier  */
    inline public function pushCutBarrier( cpnt:ChoicePoint ) {
        cutBarrier = { prev:cutBarrier, choice:cpnt };
    }
	
	inline public function pushCodeFrame() {
        codeStack = new CodeFrame( this );  
	}
	
	inline public function popCodeFrame() {
		if( codeStack != null ) codeStack.restore();
	}
	
	/** 
	 * Create a new current environment and fill it with unbound References
	 */
	inline public function createEnvironment( size:Int ) {
		environment = new TermEnvironment();
        for( i in 0...size ) environment.push( new Reference() );
	}
	
	/** Set up the args - constant terms or Variables indexing the env */
	inline public function setArguments( newArgs:Array<Term> ) {
		if( newArgs != null ) {
    		var args = new Arguments();
            var env  = environment;
                
            for( t in newArgs ) {
                //value should be as free of environment as possible    
                args.push( t.toValue(env) ); //.dereference() );
            }
                
            arguments = args;
		}
		else arguments = null;           		
	}
	
    /**
     * Set a logger function that writes via trace
     */    
	public function useTraceLogger( ?prefix:String = ":" ) {
		traceCount = 0;
		tracePrefix = prefix;
		logger = traceLogger;				
	}
	
	var tracePrefix:String;
	var traceCount:Int;
	function traceLogger( msg:String ) { 
        haxe.Log.trace( msg, { methodName  : null,
			                   lineNumber  : (traceCount++),
							   fileName    : tracePrefix,
							   customParams: null,
							   className   : null });
	}
	
	/**
	 * Dump the current state of the engine 
	 */
	public function dump() {
        log( "---------------------------------------" );
        log( "codeStack:     " + codeStack );
        log( "codePointer:   " + codePointer );
        log( "cutBarrier:    " + cutBarrier );
        log( "choiceStack:   " + choiceStack );
        log( "solutionFound: " + solutionFound );
        log( "arguments:     " + arguments );
        log( "environment:   " + environment );
        log( "---------------------------------------" );
	}
}

