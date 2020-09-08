package blub.prolog;

import haxe.ds.StringMap;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.ValueTerm;
import blub.prolog.builtins.objects.ObjectWrapper;

/**
 * Utils to marshal between terms and native values
 */
class Marshal {

    private static var object_atom_id = 0;

    /**
     * Make a new unregistered atom
     */
    public static function newAtom():Atom {
		return Atom.unregisteredAtom("object#" + (object_atom_id++) );
	}

    /**
     * Convert a value to a term.
     * 
     * ValueTerm returned as-is.
     * Bool to 'true' and 'false' atoms.
     * null to 'null' atom.
     * Number to NumberTerm.
     * Array to List (recursive).
     * String to atom with text of the string (and the string as object payload).
     * Others to atom with value as object payload.
     */
    public static function valueToTerm( value:Any ):ValueTerm {
		if( value == null ) return AtomContext.GLOBALS.getAtom( "null" );

        if( Std.is( value, Term ) ) {
			var t = cast( value, Term );
			var vt = t.asValueTerm();
            if( vt != null ) return vt.dereference();
        }
		
		if( Std.is( value, Bool ) ) {
			var b:Bool = cast value;
			return if( b ) AtomContext.GLOBALS.getAtom( "true" ) 
			       else    AtomContext.GLOBALS.getAtom( "false" );
		}
		
		if( Std.is( value, Float ) ) {
			return new NumberTerm( cast value );
		}

		if( Std.is( value, Array ) ) {
			var array:Array<Dynamic> = cast value;
    		var terms = new Array<Term>();
			
			for( el in array ) terms.push( valueToTerm( el ));
			
			return Structure.makeList( terms );
		}
		
		if( Std.is( value, StringMap ) ) {
		    var hashAtom = newAtom();
			var hash:StringMap<Any> = cast value;
			hashAtom.object =  new blub.prolog.builtins.objects.HashObjectWrapper( hashAtom, hash );
			return hashAtom;
		}
		
		var atom = if( Std.is( value, String ) ) Atom.unregisteredAtom(cast value)
                   else newAtom();	
        
        atom.object = 
		#if js
		    new blub.prolog.builtins.objects.JavascriptObjectWrapper( value, atom );
		#elseif flash
            new blub.prolog.builtins.objects.FlashObjectWrapper( value, atom );
		#elseif java
            new blub.prolog.builtins.objects.JavaObjectWrapper( value, atom );
		#else
			null;
		#end

        return atom;		
	}

    /**
     * Convert a term to a value.
     * 
     * 'true' and 'false' atoms to Bool.
     * 'null' atom to null.
     * Atom to object payload or atom text.
     * NumberTerm to number.
     * term(Term) to term.
     * Lists to Array, recursively.
     * Unbound var/ref to null.
     * Others to toString.
     */
    public static function termToValue( term:ValueTerm ):Any {
        if( term == null ) return null;
		
		var atom = term.asAtom();
		if( atom != null ) {
			if( atom.object != null ) {
				var object = atom.object;
				if( Std.is( object, ObjectWrapper ) ) {
					var wrapper:ObjectWrapper = cast object;
					return wrapper.getObject();
				}
				
				return object;
			}			
			
			switch( atom.text ) {
				case "true": return true;
				case "false": return false;
				case "null": return null;
				default: return atom.text; 
			};
		}
		
		var num = term.asNumber();
		if( num != null ) return num.value;
		
		var struc = term.asStructure();
		if( struc != null ) {
			if( struc.getArity() == 1 && struc.getNameText() == "term" ) {
				return struc.argAt(0);
			}
			
			var array = struc.toArray();
			if( array == null ) return struc.toString();
			
			var resultArray = new Array<Dynamic>();
			for( t in array ) {
				resultArray.push( termToValue( t.asValueTerm() ) );
			}
			return resultArray;
		}
		
		//maybe the term needs deref-ing
		term = term.dereference();
		if( term.asReference() != null ) return null;
		
		return termToValue( term );
    }

}
