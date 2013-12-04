package blub.prolog.builtins.objects;

import blub.prolog.terms.Atom;
import blub.prolog.util.DLList;

/**
 * A wrapper around an object
 */
interface ObjectWrapper {

    /** Get a property */
    public function getProperty( name:String ):Dynamic;

    /** Set a property */
    public function setProperty( name:String, value:Dynamic ):Void;

    /** Call a method */
    public function callMethod( name:String, ?args:Array<Dynamic> ):Dynamic;
	
	/** Access the underlying object - may be null */
	public function getObject():Dynamic;
	
	/** Register a property listener - return the token that can be used to remove it */
	public function addPropListener( listener:PropertyListener ):Dynamic;
	
	/** Unregister a property listener using the token returned from addPropListener */
	public function removePropListener( token:Dynamic ):Void;
}

/**
 * A base implementation of ObjectWrapper
 */
class ObjectWrapperImpl<T> implements ObjectWrapper {
	
	var atom:Atom;
	var object:T;
	var listeners:DLList<PropertyListener>;
	
	function new( object:T, atom:Atom ) { 
		this.object = object;
		this.atom   = atom; 
    } 
	
	/** Get a property */
    public function getProperty( name:String ):Dynamic {
		return Reflect.field( object, name );
	}

    /** Set a property */
    function setProperty_final( name:String, value:Dynamic ):Void {
        var oldValue =
            if( listeners != null && listeners.size > 0 ) 
                getProperty( name )
                else null;
        
        Reflect.setField( object, name, value );
        
        if( listeners != null ) {
            for( listener in listeners ) {
                listener.propertyChanged( this, atom, name, oldValue, value );
            }
        }
    }

    /** Set a property */
    public function setProperty( name:String, value:Dynamic ):Void {
		var oldValue =
            if( listeners != null && listeners.size > 0 ) 
                getProperty( name )
				else null;
		
		set( name, value );
		
		if( listeners != null ) {
			for( listener in listeners ) {
				listener.propertyChanged( this, atom, name, oldValue, value );
			}
		}
	}

    /**override*/ function set( name:String, value:Dynamic ):Void {
		Reflect.setField( object, name, value );
	}

    /** Call a method */
    public function callMethod( name:String, ?args:Array<Dynamic> ):Dynamic {
		if( args == null ) args = [];
		
        return Reflect.callMethod( object, 
                                   Reflect.field( object, name ),
                                   args );
	}
    
    /** Access the underlying object - may be null */
    public function getObject():Dynamic { return object; }
    
    /** Register a property listener - return the token that can be used to remove it */
    public function addPropListener( listener:PropertyListener ):Dynamic {
		if( listeners == null ) listeners = new DLList<PropertyListener>();
		
		return listeners.append( listener );
	}
    
    /** Unregister a property listener using the token returned from addPropListener */
    public function removePropListener( token:Dynamic ):Void {
		if( token == null ) return;
		if( ! Std.is( token, Entry )) return;
		
		var entry:Entry<PropertyListener> = cast token;
		entry.remove();
	}
	
	public static function capitalize( name:String ):String {
        if( name.length < 2 ) return name.toUpperCase();
        
        return name.substr( 0, 1 ).toUpperCase() + name.substr( 1 );
    }
}