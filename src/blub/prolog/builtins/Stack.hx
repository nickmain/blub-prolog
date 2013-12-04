package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Reference;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.ChoicePoint;

/**
 * stack(-Head,-Tail).
 * 
 * Creates a stack that is returned as Head pointing at the start of the
 * list representing the stack, and Tail as a special variable that pushes
 * a term to the end of the list when bound and pops the last element when
 * unbound due to backtracking.
 * 
 * Unifying the tail var with another unbound var will always cause the other
 * var to bind with the tail and the other var will not be pushed onto the
 * stack - only non-ref terms will be pushed.
 * 
 * This means that the Tail variable will always appear to be unbound.
 */
class Stack extends BuiltinPredicate {
	
    public function new() {
		super( "stack", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env  = engine.environment; 
		var h    = args[0].toValue(env);
		var t    = args[1].toValue(env);  
        
		var headRef = h.asReference();
		var tailRef = t.asReference(); 
	  
	    if( headRef == null || tailRef == null ) {
			engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_variable, 
                                        if( headRef == null ) h else t, 
                                        engine.context ) );
            return; 
		}

 		var head = new StackHead();
		var tail = new StackTail( head );
		
		engine.unify( headRef, head );
		engine.unify( tailRef, tail );
	}
}

/**
 * Reference that will push and pop the stack
 */
private class StackTail extends Reference {
	
	var head:StackHead;
	
	public function new( head:StackHead ) { 
	   super();
	   this.head = head;
	}
	
	/**
     * Make binding - if term is a reference then bind that to this so that
     * this is always unbound.
     * If term is not a ref then push it onto stack and remain unbound - return
     * self so that engine backtracking will still call unbind() on this.
     */
    override public function bind( term:ValueTerm, ?allowRebinding:Bool = false ):Reference {
        
		var ref = term.asReference();
		if( ref != null ) {
			ref.reference = this;			
			return ref;
		}

        head.push( term );		        
        return this;
    }
	
	/**
     * Undo any binding directly on this reference
     */
    override public function unbind( oldValue:ValueTerm ) {
        head.pop();
    }
}

private class StackHead extends ClauseTermImpl {
	
	//reverse list of list elems to allow popping end of list
	var elems:List<Structure>;
	
	public function new() { 
		super( Structure.EMPTY_LIST );
		elems = new List<Structure>();
	}
	
	public function push( term:ValueTerm ) {
		
		var s = new Structure( Structure.CONS_LIST );
		s.addArg( term );
		s.addArg( Structure.EMPTY_LIST );
		s.forceHasRefs();
		
		if( elems.isEmpty() ) {
			payload = s;
		}
		else {
			//add the new elem to the previous struct
			elems.first().getArgs()[1] = s;
		}
		
		elems.push( s );
	}
	
	public function pop() {
		if( elems.isEmpty() ) return;
		
		elems.pop();
		
		//everything popped
		if( elems.isEmpty() ) {
			payload = Structure.EMPTY_LIST;
			return;
		}
		
		//remove popped elem from parent struct
        elems.first().getArgs()[1] = Structure.EMPTY_LIST; 
    }	
}