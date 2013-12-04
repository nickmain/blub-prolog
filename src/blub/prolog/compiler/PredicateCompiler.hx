package blub.prolog.compiler;

import blub.prolog.Predicate;
import blub.prolog.Database;
import blub.prolog.engine.Operations;
import blub.prolog.compiler.Instruction;

/**
 * Compiler for a predicate
 */
class PredicateCompiler extends CompilerBase {
    
    public function new( database:Database ) {
        super( database );
    }
    
    /**
     * Compile a predicate
     */
    public function compile( predicate:Predicate ):OperationList {
	    add( call_clauses( predicate.indicator.toString() ));
		
		#if compile_dump
        if( CompilerBase.dumpCompile ) {
			trace("");
			Assembler.traceDump( instructions, predicate.indicator.toString() );
		}
        #end
		
		return assemble();
    }
}
