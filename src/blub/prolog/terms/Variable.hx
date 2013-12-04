package blub.prolog.terms;

import blub.prolog.terms.Term;
import blub.prolog.terms.Reference;

/**
 * A logic variable.
 * A Variable does not appear in a TermEnvironment but has an index into one.
 */
class Variable implements Term {
    static var nameCount = 0;

    /** The index of this var in the environment */
    public var index(default,null):Int;	
	
    var _name:String;
    public var name(get_name,null):String;

    public function new( ?name:String ) {
       _name = name;
	   index = -1;
    }

    public function asValueTerm():ValueTerm { return null; }
    public function asAtom() { return null; }
    public function asStructure() { return null; }
    public function asNumber() { return null; }
    public function asReference() { return null; }
	public function asUnchasedReference() { return null; }
    public function isGround():Bool { return false; }
    public function hasReferences():Bool { return false; }
    public function hasVariables():Bool { return true; }
    public function toValue( env:TermEnvironment ):ValueTerm {
		if( index < 0 ) return new Reference(); 
		return env[ index ]; 
	}
	
    public function commaSeparated() { return  [ cast this ]; }	
	
    public function equals( other:Term ):Bool {
		return this == other;
	}
	
    public function match( other:ValueTerm, env:TermEnvironment, trail:BindingTrail ):Bool {
		if( env == null || name == "_" ) return true;
		if( index >= env.length ) return false;
		
		var ref = env[index];
		return ref.match(other, env, trail);		
	}
	
	/**
     * Whether this term (as an arg of a clause head) could possibly match the
     * given argument.
     * Assumes that the argument is dereferenced (if it is a ValRef then it is
     * unbound).
     */
    public function couldMatch( arg:ValueTerm ):Bool {        
        return true;  //naked variable can match anything
    }
	
	/** Initialize the environment index */
	public function initIndex( index:Int ) {
		if( this.index != -1 ) {			
			throw "Cannot set var index more than once - " + _name + " was " + this.index + ", setting to " + index;
		}
		this.index = index;
	}
	
    public function toString():String { return name; }
	
	function get_name() { 
	    if( _name == null ) _name = "_G" + (nameCount++);
        return _name; 	
	}
}
