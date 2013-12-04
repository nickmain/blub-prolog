package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.Structure;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.compiler.Instruction;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;

/**
 * If/then/else
 */
class IfThenElse extends BuiltinPredicate {

    public function new() {
		super( "#if_then_else", 3 );
	}

    /**
     * Compile a call to this predicate
     */
    override public function compile( compiler:CompilerBase, pred:Predicate, term:ClauseTerm ) {
		var ifThen   = term.asStructure();
		var ifTerm   = ifThen.argAt(0);
		var thenTerm = ifThen.argAt(1);
        var elseTerm = ifThen.argAt(2);
				
		//make a sub-goal from the term
        // ((<if> , !, <then>) ; <else>)
        // i.e. the cut will nuke the else
		
		var atoms = compiler.database.context;
        
        var cutAtom  = atoms.getAtom("!");

        // !,<then>       
        var conjunc2 = new Structure( atoms.getAtom(",") );
        conjunc2.addArg( cutAtom );
        conjunc2.addArg( thenTerm );

        // <if>,!,<then>
        var conjunc1 = new Structure( atoms.getAtom(",") );
        conjunc1.addArg( ifTerm );
        conjunc1.addArg( conjunc2 );
        
        // (<if> , !, <then>) ; <else>
        var disjunc  = new Structure( atoms.getAtom(";") );
        disjunc.addArg( conjunc1 );
        disjunc.addArg( elseTerm );

        //compile as a nested term prefixed with a cut-point        
        compiler.compileNestedTerm( disjunc, true );
    } 
}