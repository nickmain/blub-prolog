package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.Structure;
import blub.prolog.compiler.CompilerBase;

import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;

/**
 * Not provable
 */
class NotProvable extends BuiltinPredicate {

    public function new() {
		super( "\\+", 1 );
	}

    /**
     * Compile a call to this predicate
     */
    override public function compile( compiler:CompilerBase, pred:Predicate, term:ClauseTerm ) {		
		// rewrite <goal>  --> (<goal>,!,fail ; true) 
		
		var atoms = compiler.database.context;
		
		var trueAtom = atoms.getAtom("true");
		var failAtom = atoms.getAtom("fail");
        var cutAtom  = atoms.getAtom("!");

        // !,fail		
		var conjunc2 = new Structure( atoms.getAtom(",") );
        conjunc2.addArg( cutAtom );
		conjunc2.addArg( failAtom );

        // <goal>,!,fail
        var conjunc1 = new Structure( atoms.getAtom(",") );
        conjunc1.addArg( term.asStructure().argAt(0) );
        conjunc1.addArg( conjunc2 );
		
		// <goal>,!,fail ; true
        var disjunc  = new Structure( atoms.getAtom(";") );
        disjunc.addArg( conjunc1 );
		disjunc.addArg( trueAtom );
		
		compiler.compileNestedTerm( disjunc, true );
    } 
}