package blub.prolog.terms;

import blub.prolog.terms.Term;
import blub.prolog.terms.Reference;
import blub.prolog.engine.QueryEngine;

/**
 * Terms that can be part of an evaluation environment - essentially all terms
 * other than Variables
 */
interface ValueTerm extends Term {
	
    /**
     * Unify two terms.
     * 
     * @return true if success
     */
    public function unify( other:ValueTerm, trail:BindingTrail ):Bool;

    /**
     * Dereference this term as much as possible - chase any References until
     * unbound vars or ground terms are found. The result will either be this
     * same term unmodified or a copy with the dereferenced sub-terms.
     */
    public function dereference():ValueTerm;
	
	/**
	 * Gather all the references in the term and return the resulting array.
	 * Do not dereference references.
	 * Empty array if none.
	 * If array argument is given then use that and return it. 
	 */
	public function gatherReferences( ?refs:Array<Reference> ):Array<Reference>;
}

/**
 * Base implementation of a value term
 */
class ValueTermImpl implements ValueTerm {

    function new() {}

    public function toValue( env:TermEnvironment ):ValueTerm { return this; }
    public function equals( other:Term ) { return this == other; }
    public function toString()      { return "<ValueTermImpl>"; }
    public function isGround()      { return true; }
    public function hasReferences() { return false; }
    public function hasVariables()  { return false; }
    public function asReference()   { return null; }
    public function asUnchasedReference() { return null; }
    public function asAtom()              { return null; }
    public function asStructure()         { return null; }
    public function asNumber()            { return null; }  
    public function couldMatch( arg:ValueTerm )  { return false; }
    public function commaSeparated() { return  [ cast this ]; }	
	
    public function unify( other:ValueTerm, trail:BindingTrail ) { return false; }
	public function match( other:ValueTerm, env:TermEnvironment, trail:BindingTrail ) { return false; }
    public function dereference():ValueTerm  { return this; }
    public function asValueTerm():ValueTerm  { return this; }
	public function gatherReferences( ?refs:Array<Reference> ):Array<Reference> { return []; }	
}