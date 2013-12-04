package blub.prolog.builtins.objects;

import blub.prolog.terms.Atom;

/**
 * Listener on object property changes
 */
interface PropertyListener {
    
	/**
	 * A property changed
	 * 
	 * @param object the object in question
	 * @param atom the atom that holds the object
	 * @param name the prop name
	 * @param oldValue the previous value
	 * @param newValue the new value
	 */
	public function propertyChanged( object:ObjectWrapper, 
	                                 atom:Atom, 
									 name:String, 
									 oldValue:Dynamic, 
									 newValue:Dynamic ):Void;
}
