package blub.prolog;

import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Variable;
import blub.prolog.terms.Reference;
import blub.prolog.terms.VariableContext;
import blub.prolog.terms.Structure;

import blub.prolog.Database;
import blub.prolog.Result;

import blub.prolog.engine.Operations;
import blub.prolog.engine.QueryEngine;

import blub.prolog.compiler.QueryCompiler;

import haxe.Timer;

/**
 * A query
 */
@:expose
class Query {

    #if query_trace
	public var traceQuery:Bool; //whether to trace query execution
	#end

    var autocommit:Bool;          
    var committed:Bool;
    var hadResults:Bool;

    var database:Database;
	var term:ClauseTerm;

    //for the Iterable and Iterator functions:
    var nextResult:Result;

    /** Compiled code */
	var _code:OperationList;
    public var code(get_code,null):OperationList;

    public var environment     (default,null):TermEnvironment;
    public var variableContext (default,null):VariableContext;

    var _engine:QueryEngine;
    public var engine (get_engine,null):QueryEngine;

	/** Get a timestamp - here to allow JS to access haxe.Timer */
	public static function timestamp():Float {
		return Timer.stamp();
	}

    /**
     * @param database the database to operate on
     * @param term the query to execute
     * @param autocommit true (default) to commit the query once all 
     * solutions have been explored, otherwise commit() needs
     * to be called to add assert/retract/abolish changes to the database
     */
    public function new( database:Database, term:ClauseTerm, ?autocommit:Bool = true ) {
		this.database = database;
		this.term = term;
		this.autocommit = autocommit;
	
        variableContext = if( Std.is( term, Structure ))       
            cast( term, Structure ).variableContext;        
            else VariableContext.EMPTY;
	}
    
	/** Explicitly set the code */
    public function setCode( code:OperationList ) {
        _code = code;
		_engine = null;
    }
	
	function get_code():OperationList {
		if( _code == null ) _code = new QueryCompiler( database ).compile( term );       
		return _code;
	}
	
	function get_engine():QueryEngine {
		if( _engine == null ) {
			_engine = new QueryEngine( database, code );
			
			#if query_trace
			if( traceQuery ) {
                _engine.traceQuery = traceQuery;
				_engine.useTraceLogger();
			}			
            #end
			
			_engine.createEnvironment( variableContext.count );
			environment = _engine.environment;
		}
		return _engine;
	}
	
    /**
     * Lazy iterator over the solutions
     */
    public function iterator<Result>() {
        return this;
    }
	
	/**
	 * Put back a solution so that it will be returned next
	 */
	public function putBack( solution:Result ) {
		nextResult = solution;
	}
	
    /** Iterator<Result> typedef */
    public function hasNext():Bool {
        if( nextResult != null ) return true;
        nextResult = nextSolution();
        if( nextResult != null ) return true;
        return false;
    }
	
	/** Iterator<Result> typedef */
    public function next():Result {
        if( nextResult != null ) {
            var result = nextResult;
            nextResult = null;
            return result;
        }
        
        return nextSolution();
    }
	
	/**
     * Complete the query by finding and discarding all remaining solutions
     */
    public function complete() {
        while( nextSolution() != null ) {}
    }
    
    /**
     * Get all the results
     */
    public function allResults():Array<Result> {
        var res = new Array<Result>();
        var result:Result;
        
        while((result = nextSolution()) != null ) {
            res.push( result );
        }
        
        return res;
    }
    
    /**
     * Finish the query by searching any unexplored solution branches
     * (and discarding any solutions found therein) and then commit any
     * changes (asserts) to the database.
     */
    public function commit() {
        complete();
        _commit();
    }	
	
    /**
     * Get all the success results - return an empty array if query failed
     */
    public function allSolutions():Array<Result> {
        var res = new Array<Result>();
        var result:Result;
        
        while((result = nextSolution()) != null ) {
            if( ! ResultUtil.isSuccess( result )) break;
            res.push( result );
        }
        
        return res;
    }
    
	/**
     * Get all the result bindings - return an empty array if query succeeded
     * but there were no bindings, null if the query failed.
     */
    public function allBindings():Array<Map<String,Term>> {
        var res = new Array<Map<String,Term>>();
        var result:Result;
        
        while((result = nextSolution()) != null ) {
            if( ! ResultUtil.isSuccess( result )) return null;
			var binds = ResultUtil.getBindings( result );
			if( binds == null ) return res;
			
            res.push( binds );
        }
        
        return res;
    }
	
    /**
     * Get the next solution, if any. Will always return at least one
     * result, even if that is a fail.
     * 
     * @return null if there are no more solutions
     */
    public function nextSolution():Result {
        if( nextResult != null ) {
            var r = nextResult;
            nextResult = null;
            return r;
        }
    
	    var result:Result;
		
        if( ! engine.findSolution() ) {
            if( autocommit ) _commit();
            if( hadResults ) return null;               
			
            #if query_trace
            if( traceQuery ) {
                _engine.log( "Query-result = failure" );
            }           
            #end
			
            result = failure;
        }
		else {
			result = grabCurrentSolution();
		}
        
        hadResults = true;
        return result;
    }
	
	/** Grab the current bindings of the query vars as a result */
	public function grabCurrentSolution():Result {
        if( variableContext.count == 0 ) {
            #if query_trace
            if( traceQuery ) {
                _engine.log( "Query-result = success" );
            }           
            #end
            
            return success;
        }
        else {
            //make a hash of the environment
            var binds = makeBindings();
            
            #if query_trace
            if( traceQuery ) {
                _engine.log( "Query-result = " + binds );
            }           
            #end
            
            return bindings(binds);
        }		
	}
	
	/**
	 * Make bindings from the environment
	 */
    function makeBindings():Map<String,Term> {
		if( variableContext.count == 0 ) return null;
		
        var binds = new Map<String,Term>();
		
		//for env ref to new var
		var refVars = new Map<Reference,Variable>();
		
        for( v in variableContext.variables() ) {
			var value:Term = environment[ v.index ].dereference();
			
			//unbound refs in the env need to be turned back into vars
			var ref = value.asReference();
			if( ref != null ) {
				var v = refVars.get( ref );
				if( v == null ) {
					v = new Variable();
					refVars.set( ref, v ); 
				}
				
				value = v;
			}
			
			//structures need to be re-variablized
			var s = value.asStructure();
			if( s != null && s.hasReferences() ) {
				value = s.variablize( refVars );
			}
			
            binds.set( v.name, value );
        }
		
		return binds;
	}
	
	/** commit the query transaction, if any */
	private function _commit() {
        if( committed ) return;
        if( _engine.transaction != null ) _engine.transaction.commit();
        committed = true;
    }
}
