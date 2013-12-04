package blub.prolog.builtins.lazy;

import blub.prolog.Database;
import blub.prolog.Predicate;

/**
 * Predicates (as source) that are lazily loaded. These are not considered
 * built-in and can be shadowed by user-supplied predicates.
 */
class LazyLoadPredicates {

    var database:Database;
    var preds:Map<String,String>; //functor->source

    public function new( database:Database ) {
		this.database = database;
		init();
	}

    /**
     * Attempt to load the given predicate - return true if successful
     */
    public function load( indicator:PredicateIndicator ):Bool {
		var functor = indicator.toString();
		var src = preds.get( functor );
		if( src == null ) return false;
		
		//trace( "lazy loading " + functor );
		database.addPredicateSrc( functor, src );
		return true;
	}
    
	private function init() {
	    preds = new Map<String,String>();	
		//preds.set( "member/2", "member(A,[A|_]). member(A,[_|B]):-member(A,B)." );
	
	    preds.set( "map/3", " map(Predicate,List,Result) :- Goal =.. [Predicate,In,Out], findall(Out,(member(In,List),Goal),Result)." );
		
		preds.set( "append/3", "append([], L, L). append([X|Ll], L2, [X|L3]) :- append(Ll, L2, L3)." );
		
		preds.set( "findall/3", 
                   "findall(Template,Goal,Results) :- query(Goal,Template,Q),findall_gather(Q,Results).");

        preds.set( "findall_gather/2",
		           "findall_gather(Q,R) :- solution( Q, S ) -> R = [S|T], findall_gather(Q,T) ; R=[]." );	
	}	
}
