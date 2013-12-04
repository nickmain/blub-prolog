package blub.prolog.terms;

import blub.prolog.terms.ValueTerm;
import blub.prolog.AtomContext;
import blub.prolog.Predicate;
import blub.prolog.engine.QueryEngine;
import blub.prolog.terms.Reference;

/**
 * A term that can form the head or body of a clause
 */
interface ClauseTerm extends ValueTerm {
    
	/**
	 * Get the indicator for the clause
	 */
	public function getIndicator():PredicateIndicator;
	
	/**
	 * If this is a rule (Head :- Body) then return the head term otherwise
	 * return self.
	 */
	public function getHead():ClauseTerm;

    /**
     * If this is a rule (Head :- Body) then return the body term otherwise
     * return null.
     */
    public function getBody():ClauseTerm;	
	
    /** Get the name */
    public function getNameText():String;
    
    /** Get the functor of the form name/arity */
    public function getFunctor():String;
    
    /** Get the args of the constraint */
    public function getArgs():Array<Term>;	
}

/**
 * Base impl for custom clause terms that can be atoms or structures and may
 * switch between them during the term's lifetime
 */
class ClauseTermImpl extends ValueTermImpl implements ClauseTerm {
	
	private var payload:ClauseTerm;
	
	function new( payload:ClauseTerm ) {
	    super();
		this.payload = payload;
	}
	
	public function getIndicator() { return payload.getIndicator(); }
    public function getHead()      { return payload.getHead(); }
    public function getBody()      { return payload.getBody(); }	
    public function getFunctor()   { return payload.getFunctor(); }
	public function getArgs()      { return payload.getArgs(); }
    public function getNameText()  { return payload.getNameText(); }
	
    override public function equals( other:Term ) { return payload.equals( other ); }
    override public function toString()      { return payload.toString(); }
    override public function isGround()      { return payload.isGround(); }
    override public function hasReferences() { return payload.hasReferences(); }
    override public function hasVariables()  { return payload.hasVariables(); }
    override public function asAtom()              { return payload.asAtom(); }
    override public function asStructure()         { return payload.asStructure(); }
    override public function couldMatch( arg:ValueTerm )  { return payload.couldMatch( arg ); }
    
    override public function unify( other:ValueTerm, trail:BindingTrail ) { return payload.unify( other, trail ); }
    override public function dereference():ValueTerm  { return payload.dereference(); }
}