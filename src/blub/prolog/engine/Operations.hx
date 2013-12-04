package blub.prolog.engine;

import blub.prolog.Database;
import blub.prolog.AtomContext;
import blub.prolog.Predicate;
import blub.prolog.Clause;
import blub.prolog.PrologException;
import blub.prolog.PrologError;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Variable;
import blub.prolog.terms.VariableContext;
import blub.prolog.terms.Reference;

import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.CodeFrame;
import blub.prolog.engine.parts.ChoicePoint;
import blub.prolog.engine.parts.ClauseChoices;


/** Function signature for an operation */
typedef Operation = QueryEngine->Void;

/** Operation list */
typedef OperationList = { 
	var op  :Operation;
	var asm :Dynamic;   //the assembly
	var next:OperationList;
}

/**
 * Operation functions for the prolog virtual machine
 */
class Operations {

    /** Halt after a given number of calls */
    public static function halt_count( count:Int ) {
		var i = 0;
		
		return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "halt_count" );
            #end
			
			if( i >= count ) eng.halt();
			i++;
		}
	}

    /**
     * Unify a given arg with a term. The term is interpreted within the
     * current environment.
     * Cause a failure if the unification does not succeed.
     */
    public static function unify_arg( index:Int, term:Term ) {
        return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "unify_arg " + index + " " + term.toString() );
            #end
            
			eng.unify( term.toValue( eng.environment ), eng.arguments[index] );
        }
    }

    /**
     * Unify all the args with a clause head.
     * Cause a failure if the unification does not succeed.
     */
    public static function unify_args( head:ClauseTerm ) {
        return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "unify_args " + head.toString() );
            #end
            			
			var stru = head.asStructure();
			if( stru == null ) return;
			
			var headArgs = stru.getArgs();
			
			var args = eng.arguments;
			var numArgs = args.length;
			var env = eng.environment;
			
			for( i in 0...numArgs ) {
				if( ! eng.unify( headArgs[i].toValue( env ), args[i] )) return;
			}
        }
    }

    /** Set up the args - constant terms or Variables indexing the env */
    public static function set_args( terms:Array<Term> ) {
        return function(eng:QueryEngine) {
			#if query_trace
            if( eng.traceQuery ) eng.log( "set_args " + Std.string( terms ) );
            #end
			
			eng.setArguments( terms );			
        }
    }

    /** Copy an argument to the environment */
    public static function arg_to_env( argIndex:Int, envIndex:Int ) {
        return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "arg_to_env arg[" + argIndex + "] env[" + envIndex + "]" );
            #end
            
            eng.environment[envIndex].bind( eng.arguments[argIndex] );
        }
    }

    /** Set the call args to constant terms */
    public static function set_arg_values( terms:Arguments ) {
        return function(eng:QueryEngine) {			
            #if query_trace
            if( eng.traceQuery ) eng.log( "set_arg_values " + Std.string( terms ) );
            #end
            
            eng.arguments = terms;
		}
	}
	
	/** 
	 * Determine the possible clauses for the predicate, given the current
	 * arguments. 
	 * If there are no matching clauses, fail.
	 * If there is only one clause jump to it immediately.
	 * If there are multiple clauses push a choice-point and call the first.
	 */
    public static function call_clauses( db:Database, indicator:PredicateIndicator ) {
		var predicate = db.lookup( indicator );
		if( predicate != null ) {    				
            return function(eng:QueryEngine) {
    			var clauses = predicate.findMatchingClauses( eng.arguments );
    			
    			var len = clauses.length;
    			if( len == 0 ) {
                    #if query_trace
                    if( eng.traceQuery ) eng.log( "call_clauses " + indicator + " -- no clauses" );
                    #end
            					
					eng.fail(); //dynamic predicate ?
				}
                
				//TODO - detect a cut in a single clause and allow this to be uncommented
				/*
				else if( len == 1 ) {
                    #if query_trace
                    if( eng.traceQuery ) eng.log( "call_clauses " + indicator + " -- 1 clause" );
                    #end
            					
                    eng.context     = clauses[0];
                    eng.codePointer = clauses[0].code;
                }
    			*/
				
				else {
                    #if query_trace
                    if( eng.traceQuery ) eng.log( "call_clauses " + indicator + " -- clause choices " + clauses.length );
                    #end
					
					new ClauseChoices( eng, clauses );
				}
            };
		}
		
		//look up predicate at runtime
        return function(eng:QueryEngine) {
			var predicate = db.lookup( indicator );
			if( predicate == null ) {
                #if query_trace
                if( eng.traceQuery ) eng.log( "call_clauses " + indicator + " -- lookup failed" );
                #end
				
				eng.raiseException( RuntimeError.existenceError( ee_procedure, Atom.unregisteredAtom(indicator.toString()), eng.context ));				
				return;
			}
			
            var clauses = predicate.findMatchingClauses( eng.arguments );
            
            var len = clauses.length;
            if( len == 0 ) {
                #if query_trace
                if( eng.traceQuery ) eng.log( "call_clauses " + indicator + " -- dynamic -- no clauses" );
                #end
				
				eng.fail(); //dynamic predicate ?
			}
            
			else if( len == 1 ) {
                #if query_trace
                if( eng.traceQuery ) eng.log( "call_clauses " + indicator + " -- dynamic -- 1 clause" );
                #end

				eng.context     = clauses[0];
				eng.codePointer = clauses[0].code;
			}
            
			else {
                #if query_trace
                if( eng.traceQuery ) eng.log( "call_clauses " + indicator + " -- dynamic -- clause choices " + clauses.length );
                #end
				
				new ClauseChoices( eng, clauses );
			}
        };		
    }
	
	/** Call a built-in predicate */
    public static function call_builtin( db:Database, indicator:PredicateIndicator, args:Array<Term> ) {
        var predicate = db.lookup( indicator );
        if( predicate != null ) {            
            //builtin predicate
            if( predicate.isBuiltin ) {
                return function(eng:QueryEngine) {
                    #if query_trace
                    if( eng.traceQuery ) eng.log( "call_builtin " + indicator + " " + Std.string( args ) );
                    #end
					
                    predicate.builtin.execute( eng, args );
                }
            }
        }
		
		throw new PrologError( "Cannot find built-in " + indicator.toString() );
    }
	
    /** Call a predicate */
    public static function call_pred( db:Database, indicator:PredicateIndicator, args:Array<Term> ) {
        var predicate = db.lookup( indicator );
        if( predicate != null ) {
			
			//builtin predicate
			if( predicate.isBuiltin ) {
				return function(eng:QueryEngine) {
                    #if query_trace
                    if( eng.traceQuery ) eng.log( "call_pred " + indicator + " " + Std.string( args ) + " -- builtin" );
                    #end
					
					predicate.builtin.execute( eng, args );
				}
			}
			
			//user predicate
			else return function(eng:QueryEngine) {
                #if query_trace
                if( eng.traceQuery ) eng.log( "call_pred " + indicator + " " + Std.string( args ) );
                #end

				eng.setArguments( args );
    			eng.pushCodeFrame();
                eng.codePointer = predicate.code;
    	    };
		}
		
		//look up predicate at runtime
        return function(eng:QueryEngine) {
            var predicate = db.lookup( indicator );
            if( predicate == null ) {
                #if query_trace
                if( eng.traceQuery ) eng.log( "call_pred " + indicator + " -- lookup failed" );
                #end
				
                eng.raiseException( RuntimeError.existenceError( ee_procedure, Atom.unregisteredAtom(indicator.toString()), eng.context ));               
                return;
			}

            #if query_trace
            if( eng.traceQuery ) eng.log( "call_pred " + indicator + " " + Std.string( args ) + " -- dynamic" );
            #end

            eng.setArguments( args );
			eng.pushCodeFrame();
            eng.codePointer = predicate.code;
		}
    }

    /** Tail call to a predicate */
    public static function tail_call( db:Database, indicator:PredicateIndicator, args:Array<Term> ) {
        var predicate = db.lookup( indicator );
        if( predicate != null ) {
            return function(eng:QueryEngine) {
                #if query_trace
                if( eng.traceQuery ) eng.log( "tail_call " + indicator + " " + Std.string( args ) );
                #end

                eng.setArguments( args );
                eng.codePointer = predicate.code;
            };
        }
        
        //look up predicate at runtime
        return function(eng:QueryEngine) {
            var predicate = db.lookup( indicator );
            if( predicate == null ) {
                #if query_trace
                if( eng.traceQuery ) eng.log( "tail_call " + indicator + " -- lookup failed" );
                #end
                
                eng.raiseException( RuntimeError.existenceError( ee_procedure, Atom.unregisteredAtom(indicator.toString()), eng.context ));               
                return;
			}
			
            #if query_trace
            if( eng.traceQuery ) eng.log( "tail_call " + indicator + " " + Std.string( args ) + " -- dynamic" );
            #end

            eng.setArguments( args );
            eng.codePointer = predicate.code;
        }        
    }

    /** Push a choice point that jumps to the given alternative upon backtracking */
    public static function choice_point( alternative:OperationList ) {
        return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "choice_point ..." );
            #end
			
            new ChoicePoint( eng, 
			    new CodeFrame( eng, alternative ));
        }             
    }

    /** Succeed and return to any enclosing code */
    public static function succeed(eng:QueryEngine) {		
        #if query_trace
        if( eng.traceQuery ) eng.log( "succeed" );
        #end
            
        eng.succeed();
    }   

    /** A no-op */
    public static function no_op(eng:QueryEngine) {       
        #if query_trace
        if( eng.traceQuery ) eng.log( "no_op" );
        #end
            
        //nothing
    }   

    /** Fail and cause backtracking */
    public static function fail(eng:QueryEngine) {
        #if query_trace
        if( eng.traceQuery ) eng.log( "fail" );
        #end
            
        eng.fail();         
    }   

    /** Cut */
    public static function cut(eng:QueryEngine) {
        #if query_trace
        if( eng.traceQuery ) eng.log( "cut" );
        #end
            
        eng.cut();         
    }   
	
	/** Push a cut barrier */
    public static function cut_point(eng:QueryEngine) {
        #if query_trace
        if( eng.traceQuery ) eng.log( "cut_point" );
        #end
            
        eng.pushCutPoint();         
    }   
	
    /** Log a message */
    public static function log( msg:String ) {
		return function(eng:QueryEngine) { 
			eng.log(msg); 
	    };
	}

    /** Trace a message - for debug only */
    public static function debug_trace( msg:String ) {
        return function(eng:QueryEngine) { trace(msg); };
    }
	
	/** Callback function */
    public static function call_back( fn:Operation ) {
		return fn;
	}
	
    /** Dump the current state of the engine */
    public static function dump(eng:QueryEngine) {
        eng.dump();         
    }
	
	/** Halt the engine */
    public static function halt(eng:QueryEngine) {
        #if query_trace
        if( eng.traceQuery ) eng.log( "halt" );
        #end
            
        eng.halt();         
    }       

    /** create a new environment for a set of variables */
    public static function new_environment( size:Int ) {
        return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "new_environment " + size );
            #end
            
            eng.createEnvironment( size ); 
        }            
    }   

    /** Push a code frame  */
    public static function push_code_frame(eng:QueryEngine) {
        #if query_trace
        if( eng.traceQuery ) eng.log( "push_code_frame" );
        #end
            
        eng.pushCodeFrame();         
    }   

    /** push a frame and call a nested instruction list */
    public static function call_nested( code:OperationList ) {
        return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "call_nested ..." );
            #end
            
            eng.pushCodeFrame();
            eng.codePointer = code;
        }            
    } 

    /** Pop a code frame and use it to restore working props */
    public static function pop_code_frame(eng:QueryEngine) {
        #if query_trace
        if( eng.traceQuery ) eng.log( "pop_code_frame" );
        #end
            
        eng.popCodeFrame();         
    }   

    /** Unconditional jump */
    public static function jump_to( code:OperationList ) {
        return function(eng:QueryEngine) {
            #if query_trace
            if( eng.traceQuery ) eng.log( "jump_to ..." );
            #end
            
            eng.codePointer = code; 
        }            
    }
}
