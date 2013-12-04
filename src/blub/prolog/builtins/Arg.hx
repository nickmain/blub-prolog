package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Reference;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.ChoicePoint;

/**
 * arg(?Arg, +Term, ?Value)
 * 
 * Term should be instantiated to a term, Arg to an integer between 1 and the
 * arity of Term. 
 * 
 * Value is unified with the Arg-th argument of Term.
 * Arg may also be unbound. In this case Value will be unified with the
 * successive arguments of the term. 
 * On successful unification, Arg is unified with the argument number.
 * 
 * Backtracking yields alternative solutions. 
 * The predicate arg/3 fails silently if Arg = 0 or Arg > arity and raises
 * the exception domain_error(not_less_then_zero, Arg) if Arg < 0.
 */
class Arg extends BuiltinPredicate {
	
    public function new() {
		super( "arg", 3 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var arg   = args[0].toValue(env);
        var term  = args[1].toValue(env);
        var value = args[2].toValue(env);
		 
		var atom = term.asAtom();
		if( atom != null ) {
			engine.fail();
			return;
		}
		 
		var stru = term.asStructure();
		if( stru == null ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_compound, 
                                        term, 
                                        engine.context ) );
            return;													
		}
		 
		var argNum = arg.asNumber();
		if( argNum != null ) {
			executeIndex( engine, argNum, stru, value );
			return;
		}
		
		var argRef = arg.asReference();
		if( argRef == null ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_variable, 
                                        arg, 
                                        engine.context ) );
            return;                                                 			
		}
		
		executeChoices( engine, argRef, stru, value );
	}

    /** Index is not specified - muliple choices */
    private function executeChoices( engine:QueryEngine, argRef:Reference, stru:Structure, value:ValueTerm ) {
		var arity = stru.getArity();
		
        for( i in 0...arity ) {
            var arg = stru.argAt( i ).asValueTerm();
			
			var binds = engine.bindings;
						
            if( arg.unify( value, engine ) ) {
				argRef.unify( new NumberTerm( i + 1 ), engine );

                //choice point for trying remaining args
                if( i < arity - 1 ) {
					var cp = new ArgChoicePoint( engine, i + 1, argRef, stru, value );
					cp.bindings = binds;
				}
				return;
			}
		}
		
		//no arg was unifiable
		engine.fail();
	}
	
	/** Index is specified */
	private function executeIndex( engine:QueryEngine, argNum:NumberTerm, stru:Structure, value:ValueTerm ) {
        var index = Std.int(argNum.value);
        
        if( index < 0 ) {
            engine.raiseException( 
                RuntimeError.domainError( "not_less_than_zero",
                                          argNum, 
                                          engine.context ) );
            return;
        }
        
        if( index == 0 || index > stru.getArity() ) {
            engine.fail();
            return;             
        }
		
		var arg = stru.argAt( index - 1 ).asValueTerm();
		engine.unify( arg, value );
	}
}

/**
 * Choice point for args 
 */
class ArgChoicePoint extends ChoicePoint { 
	
	var index:Int;
	var argRef:Reference;
	var stru:Structure;
	var value:ValueTerm;
	
    public function new( eng:QueryEngine, index:Int, argRef:Reference, stru:Structure, value:ValueTerm ) {
        super( eng, eng.codeStack );
		this.index  = index;
		this.argRef = argRef;
		this.stru   = stru;
		this.value  = value;
    }
    
    override public function nextChoice():Bool {
		frame.restore();		
        var arity = stru.getArity();
        		
        for( i in index...arity ) {
            var arg = stru.argAt( i ).asValueTerm();
			
            if( arg.unify( value, engine ) ) {
                argRef.unify( new NumberTerm( i + 1 ), engine ); //assumption: is unbound ref
            
                //last choice ?
                if( i == arity - 1 ) popThisChoicePoint();
				else index = i + 1;				
				 
                return true;
            }
        }
        
        popThisChoicePoint();		
        return false;
    }
    
    override public function toString() {
        return "arg/3: " + frame;
    }
}

