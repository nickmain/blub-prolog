package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Reference;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;

/**
 * retract
 */
class Retract extends BuiltinPredicate {
    public function new() {
		super( "retract", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		var term = args[0].toValue(env).dereference();

		if( ! Std.is( term, ClauseTerm )) {
			engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_callable, 
                                        term, 
                                        engine.context ) );
            return;										
		}
		
		var ct:ClauseTerm = cast term;
		var functor = ct.getIndicator();
		
		var predicate = engine.database.lookup(functor);
		if( predicate == null ) return;
		
		for( clause in predicate.clauses() ) {
			var cterm = clause.term;
			
			//make a temp env and convert to a value term
			var env   = clause.variableContext.createEnvironment();
			var vterm = cterm.toValue( env );
			
			//unify the clause term with the arg
			if( vterm.unify( term, null )  ) {
                engine.makeTransaction().retract( clause );
				return;				
			}
		}
		
        //no clauses matched - just carry on
	}
}
