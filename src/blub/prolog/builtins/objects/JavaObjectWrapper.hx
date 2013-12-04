package blub.prolog.builtins.objects;

import blub.prolog.terms.Atom;
import blub.prolog.builtins.objects.ObjectWrapper;

/**
 * Wrapper around a Java object
 */
class JavaObjectWrapper extends ObjectWrapperImpl<Dynamic> {

    public function new( object:Dynamic, atom:Atom ) { 
        super( object, atom ); 
    } 
}
