package blub.prolog.terms;

import blub.prolog.stopgap.parse.Parser;
import blub.prolog.stopgap.parse.Operators;
import blub.prolog.terms.Reference;

#if (flash11 || flash10)
typedef TermEnvironment = flash.Vector<Reference>;
#else
typedef TermEnvironment = Array<Reference>;
#end

/**
 * Implemented by all term types
 */
interface Term {
	
	/** get a string representation of the term */
	public function toString():String;

    /** compare terms */
    public function equals( other:Term ):Bool;

    /** Whether the term is ground (no Variables or References) */
    public function isGround():Bool;

    /** Whether the term has References (no Variables) */
    public function hasReferences():Bool;

    /** Whether the term has Variables (no References) */
    public function hasVariables():Bool;
	
	/**
     * Return a value term.
     * Variables return their corresponding Reference in the given environment.
     * Structures with Variables are copied and the vars are replaced with refs.
     */
    public function toValue( env:TermEnvironment ):ValueTerm;
	    
    /**
     * Whether the term is a Reference (optimization since Std.is is slow).
     * Chases references until an unbound one is found. 
     * @return null if not a reference or is reference (or ref chain) with
     *              a non-ref binding.
     */
    public function asReference():Reference;

    /**
     * Whether the term is a Reference (optimization since Std.is is slow).
     * Does not chase references and will return a ref that has a binding. 
     * @return null if not a reference
     */
    public function asUnchasedReference():Reference;
    
    /**
     * Whether the term is an atom (optimization since Std.is is slow)
     * @return null if not
     */
    public function asAtom():Atom;

    /**
     * Whether the term is a structure (optimization since Std.is is slow)
     * @return null if not
     */
    public function asStructure():Structure;

    /**
     * Whether the term is a number (optimization since Std.is is slow)
     * @return null if not
     */
    public function asNumber():NumberTerm;	
	
    /**
     * Whether the term is a value (optimization since Std.is is slow)
     * @return null if not
     */
	public function asValueTerm():ValueTerm;	

    /**
     * If this term is a comma-structure then break it down into elements,
     * otherwise just return the term as the single element
     */
    public function commaSeparated():Array<Term>;
	
	/**
	 * Whether this term (as an arg of a clause head) could possibly match the
	 * given argument.
	 * Assumes that the argument is dereferenced (if it is a ValRef then it is
	 * unbound).
	 */
	public function couldMatch( arg:ValueTerm ):Bool;
	
	/**
	 * Attempt to match this term against another, recursively.
	 * Any vars/refs in this term that match should be bound in the given
	 * environment and trail.
	 * Return true upon success.
	 */
	public function match( other:ValueTerm, env:TermEnvironment, trail:BindingTrail ):Bool;	
}

@:expose
class TermParse {	
	/**
     * Parse a single term from a string
     */
    public static function parse( s:String, ?context:AtomContext, ?operators:Operators ):Term {
		if( context == null ) context = AtomContext.GLOBALS;
		
        if( operators == null ) {
            operators = new Operators();
            operators.addStandardOps();
        }
        
        if( s.charAt( s.length - 1 ) != "." ) s += " ."; 
        
        var parser:Parser = new Parser( context, operators, s, "method=Term.parse()" );
        return parser.nextTerm();
    } 
}