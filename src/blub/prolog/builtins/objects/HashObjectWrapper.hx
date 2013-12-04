package blub.prolog.builtins.objects;

import blub.prolog.terms.Atom;
import blub.prolog.builtins.objects.ObjectWrapper;

/**
 * An object wrapper around a Hash
 */
class HashObjectWrapper extends ObjectWrapperImpl<Map<String,Dynamic>> {

    public function new( atom:Atom, ?hash:Map<String,Dynamic> ) { 
        super( if( hash != null ) hash else new Map<String,Dynamic>(), atom ); 
    } 

    override public function getProperty( name:String ):Dynamic {
        return object.get( name );
	}

    override function set( name:String, value:Dynamic ):Void {
		object.set( name, value );
    }
	
	override public function callMethod( name:String, ?args:Array<Dynamic> ):Dynamic {
		var prop = getProperty( name );
		if( prop != null && Reflect.isFunction( prop ) ) {
			return Reflect.callMethod( object, prop, args );
		}
		
		return null;
	}
}
