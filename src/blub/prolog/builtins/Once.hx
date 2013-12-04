package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.NumberTerm;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.compiler.Instruction;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;
import blub.prolog.Predicate;

/**
 * Meta-call once
 */
class Once extends BuiltinPredicate {

    public function new() {
		super( "once", 1 );
	}

    /**
     * Compile a call to this predicate
     */
    override public function compile( compiler:CompilerBase, pred:Predicate, term:ClauseTerm ) {
		//defer to call/1		
		var call = compiler.database.lookup( Call.INDICATOR );
		
		//localized cut around call to call/1
		compiler.add( cut_point );
        compiler.add( call_builtin( "call/1", term.asStructure().getArgs() ));
		compiler.add( cut );
    } 
}