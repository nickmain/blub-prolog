package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.Structure;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.compiler.Instruction;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;

/**
 * If/then
 */
class IfThen extends BuiltinPredicate {

    public function new() {
		super( "->", 2 );
	}

    /**
     * Compile a call to this predicate
     */
    override public function compile( compiler:CompilerBase, pred:Predicate, term:ClauseTerm ) {
		var ifThen   = term.asStructure();
		var ifTerm   = compiler.clauseTerm( ifThen.argAt(0) );
		var thenTerm = compiler.clauseTerm( ifThen.argAt(1) );
				
        compiler.add( cut_point );
        compiler.compileTerm( ifTerm );
        compiler.add( cut );				
        compiler.compileTerm( thenTerm );				
    } 
}