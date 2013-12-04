package blub.prolog.terms;

import blub.prolog.terms.Term;
import blub.prolog.terms.Reference;
import blub.prolog.engine.QueryEngine;

/**
 * A number
 */
class NumberTerm implements ValueTerm {

    public var value(default,null):Float;

    public function new( value:Float ) {
       this.value = value;
    }

    public function asValueTerm():ValueTerm { return this; }
    public function asAtom() { return null; }
    public function asStructure() { return null; }
    public function asNumber() { return this; }
    public function asReference() { return null; }
	public function asUnchasedReference() { return null; }
	public function isGround():Bool { return true; }
    public function hasReferences():Bool { return false; }
    public function hasVariables():Bool { return false; }
    public function dereference():ValueTerm { return this; }
    public function toValue( env:TermEnvironment ):ValueTerm { return this; }
    public function commaSeparated() { return  [ cast this ]; }
		
    public function gatherReferences( ?refs:Array<Reference> ):Array<Reference> {
        if( refs != null ) return refs;
        return []; 
    }

    public function toString():String {
        return Std.string( value );
    }
	
    public function equals( other:Term ):Bool {
		var otherNum = other.asNumber();
		if( otherNum == null ) return false;
		
        return otherNum.value == value;
    }

    public function match( other:ValueTerm, env:TermEnvironment, trail:BindingTrail ):Bool {
		return equals(other.dereference());
	}

    /**
     * Whether this term (as an arg of a clause head) could possibly match the
     * given argument.
     * Assumes that the argument is dereferenced (if it is a ValRef then it is
     * unbound).
     */
    public function couldMatch( arg:ValueTerm ):Bool {
        if( arg.asReference() != null ) return true;        
        return equals( arg );
    }

    /**
     * Unify two terms.
     * 
     * @return true if success
     */
    public function unify( other:ValueTerm, trail:BindingTrail ):Bool {        
        if( other.asReference() != null ) return other.unify( this, trail );       
        
        return equals( other );                                   
    }

}
