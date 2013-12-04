package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Reference;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.ChoicePoint;

/**
 * Variable rebinding operators
 */
class RebindVar extends BuiltinPredicate {
    public static function get():Array<BuiltinPredicate> {
        return cast [ 
            new NonBacktrackingRebindVar(),         
            new BacktrackingRebindVar(),
			new NonBacktrackingArithmeticRebind(),
			new BacktrackingArithmeticRebind()
        ];
    }
   
    public function new( name:String ) {
        super( name, 2 );
    }
    
    override function execute( engine:QueryEngine, args:Array<Term> ) {
        var env = engine.environment; 
        var ref = args[0].toValue(env);
        var val = args[1].toValue(env).dereference();  
        
        var targetRef = ref.asUnchasedReference(); 
      
        if( targetRef == null ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_variable, 
                                        ref, 
                                        engine.context ) );
            return; 
        }

        bind( targetRef, val, engine );
    }
	
	function bind( targetRef:Reference, value:ValueTerm, engine:QueryEngine ) {
		targetRef.rebindLast( value );
	}
}

/**
 * Var <= Value.
 * 
 * Bind a variable even if it is already bound - the old value is not restored
 * upon backtracking. (Not that if the var was previously bound via unfication
 * or the <+ operator then backtracking will still undo those bindings).
 * 
 * If the variable is bound to a reference then that reference is bound
 * instead (recursively until the final ref in the chain is found).
 */
class NonBacktrackingRebindVar extends RebindVar {    
    public function new() { super( "<=" ); }
}

/**
 * Var <=& Value.
 * 
 * Bind a variable even if it is already bound - the old value is restored
 * upon backtracking.
 * 
 * If the variable is bound to a reference then that reference is bound
 * instead (recursively until the final ref in the chain is found).
 */
class BacktrackingRebindVar extends RebindVar {
	
    public function new() { super( "<=&" ); }
	
    override function bind( targetRef:Reference, value:ValueTerm, engine:QueryEngine ) {
        targetRef.rebindLast( value, engine );
	}
}

class ArithmeticRebind extends RebindVar {
	public function new( name:String ) { super( name );}
	
	override function bind( targetRef:Reference, value:ValueTerm, engine:QueryEngine ) {
		var num = value.asNumber();
		if( num == null ) num = new NumberTerm( engine.arithmetic.evaluate( value ));
		
        bindNum( targetRef, num, engine );
    }

    function bindNum( targetRef:Reference, value:NumberTerm, engine:QueryEngine ) {
        targetRef.rebindLast( value );
    }	
}

/** Rebind that evaluates the RHS */
class NonBacktrackingArithmeticRebind extends ArithmeticRebind {    
    public function new() { super( "<#" ); }
}

/** Backtracking rebind that evaluates the RHS */
class BacktrackingArithmeticRebind extends ArithmeticRebind {    
    public function new() { super( "<#&" ); }
	
	override function bindNum( targetRef:Reference, value:NumberTerm, engine:QueryEngine ) {
        targetRef.rebindLast( value, engine );
    }   	
}
