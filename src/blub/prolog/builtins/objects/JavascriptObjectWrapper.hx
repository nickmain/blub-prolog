package blub.prolog.builtins.objects;

import blub.prolog.terms.Atom;
import blub.prolog.builtins.objects.ObjectWrapper;

/**
 * Wrapper around a JS object - extra handling for props that use getter/setter
 * functions, especially with respect to Jeash
 */
class JavascriptObjectWrapper extends ObjectWrapperImpl<Dynamic> {

    public function new( object:Dynamic, atom:Atom ) { 
        super( object, atom ); 
    } 

    /** Get a property */
    override public function getProperty( name:String ):Dynamic {
        //--Jeash props are getters/setters
        var getterName = "jeashGet" + ObjectWrapperImpl.capitalize( name );
        var getter = untyped object[getterName];
        if( getter != null ) {			
            return untyped getter.call(object);                
        }

        return super.getProperty( name );
	}

    override function set( name:String, value:Dynamic ):Void {
        //--Jeash props are getters/setters
        var setterName = "jeashSet" + ObjectWrapperImpl.capitalize( name );
        var setter = untyped object[setterName];
		
        if( setter != null ) {
            untyped setter.call( object, value );
			return;             
        }
		
		super.setProperty_final( name, value );
    }
}
