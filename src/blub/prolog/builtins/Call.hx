package blub.prolog.builtins;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.NumberTerm;
import blub.prolog.compiler.CompilerBase;
import blub.prolog.engine.Operations;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.PrologException;
import blub.prolog.Predicate;

/**
 * Meta-call
 */
class Call extends BuiltinPredicate {

    public static var INDICATOR = PredicateIndicator.fromString( "call/1" );

    public function new() {
		super( "call", 1 );
	}

    override function execute( engine:QueryEngine, args:Array<Term> ) {
        var goal = args[0].toValue(engine.environment).dereference();
		
		try {
		    var instruction = new CallCompiler( engine ).compileCall( goal );
		
		    engine.pushCodeFrame();
			engine.pushCutPoint();  //this will be popped when the call finishes
		    engine.codePointer = instruction;
			
		}
		catch( ex:NotCallable ) {
		    engine.raiseException( 
			    RuntimeError.typeError( TypeError.VALID_TYPE_callable, 
				                        ex.culprit, 
										engine.context ) );
		}
    }
}

class NotCallable {
	public var culprit:Term;
	public function new( culprit:Term ) {
		this.culprit = culprit;
	}
}

class CallCompiler extends CompilerBase {
	
	var eng:QueryEngine;
	
	public function new( engine:QueryEngine ) {
		super( engine.database );
		eng = engine;
	}
	
	public function compileCall( term:Term ):OperationList {
		var clause = clauseTerm( term );
		var stru = clause.asStructure();
		
		compileTerm( clause, true );
		
		return assemble();
	}
	
	/**
     * Cast to ClauseTerm or throw up
     */
    override function clauseTerm( term:Term ):ClauseTerm {
        if( ! Std.is(term,ClauseTerm)) throw new NotCallable( term );
        return cast term;
    }
}
