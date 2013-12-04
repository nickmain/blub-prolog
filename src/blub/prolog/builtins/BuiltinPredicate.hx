package blub.prolog.builtins;

import blub.prolog.Database;
import blub.prolog.Predicate;

import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Atom;

import blub.prolog.engine.QueryEngine;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.compiler.Instruction;

/**
 * Base for builtins
 */
class BuiltinPredicate {

    var name:String;
	var arity:Int;

    function new( name:String, arity:Int ) {
		this.arity = arity;
		this.name  = name; 
	}

    /**
     * Register a predicate in the given database
     */
    public function register( database:Database ) {
		var nameAtom = database.context.getAtom( name );
        var pred = database.addPredicate( new PredicateIndicator(nameAtom, arity), false );
		pred.setBuiltin( this );
	}
	
	/**
	 * Compile a call to this predicate
	 */
	public function compile( compiler:CompilerBase, pred:Predicate, term:ClauseTerm ) {
		var stru = term.asStructure();
		var args = if( stru != null ) stru.getArgs() else null;
		compiler.add( call_builtin( pred.indicator.toString(), args ));
	}
	
	/** Execute */
	public function execute( engine:QueryEngine, args:Array<Term> ) {		
		//override		
	}
}
