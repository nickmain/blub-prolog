package blub.prolog.terms;

import blub.prolog.terms.Term;
import blub.prolog.terms.Reference;
import blub.prolog.AtomContext;
import blub.prolog.Predicate;

import blub.prolog.engine.QueryEngine;
import blub.prolog.stopgap.parse.Char;

/**
 * An atom
 */
class Atom implements ClauseTerm
           implements ListTerm {
    
	private static var ID_GEN = 0;
	
	/** Optional object associated with the atom */
	public var object:Dynamic;

	public var text(default,null):String;     

    /** Atoms can only be created via a Context */
    private function new( text:String ) {
	    this.text = text;
	}

    /** Create a new unique atom */
    public static function newUniqueAtom( prefix:String ) {
		return new Atom( prefix + (ID_GEN++) );
	}

    /** Create an atom that is not registered in any Context */
    public static function unregisteredAtom( text:String ) {
		return new Atom( text );
	}
	
	public function getIndicator() { return new PredicateIndicator(this,0); }
	public function getHead():ClauseTerm { return this; } 
    public function getBody():ClauseTerm { return null; }
    public function getFunctor() { return text + "/0"; }
    public function getArgs() { return []; }
    public function getNameText() { return text; }	
	
	public function toString():String { return escape(text); }	

    public function asValueTerm():ValueTerm { return this; }
    public function asAtom() { return this; }
    public function asStructure() { return null; }
    public function asNumber() { return null; }
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

    public function match( other:ValueTerm, env:TermEnvironment, trail:BindingTrail ):Bool {
		return equals(other.dereference());
	}

    public function equals( other:Term ):Bool {
		if( other == null ) return false;
        var otherAtom = other.asAtom();
        if( otherAtom == null ) return false;            
        
		//direct comparison
		if( this == otherAtom ) return true;

        //object-based comparison
        if( object != null && otherAtom.object != null ) {
			return object == otherAtom.object;
		}

        //text-based comparison
        return ( text == otherAtom.text );
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

    /** Whether this atom is the empty list */
    public function isList():Bool {
		return this == Structure.EMPTY_LIST;
	}

    /**
     * ListTerm interface
     */
    public function listToArray():Array<Term> {
		if( isList() ) return [];
		return null;
	}

    /**
     * Unquote an atom string
     * @return null if the text was not quoted
     */
    public static function unquote( text:String ):String {
        if( StringTools.startsWith( text, "'" )
         && StringTools.endsWith( text, "'" )) {
            return text.substr( 1, text.length - 2 );
        }
        
        return null;
    }
	
	/**
	 * Simple escaping of atom text
	 */
    public static function escape( s:String ) {
		if( s == null ) return null;
        if( s.length == 0 ) return "''";
		if( s == "{}" || s == "[]" ) return s;
        
        var b = new StringBuf();
        var needsEscape = false;

        //must start with lowercase or an op-char
        var code = s.charCodeAt(0);
		var char = s.charAt(0);
        if( (code >= a_CODE && code <= z_CODE) || Char.isOpChar_( char ) ) {
            needsEscape = false;
        }
		else {
            needsEscape = true;
		}

        for( i in 0...s.length ) {
            
            //alphanumerics
            code = s.charCodeAt(i);
            if( code == under_CODE
             ||(code >= A_CODE && code <= Z_CODE)
             ||(code >= a_CODE && code <= z_CODE)
             ||(code >= zero_CODE && code <= nine_CODE)) {
                b.addChar( code );
                continue;
            }

            char = s.charAt( i );
            if( Char.isOpChar_( char ) ) {
				b.add( char );
				continue;
			}
			
            needsEscape = true;
            b.add( switch( char ) {
                case "\n": " ";
                case "\r": " ";
                case "\t": " ";
                case "\\": "\\\\";
                case "'" : "''";               
                default: char;     
            });
        }
        
        return if( needsEscape ) ("'" + b + "'") else s;
    }
    
    private static var A_CODE = "A".charCodeAt(0);
    private static var Z_CODE = "Z".charCodeAt(0);
    private static var a_CODE = "a".charCodeAt(0);
    private static var z_CODE = "z".charCodeAt(0);
    private static var zero_CODE = "0".charCodeAt(0);
    private static var nine_CODE = "9".charCodeAt(0);
    private static var under_CODE = "_".charCodeAt(0);	
}
