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
import blub.prolog.builtins.BuiltinPredicate;

/**
 * A <- B
 * 
 * A is either a free variable or a DotAccessor pair referencing a field
 * on an object. The variable or the field receives the evaluation of B.
 * 
 * B is a DotAccessor pair or a structure representing a constructor call.
 * The constructor is called and the new object is assigned to A.
 * If a DotAccessor pair then evaluation is as for DotAccessor and the result
 * is assigned to A.
 * 
 * B could also be another term - converted to a value via Marshal.
 */
class ArrowAssigner extends BuiltinPredicate {
    
    public function new() { super( "<-", 2 ); }

    override function execute( engine:QueryEngine, args:Array<Term> ) {  
        var env = engine.environment;
        var a = args[0].toValue(env).dereference();
        var b = args[1].toValue(env).dereference();
        
        var value = null;
        try {
            value = DotAccessor.eval( engine, b );
        }
        catch( e:Dynamic ) {
            engine.raiseException( new PrologException( Atom.unregisteredAtom(  Std.string(e)), engine.context ));
            return;
        }
        
        //target is a free ref
        if( a.asReference() != null ) {
            var valTerm = Marshal.valueToTerm( value );
            engine.unify( a, valTerm );
            return;
        }
        
        var target = a.asStructure();
        if( target == null || target.getName().text != "." || target.getArity() != 2 ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "target of <- must be a var or dot-accessor: " + a.toString()), 
                    engine.context ));
            return;
        }
        
		var atom = null;
		
		//if the LHS of dot is a var then make a new atom and unify
		var lhsRef = target.argAt(0).asReference();
		if( lhsRef != null ) {
			atom = Marshal.newAtom();
			engine.unify( lhsRef, atom );			
		}
		else {
            atom = target.argAt(0).asAtom();
		}
		
        if( atom == null ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "is not an atom: " + target.argAt(0) + " in " + target.toString()), 
                    engine.context ));
            return;
        }

        //default atom payload to a Hash
        if( atom.object == null ) atom.object = new HashObjectWrapper( atom ); 

        if( ! Std.is( atom.object, ObjectWrapper )) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "is not an atom wrapping a native object: " + atom + " in " + target.toString()), 
                    engine.context ));
            return;
        }
        
        var nameAtom = target.argAt(1).asAtom();
        if( nameAtom == null ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "is not an atom representing a field name: " + target.argAt(1) + " in " + target.toString()), 
                    engine.context ));
            return;
        }

        var name = nameAtom.text;
        var wrapper:ObjectWrapper = cast atom.object;
		        
        //make the assignment and let any resulting exception raise itself
        wrapper.setProperty( name, value );
    }   
}