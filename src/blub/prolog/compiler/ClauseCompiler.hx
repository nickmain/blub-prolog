package blub.prolog.compiler;

import blub.prolog.Clause;
import blub.prolog.Database;
import blub.prolog.engine.Operations;
import blub.prolog.compiler.Instruction;

/**
 * Compiler for a single clause
 */
class ClauseCompiler extends CompilerBase {

    public function new( database:Database ) {
		super( database );
	}
	
	/**
     * Compile a clause
     */
    public function compile( clause:Clause ):OperationList {
		//add( "debug_trace",  [ "Entering clause " + clause.head.toString() ]);
		
		if( clause.variableContext.count > 0 ) {
		  add( new_environment( clause.variableContext.count ));
		}
		
		var head = clause.head;
		
		//process arguments
		if( head.getIndicator().arity > 0 ) {
			add( unify_args( head ));
		}
		
		//TODO - analyze the clause head and produce more optimized
		//       arg unification/copying instructions
		
		var body = clause.body;
		if( body != null ) compileTerm( body, true )
		else add( succeed );
		
		#if compile_dump
        if( CompilerBase.dumpCompile ) {
			trace("");
            Assembler.traceDump( instructions, clause.head.toString() );
        }
        #end		
		
		return assemble();
    }
}
