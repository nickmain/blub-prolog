package blub.prolog.compiler;

import blub.prolog.terms.ClauseTerm;
import blub.prolog.Database;
import blub.prolog.engine.Operations;

/**
 * Compiler for a top-level query
 */
class QueryCompiler extends CompilerBase {
    
    public function new( database:Database ) {
        super( database );
    }
	
	/**
	 * Compile a query
	 */
	public function compile( term:ClauseTerm ):OperationList {	
		compileTerm( term, true );
		
		#if compile_dump
        if( CompilerBase.dumpCompile ) {
			trace("");
			trace( "Query = " + term );
            Assembler.traceDump( instructions, "query" );
        }
        #end
		
		return assemble();
	}
}
