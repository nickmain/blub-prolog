package blub.prolog.builtins.objects;

import blub.prolog.terms.Atom;
import blub.prolog.builtins.objects.ObjectWrapper;

/**
 * Wrapper around a Flash object
 */
class FlashObjectWrapper extends ObjectWrapperImpl<Dynamic> {

    public function new( object:Dynamic, atom:Atom ) { 
        super( object, atom ); 
    } 
}
