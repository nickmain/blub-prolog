package blub.prolog.builtins.objects;

import blub.prolog.Marshal;
import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Reference;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.ArithmeticEvaluator;
import blub.prolog.builtins.BuiltinPredicate;

/**
 * A.B - A must be an atom holding a reference to a native object, B is either
 * an atom representing a field on that object or a structure representing
 * a method call. The field is accessed or the method is called.
 * 
 * DotAccessor arguments in the structure are evaluated.
 */
class DotAccessor extends BuiltinPredicate {
    
    public function new() { super( ".", 2 ); }

    override function execute( engine:QueryEngine, args:Array<Term> ) {
        var env = engine.environment;
        var a = args[0].toValue(env).dereference();
        var b = args[1].toValue(env).dereference();
                
        evalDot( engine, a, b );
    }   
	
	/** Evaluate a dot pair */
	public static function evalDot( engine:QueryEngine, termA:Term, termB:Term ):Dynamic {
		var stru = termA.asStructure();
        if( stru != null && stru.getName().text == "." && stru.getArity() == 2 ) {
            termA = Marshal.valueToTerm( evalDot( engine, stru.argAt(0), stru.argAt(1) ));
        }		
		
        var atom = termA.asAtom();
        if( atom == null ) {
            throw "is not an atom: " + termA + " in " + termA + "." + termB;
        }

        //default atom payload to a Hash
        if( atom.object == null ) atom.object = new HashObjectWrapper( atom );

        if( ! Std.is( atom.object, ObjectWrapper) ) {
            throw "is not an atom wrapping a native object: " + termA + " in " + termA + "." + termB;
        }

        var wrapper:ObjectWrapper = cast atom.object;

        //field access
        var nameAtom = termB.asAtom();
        if( nameAtom != null ) {			
			var name = nameAtom.text;
            return wrapper.getProperty( name ); 
        }
        
        //method call
        var method = termB.asStructure();
        if( method != null ) {
            var args = makeArgs( engine, method.getArgs() );
			return wrapper.callMethod( method.getName().text, args );
        }

        throw "is not a field name or method call: " + termB + " in " + termA + "." + termB;
	}
	
	/** Evaluate an access expression */
	public static function eval( engine:QueryEngine, expr:ValueTerm ):Dynamic {

		//dot or constructor
		var stru = expr.asStructure();
        if( stru != null ) {
			
			//term escape
			if( stru.getArity() == 1 && stru.getNameText() == "term" ) {
                return stru.argAt(0);
            }
			
			if( ArithmeticEvaluator.isArithmetic( stru )) {
				return engine.arithmetic.evalFunc( stru );
			}
			
			if( stru.getName().text == "." && stru.getArity() == 2 ) {
				return evalDot( engine, stru.argAt(0), stru.argAt(1) );
            }
            else { //constructor call
                var className = stru.getName().text;
                var clazz = Type.resolveClass( className );
				if( clazz == null ) throw "Could not find class " + className;
				
				var args = makeArgs( engine, stru.getArgs() );
                return Type.createInstance( clazz, args );
            }
        }		
        
		//some other term
        return Marshal.termToValue( expr );
	}
	
	static function makeArgs( engine:QueryEngine, terms:Array<Term> ):Array<Dynamic> {
		var args = new Array<Dynamic>();
		
		//detect a void arg list
		if( terms.length == 1 ) {
			var arg1 = terms[0].asAtom();
			if( arg1 != null && arg1.text == "void" ) return args;
		}
				
		for( t in terms ) args.push( eval( engine, t.asValueTerm() ) );		
		return args;
	}
}
