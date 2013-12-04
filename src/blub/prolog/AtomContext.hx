package blub.prolog;

import blub.prolog.Predicate;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;

/**
 * A context for Atoms and other global things.
 * Maintains the mapping from atom text to atom id.
 */
class AtomContext {

    /** A context for creating global Atoms */
    public static var GLOBALS:AtomContext = new AtomContext();

	var atoms:Map<String,Atom>;
	
	public function new() {
		atoms = new Map<String,Atom>();
	}
	
	/**
	 * Look up an atom based on its unquoted text -
	 * return the cached one or create and cache a new one.
	 */
	public function getAtom( text:String ):Atom {
		var atom = lookupAtom( text );
				
		if( atom == null ) { 
			atom = createAtom( text );
			atoms.set( text, atom );
		}
		
		return atom;
	}
	
    /**
     * Look up an atom based on its unquoted text - null if not found
     */
	public function lookupAtom( text:String, ?checkGlobals:Bool = true ):Atom {
		var atom = atoms.get( text );

		if( atom == null && checkGlobals && this != GLOBALS ) {
			return GLOBALS.lookupAtom( text, false );
		}
		
		return atom;
    }
	
	private function createAtom( text:String ):Atom {
		return Atom.unregisteredAtom(text);
	}
}
