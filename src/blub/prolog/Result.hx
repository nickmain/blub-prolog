package blub.prolog;

import blub.prolog.terms.Term;

/**
 * A query result
 */
enum Result {
	failure;
	success;
	bindings(binds:Map<String,Term>);
}

@:expose
class ResultUtil {

    /** toString for a result */
    public static function toString( result:Result ):String {
        return switch( result ) {
            case failure: "false";
            case success: "true";
            case bindings(b): bindingsToString( b );
        }       
    }
    
    /** toString for a set of bindings */
    public static function bindingsToString( bindings:Map<String,Term> ):String {
        if( bindings == null ) return "{null}";
    
        var s = "{ ";
        
        var first:Bool = true;
        for( key in bindings.keys() ) {
            if( first ) first = false;
            else s += ", ";
            
            var t = bindings.get(key);
            s += key + "=" + (if( t != null ) t.toString() else "<null>");
        }
        
        s += " }";
        
        return s;           
    }
    
	/** Get bindings from a result - null if none or if failure */
	public static function getBindings( result:Result ):Map<String,Term> {
        return switch( result ) {
            case failure: null;
            case success: null;
            case bindings(b): b;
        }       	
	}
	
	/** Whether a result is a success or a solution with bindings */
	public static function isSuccess( result:Result ):Bool {
	    return switch( result ) {
            case failure: false;
            case success: true;
            case bindings(_): true;
        }		
	}
	
    /**
     * Compare two sets of results - return true if they have the same 
     * bindings (and no more or less than each other). 
     */
    public static function equals( r1:Result, r2:Result ):Bool {

        var binds1:Map<String,Term>;
		var binds2:Map<String,Term>;
        
		switch( r1 ) {
			case failure: switch( r2 ) {
				              case failure: return true;
							  default: return false;
			              }
			case success: switch( r2 ) {
                              case success: return true;
                              default: return false;
                          }
            case bindings(b1): switch( r2 ) {
                                   case bindings(b2): {
									   binds1 = b1;
									   binds2 = b2;
								   }
                                   default: return false;
                               }
		}

        return compareBindings( binds1, binds2 );		
	}
	
	/**
	 * Compare a result against a set of bindings
	 */
	public static function equalsBindings( result:Result, binds:Map<String,Term> ):Bool {
        switch( result ) {
            case failure: return false;
            case success: return false;
            case bindings(b1): return compareBindings( b1, binds ); 
        }		
		
		return false;
	}
	
	/**
     * Compare two sets of bindings 
     */
    public static function compareBindings( binds1:Map<String,Term>, binds2:Map<String,Term> ):Bool {
        for( key in binds2.keys() ) {
            var val = binds2.get(key);
            if( val == null ) return false;
            
            var bind = binds1.get(key);
            if( bind == null || ! bind.equals( val )) return false; 
        }

        for( key in binds1.keys() )
        {
            var bind = binds1.get(key);
            
            var val = binds2.get(key);
            if( val == null ) return false;
            
            if( ! bind.equals( val )) return false; 
        }

        return true;
    }
}