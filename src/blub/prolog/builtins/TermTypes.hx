package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.engine.QueryEngine;

import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Variable;

/**
 * Term type predicates
 */
class TermTypes extends BuiltinPredicate {

    public static function get():Array<BuiltinPredicate> {
        return cast [ 
            new TermTypes( "var"      , function(t){ return t.asReference() != null; }),
            new TermTypes( "nonvar"   , function(t){ return t.asReference() == null; }),
            new TermTypes( "number"   , function(t){ return t.asNumber() != null; }),
            new TermTypes( "atom"     , function(t){ return t.asAtom() != null; }),
            new TermTypes( "atomic"   , function(t){ return t.asAtom() != null || t.asNumber() != null; }),
            new TermTypes( "compound" , function(t){ return t.asStructure() != null; }),
            new TermTypes( "callable" , function(t){ return t.asAtom() != null || t.asStructure() != null; }),
            new TermTypes( "ground"   , function(t){ return t.isGround(); }),
			
			new TermTypes( "integer"  , function(t){
				var num = t.asNumber();
				if( num == null ) return false; 
				return Std.is( num.value, Int ); 
		    }),

            new TermTypes( "is_list"  , function(t){
				var empty = t.asAtom();
				if( empty != null ) return empty.isList();
				
                var str = t.asStructure();
                if( str == null ) return false;
				return str.isList();
            }),
			
            new TermTypes( "float"    , function(t){
                var num = t.asNumber();
                if( num == null ) return false; 
                return ! Std.is( num.value, Int ); 
            })			
        ];
    }

    var fn:ValueTerm->Bool;

    function new( functor:String, fn:ValueTerm->Bool ) {
        super( functor, 1 );
        this.fn = fn;
    }
    
    override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
        var term = args[0].toValue(env).dereference();
                
        if( ! fn( term )) engine.fail();
    }
}

