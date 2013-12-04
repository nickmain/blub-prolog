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

/**
 * list_slice(+ListA, +ListB, -ListC) 
 * 
 * For use with DCGs - assumes that ListB is a pointer to an element in the
 * tail of ListA, returns ListC as a copy of ListA up to, but excluding, ListB.
 */
class ListSlice extends BuiltinPredicate {
	
    public function new() {
		super( "list_slice", 3 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var a = args[0].toValue(env);
        var b = args[1].toValue(env);
        var c = args[2].toValue(env);
	
		var listA = a.asStructure();
		var listB = b.asStructure();
		var listC = c.asReference();
		
		//A is empty list
		if( listA == null ) {
		    var emptyA = a.asAtom();
		    if( emptyA != null && emptyA == Structure.EMPTY_LIST ) {
				engine.unify( Structure.EMPTY_LIST, c );
				return;
			}		
		}

        //B is empty list
        if( listB == null ) {
            var emptyB = b.asAtom();
            if( emptyB != null && emptyB == Structure.EMPTY_LIST ) {
                engine.unify( a, c );
                return;
            }       
        }
		
        if( listA == null || listB == null || listC == null ) {
			engine.raiseException( new PrologException( Atom.unregisteredAtom( "list_slice/3 requires (In,In,Out)" ) , engine.context ));
			return;
		}

        var elems = new Array<Term>();
		for( s in listA.listStructureIterator() ) {
			if( s == listB ) break;
			elems.push( s.argAt(0) );
		}
		
		engine.unify( Structure.makeList(elems), listC );
	}
}
