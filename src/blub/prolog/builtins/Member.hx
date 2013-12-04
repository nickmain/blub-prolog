package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Reference;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.ChoicePoint;
import blub.prolog.engine.parts.CodeFrame;

/**
 * member(?Elem, ?List) - Whether Elem is a member of List, or when Elem is
 * unbound, provide a choicepoint that returns each member of the list.
 * 
 * Definition:
 *   member(A,[A|_]).
 *   member(A,[_|B]):-member(A,B).
 */
class Member extends BuiltinPredicate {
	
    public function new() {
		super( "member", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var elem = args[0].toValue(env);
        var list = args[1].toValue(env);
	
		var cp = new MemberChoicePoint( engine, new CodeFrame( engine ), elem, list );
		engine.processBuiltinChoices();
	}
}

/**
 * Choice point for member clauses 
 */
class MemberChoicePoint extends ChoicePoint { 
	
	private var clause:Int;
    private var arg1:ValueTerm;
	private var arg2:ValueTerm;
		
    public function new( eng:QueryEngine, frame:CodeFrame, arg1:ValueTerm, arg2:ValueTerm ) {
        super( eng, frame );		
		this.arg1 = arg1;
		this.arg2 = arg2;
		
		clause = 0;
    }
    
	/**
	 * member(A,[A|_]).
	 */
	private function clause1() {
		var param2 = new Structure( Structure.CONS_LIST ); //[A|_]
		param2.addArg(arg1);
		param2.addArg(new Reference());
		
		var result = param2.unify( arg2, engine );
		return result;
	}
	
	/**
	 * member(A,[_|B]):-member(A,B).
	 */
	private function clause2() {	
        var refB   = new Reference(); //B
        var param2 = new Structure( Structure.CONS_LIST ); //[_|B]
        param2.addArg(new Reference());
        param2.addArg(refB);
        
        var result = param2.unify( arg2, engine );

		//push a new choice-point representing the recursive call
		if( result ) new MemberChoicePoint( engine, frame, arg1, refB );
	}
	
    override public function nextChoice():Bool {
		clause++;
		
        switch( clause ) {
            case 1: if( clause1() ) { frame.restore(); return true; } else return false;
			case 2: { clause2(); return false; }  //false causes recursive choice-point to be tried
			default: { popThisChoicePoint(); return false; }
		}
    }
    
    override public function toString() {
        return "member/2 [" + (clause+1) + "] (" + arg1 + "," + arg2 + ")";
    }
}

