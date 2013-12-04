package blub.prolog;

/**
 * Listener collection
 */
class Listeners<T> {
	var listeners:Array<T>;
	
	public function add( listener:T ) {
		listeners.push( listener );
	}

    public function remove( listener:T ) {
        listeners.remove( listener );
    }
	
	public function iterator():Iterator<T> {
		return listeners.iterator();
	}
	
	public function new() {
	    listeners = new Array<T>();
	}	
}

/** Listener on Database */
interface PredicateListener {
    public function predicateAdded    ( pred:Predicate ):Void;
    public function predicateAbolished( pred:Predicate ):Void;
}

/** Listener on Predicate */
interface AssertionListener {
    public function clauseAsserted( clause:Clause, atFront:Bool ):Void;
}

/** Listener on a Clause */
interface RetractionListener {
    public function clauseRetracted( clause:Clause ):Void; 
}