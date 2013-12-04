package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Reference;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;
import blub.prolog.Predicate;

/**
 * abolish
 */
class Abolish extends BuiltinPredicate {
    public function new() {
		super( "abolish", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		var term = args[0].toValue(env).dereference();

        var stru = term.asStructure();
		
		var indicator = PredicateIndicator.fromTerm( term, engine.context );
		
		var predicate = engine.database.lookup( indicator );
		if( predicate == null ) return;
		
		engine.makeTransaction().abolish( predicate );
	}
}
