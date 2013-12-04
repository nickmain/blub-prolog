package blub.prolog.terms;

import blub.prolog.terms.Term;
import blub.prolog.terms.Variable;
import blub.prolog.engine.QueryEngine;

/**
 * Implemented by things that keep track of new bindings (to enable undo and
 * backtracking)
 */
interface BindingTrail {
    public function newBinding( ref:Reference, oldValue:ValueTerm ):Void;	
	public function bookmark():Dynamic;
	public function undo( bookmark:Dynamic ):Void;
}

/**
 * A reference to a term
 */
class Reference implements ValueTerm {

    static var nameGen:Int = 0;

    public var name (get_name,null):String;
    public var reference (default,null):ValueTerm;

    public function new( ?name:String ) {
        reference = null;
		_name = name;
    }
    function asAtom_nochase() { return if( reference == null ) null else reference.asAtom(); }
    function asStructure_nochase() { return if( reference == null ) null else reference.asStructure(); }
    function asNumber_nochase() { return if( reference == null ) null else reference.asNumber(); }
	function asReference_nochase() { return if( reference == null ) this else null; }   
	
    public function asValueTerm():ValueTerm { return this; }
    public function asAtom() { return chaseReferences().asAtom_nochase(); }
    public function asStructure() { return chaseReferences().asStructure_nochase(); }
    public function asNumber() { return chaseReferences().asNumber_nochase(); }   
    public function asReference() { return chaseReferences().asReference_nochase(); }
    public function asUnchasedReference() { return this; }		
    public function commaSeparated() { return if( reference != null ) reference.commaSeparated() else [ cast this ]; }
	
    public function gatherReferences( ?refs:Array<Reference> ):Array<Reference> {
		if( reference == null ) {
            if( refs == null ) return [this];
    		refs.push( this );
			return refs;
		}
		
		return reference.gatherReferences(refs);         
    }
	
	public function isGround():Bool { 
		var ref = chaseReferences();
		var val = ref.reference;
		if( val != null ) return val.isGround();
		return false; 
	}
	
    public function hasReferences():Bool { return true; }
    public function hasVariables():Bool { return false; }
    public function toValue( env:TermEnvironment ):ValueTerm { return this; }
	
    public function toString():String {
		var val = dereference();
		
		if( val == this ) return "_" + name;
		else return name + "=" + val.toString(); 
    }

    public function match( other:ValueTerm, env:TermEnvironment, trail:BindingTrail ):Bool {
        var val = dereference();
		if( val == this ) {
            if( trail != null ) trail.newBinding( this, reference );
			bind( other );
			return true;
		}
		else {
		  	return val.equals(other);
		}		
	}

	public function equals( other:Term ):Bool {
		if( this == other ) return true;
		
		var otherVal = other.asValueTerm();
		if( otherVal == null ) return false; //was a Variable
		
		otherVal = otherVal.dereference();
		var thisVal = dereference();
		
		var otherRef = otherVal.asReference();
		var thisRef  = thisVal.asReference();
		
		//two references are only equal if they are the same ref
		//(to conform to the spec for ISO ==/2 )
		if( otherRef != null && thisRef != null ) return otherRef == thisRef;
		if( otherRef != null || thisRef != null ) return false;
		
		return thisVal.equals( otherVal );
    }
	
	var _name:String;
	function get_name() {
		if( _name == null ) _name = "V_" + (nameGen++);
		return _name;
	}
	
	/**
     * Whether this term (as an arg of a clause head) could possibly match the
     * given argument.
     * Assumes that the argument is dereferenced (if it is a ValRef then it is
     * unbound).
     */
    public function couldMatch( arg:ValueTerm ):Bool {
        return false; //a clause head will not contain References
    }
	
	/**
     * Unify two terms.
     * 
     * @return true if success
     */ 
    public function unify( other:ValueTerm, trail:BindingTrail ):Bool {

        var here    = dereferenceReferences();
        var hereRef = here.asReference();        

        var thereRef = other.asReference(); 
        var there = if( thereRef != null ) thereRef.dereferenceReferences() 
		            else other; 		
		thereRef = there.asReference();		
						
		//two non-refs - let them take care of it
		if( (hereRef == null) && (thereRef == null) ) {
			return here.unify( there, trail );
		}
		
		//at least one is a ref
		var ref  :Reference;
		var value:ValueTerm;
		
		if( hereRef != null ) {
			ref   = hereRef;
			value = there;
		}
		else {
            ref   = thereRef;
            value = here;			
		}
				
        //save the undo info
        if( trail != null ) trail.newBinding(ref,ref.reference);
        
		//make the binding
		ref = ref.bind( value );
		
        return true;                                   
    }
		
	/**
	 * Bind the variable and return the actual ref that was bound
	 */
	public function bind( term:ValueTerm, ?allowRebinding:Bool = false ):Reference {
		
		var target = chaseReferences();
		if( target.reference != null && ! allowRebinding ) {
			throw "Cannot bind already bound var " + target.toString();
		}
		
		//don't create circular refs
		if( target == term ) return target;
		
		target.reference = term;
		
		return target;
	}
	
	/**
	 * Undo any binding directly on this reference
	 */
	public function unbind( oldValue:ValueTerm ) {
		reference = oldValue;
	}
	
	/**
	 * Rebind the last reference in the chain and optionally record the old
	 * value to allow backtracking.
	 */
	public function rebindLast( value:ValueTerm, ?trail:BindingTrail ) {
		var ref = chaseReferences();
		if( trail != null ) trail.newBinding( ref, ref.reference );
		
		ref.rebind( value );
	}
	
	/** Overridable */
	private function rebind( value:ValueTerm ) {
		reference = value;
	}
	
	/**
	 * Chase references to find the one at the end of the chain
	 */
	inline function chaseReferences():Reference {
		var ref = this;
		var val = reference;
		
		while( true ) {
		    if( val == null ) break;
			
			var nextRef = val.asUnchasedReference();
			if( nextRef != null ) {
				ref = nextRef;
				val = ref.reference;
			}
			else break;
		}		
		
		return ref;
	}
	
	/**
	 * Chase references and dereference any binding.
	 */
	public function dereference():ValueTerm {
		if( reference == null ) return this;
		return reference.dereference();
	}
	
	/**
     * Chase references and return the last one (if unbound) or its binding,
     * without dereferencing the bound term.
     */
    public function dereferenceReferences():ValueTerm {
		var ref = chaseReferences();		
        if( ref.reference == null ) return ref;		
        return ref.reference;
    }
	
}
