package blub.prolog.engine;

import blub.prolog.PrologException;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;

/**
 * Evaluates arithmetic structures
 */
class ArithmeticEvaluator {
    
    private static var arithmeticFuncs:Map<String,Bool> = {
        var h = new Map<String,Bool>();
        h.set( "+/2", true );
        h.set( "-/2", true );  
        h.set( "*/2", true ); 
        h.set( "//2", true );
        h;
    };
    
	var engine:QueryEngine;
	
    public function new( engine:QueryEngine ) {
        this.engine = engine;
    }

    /**
     * Whether the given structure is potentially an arithmetic function
     */
    public static function isArithmetic( struct:Structure ):Bool {
        return arithmeticFuncs.get( struct.getIndicator().toString() ) == true;
    }

    /**
     * Whether the given term is potentially an arithmetic function or number
     */
    public static function isEvaluable( t:Term ):Bool {
		if( t.asNumber() != null ) return true;
		var s = t.asStructure();
		if( s == null ) return false;		
        return isArithmetic(s);
    }
    
	/**
	 * Evaluate an expression - blow up if not evaluable
	 */
    public function evaluate( expression:Term ):Float {
		var numTerm = expression.asNumber();
		if( numTerm != null ) return numTerm.value;

        var stru = expression.asStructure();
		if( stru != null ) return evalFunc( stru );
        
        engine.raiseException( 
            RuntimeError.typeError( 
                TypeError.VALID_TYPE_evaluable, expression, engine.context ) );
		return 0.0;
    }
    
    /**
     * Evaluate a structure - blow up if not evaluable
     */
    public function evalFunc( funcExpression:Structure ):Float {
        switch( funcExpression.getIndicator().toString() ) {
            case "+/2": return evaluate( funcExpression.argAt(0) ) +
                               evaluate( funcExpression.argAt(1) );
                
            case "-/2": return evaluate( funcExpression.argAt(0) ) -
                               evaluate( funcExpression.argAt(1) );
                
            case "*/2": return evaluate( funcExpression.argAt(0) ) *
                               evaluate( funcExpression.argAt(1) );
                
            case "//2": return evaluate( funcExpression.argAt(0) ) /
                               evaluate( funcExpression.argAt(1) );
                
			case "./2": {
				var val = blub.prolog.builtins.objects.DotAccessor.evalDot(engine, funcExpression.argAt(0), funcExpression.argAt(1) );
				if( Std.is( val, Float ) ) {
					var flt:Float = cast val;
					return flt; 	
				}
			}
				
            default:
        }           
        
        engine.raiseException( 
            RuntimeError.typeError( 
                TypeError.VALID_TYPE_evaluable, funcExpression, engine.context ) );
        return 0.0;
    }
    
	/** Whether all args of the structure are numbers */
	public static function hasAllNumericArgs( s:Structure ) {
		for( a in s.getArgs() ) if( a.asNumber() == null ) return false;		
		return true;
	}
}