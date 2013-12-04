package blub.prolog.compiler;

import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.Operations;

typedef InstructionList = Array<Instruction>;

/**
 * The instruction set of the Prolog engine
 */
enum Instruction {
	
    call_builtin( functor:String, args:Array<Term> ); // Call a built-in predicate
    call_pred( functor:String, args:Array<Term> );    // Call a predicate
    tail_call( functor:String, args:Array<Term> );    // Tail call to a predicate
    call_clauses( functor:String );                   // Call the clauses of a predicate - 
                                                      //   either by jump, choice-point or fail

    arg_to_env( argIndex:Int, envIndex:Int );    // Copy an argument to the environment
    set_args( terms:Array<Term> );               // Set the call args
    set_arg_values( terms:Arguments );           // Set the call args to value terms
    unify_args( head:ClauseTerm );               // Unify all the args with a clause head, or fail
    unify_arg( index:Int, term:Term );           // Unify a given arg with a term or fail
    
    choice_point( alternative:InstructionList ); // Choice point that backtracks to the alternative
    call_nested( code:InstructionList );         // Push a frame and call a nested instruction list
    
    new_environment( size:Int );    // Create a new environment for a set of variables
    push_code_frame;                // Push a code frame
    pop_code_frame;                 // Pop a code frame
    succeed;                        // Succeed and pop any enclosing code frame
    no_op;                          // A no-op
    fail;                           // Fail and cause backtracking
    cut;                            // Cut
    cut_point;                      // Push a cut barrier
    log( msg:String );              // Log a message
    call_back( fn:Operation );      // Callback function

    dump;                           // Dump the current state of the engine
    halt;                           // Halt the query and discard all choice points
    debug_trace( msg:String );      // Trace a message - for debug only
    halt_count( count:Int );        // Halt after a given number of calls - for debug

}
