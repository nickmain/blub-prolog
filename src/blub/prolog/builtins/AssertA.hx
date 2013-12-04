package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.Structure;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;

/**
 * asserta
 */
class AssertA extends BuiltinPredicate {
    public function new() {
		super( "asserta", 1 );
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
		
		var clauseTerm:ClauseTerm = cast term;
		
		var stru = clauseTerm.asStructure();
		if( stru != null ) clauseTerm = stru.variablize(); //turn refs into vars
		
		engine.makeTransaction().preAssert( clauseTerm );
	}
}
