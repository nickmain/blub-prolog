package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.engine.QueryEngine;

import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Term;
import blub.prolog.terms.Variable;

/**
 * Base for binary arithmetic predicates
 */
class BinaryArithmeticPred extends BuiltinPredicate {

    public static function get():Array<BuiltinPredicate> {
        return cast [ 
            new BinaryArithmeticPred("=:=" ,function(a,b){ return a == b; }),
            new BinaryArithmeticPred("=\\=",function(a,b){ return a != b; }),
            new BinaryArithmeticPred(">"   ,function(a,b){ return a >  b; }),
            new BinaryArithmeticPred("<"   ,function(a,b){ return a <  b; }),
            new BinaryArithmeticPred(">="  ,function(a,b){ return a >= b; }),
            new BinaryArithmeticPred("=<"  ,function(a,b){ return a <= b; })
        ];
    }

    var fn:Float->Float->Bool;

    function new( functor:String, fn:Float->Float->Bool ) {
        super( functor, 2 );
        this.fn = fn;
    }
    
    override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
        var a = args[0].toValue(env); //.dereference();
        var b = args[1].toValue(env); //.dereference();
        
        var numA = a.asNumber();
        var numB = b.asNumber();

        var valA = if( numA == null ) engine.arithmetic.evaluate( a ) else numA.value;
        var valB = if( numB == null ) engine.arithmetic.evaluate( b ) else numB.value;
        
        if( ! fn( valA, valB )) engine.fail();
		//else continue
    }
}

