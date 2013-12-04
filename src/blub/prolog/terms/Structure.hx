package blub.prolog.terms;

import blub.prolog.terms.Term;
import blub.prolog.terms.Reference;
import blub.prolog.AtomContext;
import blub.prolog.Predicate;
import blub.prolog.engine.QueryEngine;

/**
 * A structure.
 */
class Structure implements ClauseTerm
                implements ListTerm {
    
	/** Fixed instance used to build list structures */
	public static var CONS_LIST = AtomContext.GLOBALS.getAtom("CONS");

    /** Fixed instance denoting empty list */
    public static var EMPTY_LIST = AtomContext.GLOBALS.getAtom("[]");
	
    var args:Array<Term>;
    var atom:Atom;    

	var hasVars:Bool;
	var hasRefs:Bool;
    public var varContext:VariableContext;

    public var variableContext (get_variableContext, null):VariableContext;

    public function new( name:Atom, ?arguments:Array<Term> ) {
       atom = name;
	   if( arguments != null ) {
	       this.args = arguments;
		   for( arg in args ) updateArg( arg );
	   }
	   else this.args = new Array<Term>();	   	   
    }

    /**
     * Add an arg to the end of the structure;
     */
    public function addArg( t:Term ) {
        args.push( t );
		updateArg( t );
    }

    /**
     * Add an arg to the start of the structure;
     */
    public function prependArg( t:Term ) {
        args.unshift( t );
        updateArg( t );
    } 
	
    /** Update status flags based on a new arg and merge Variables */
    inline function updateArg( arg:Term ) {
		hasRefs = hasRefs || arg.hasReferences();
		hasVars = hasVars || arg.hasVariables();
	}

    /**
     * Force the structure to indicate that it has refs - use in situations
     * where the hasRefs cannot be properly maintained and it is better to
     * err on the side of having refs.
     */
    public function forceHasRefs() {
		hasRefs = true;
	}

    public function asValueTerm():ValueTerm { return this; }
    public function asAtom() { return null; }
    public function asStructure() { return this; }
    public function asNumber() { return null; }
    public function asReference() { return null; }
	public function asUnchasedReference() { return null; }

    public function hasReferences():Bool { return hasRefs; }
    public function hasVariables():Bool { return hasVars; }

    public function isGround():Bool {
		if( hasVars ) return false;
		return ! hasUnboundRefs(); 
	}

    public function equals( other:Term ):Bool {
         var otherS = other.asStructure();
		 if( otherS == null ) return false;
			
		if( ! atom.equals( otherS.atom ) ) return false;
		if( args.length != otherS.args.length ) return false;
		
        for( i in 0...args.length ) {
            if( ! args[i].equals( otherS.args[i] ) ) return false;
        }
		
		return true;
    }

    public function match( other:ValueTerm, env:TermEnvironment, trail:BindingTrail ):Bool {
        var otherStruct = other.asStructure();
		if( otherStruct == null ) return false;
		
		if( ! atom.equals( otherStruct.atom ) ) return false;
		if( args.length != otherStruct.args.length ) return false;
		
		var otherArgs = otherStruct.args;
		for( i in 0...args.length ) {
			if( ! args[i].match( otherArgs[i].asValueTerm(), env, trail )) {
                return false;
            }
		}
		
		return true;
	}

    /**
     * Whether this term (as an arg of a clause head) could possibly match the
     * given argument.
     * Assumes that the argument is dereferenced (if it is a ValRef then it is
     * unbound).
     */
    public function couldMatch( arg:ValueTerm ):Bool {
        if( arg.asReference() != null ) return true;  
		
		var argStruct = arg.asStructure();
		if( argStruct == null ) return false;
		
		return argStruct.atom.equals( atom )
		    && argStruct.getArity() == getArity();
    }

    /**
     * Unify two terms.
     * 
     * @return true if success
     */ 
    public function unify( other:ValueTerm, trail:BindingTrail ):Bool {
		
		if( other.asReference() != null ) return other.unify( this, trail );
		
		var stru:Structure = other.asStructure();
		if( stru == null ) return false;
		
		if( ! atom.equals( stru.atom ) ) return false;
		if( args.length != stru.args.length ) return false;
		
		for( i in 0...args.length ) {
			var arg1 = args[i].asValueTerm();
			var arg2 = stru.args[i].asValueTerm(); 
			 
			if( ! arg1.unify( arg2, trail ) ) {
				return false;
			}
		}
		
		return true;
	}

    /**
     * Whether this is a conjunction
     */
    public function isConjunction():Bool {
		return args.length == 2 && atom.text == ",";
	}

    /**
     * Whether this is a disjunction
     */
    public function isDisjunction():Bool {
        return args.length == 2 && atom.text == ";";
    }

    /**
     * Create a copy of this structure with all References turned back into
     * variables.
     * If this structure is already in variable form, or contains no references
     * then return self.
     */
    public function variablize( ?varMap:Map<Reference,Variable> ):Structure {
		if( hasVars ) return this;
		if( ! hasRefs ) return this;
		
		if( varMap == null ) varMap = new Map<Reference,Variable>();
		
		var copy = new Structure( atom );
        
        for( arg in args ) {
            var ref = arg.asReference();
			if( ref != null ) {			
				var v = varMap.get( ref );
				if( v == null ) {
					v = new Variable( ref.name );
					varMap.set( ref, v );
				}
				
				copy.addArg( v );
			}
			
			else {
				var stru = arg.asStructure();
				if( stru != null ) {
					copy.addArg( stru.variablize( varMap ) );
				}
				
				else {
					copy.addArg( arg );
				}
			}
        }
		return copy;
	}

    /**
     * Recursively unpack any args that are parenthesized
     */
     public function unpackParentheses():Term {
		if( atom.text == "()" ) {
			var s = argAt(0).asStructure();
			if( s != null ) return s.unpackParentheses();
			return argAt(0);
		}
		
        for( i in 0...args.length ) {
            var s = args[i].asStructure();			
			if( s != null ) args[i] = s.unpackParentheses(); 
        }
        
        return this;
    }

    /**
     * Make a structure that is bound to the given environment.
     * If this structure has no variables then return self, otherwise
     * make a copy with all vars replaced with environment values.
     */
    public function toValue( env:TermEnvironment ):ValueTerm {
		if( ! hasVars ) return this;

		var copy = new Structure( atom );
		
		for( arg in args ) {
			copy.addArg( arg.toValue(env) );
		}
		
		return copy;
	}

    /**
     * Make a structure that has all Variables turned into named References.
     * If this structure has no variables then return self, otherwise
     * make a copy with all vars replaced with references.
     */
    public function varsToReferences():Structure {
        if( ! hasVars ) return this;

        var env = variableContext.createNamedEnvironment();
		return cast toValue( env );
    }

    /**
     * Search for unbound refs
     */
    public function hasUnboundRefs():Bool {
        if( ! hasRefs ) return false;

        if( atom == CONS_LIST ) {
            //use a queue instead of recursion to avoid blowing the stack for long lists
            var queue = new List<Structure>();       
            queue.add(this);
        
            while( ! queue.isEmpty() ) {
                var s = queue.pop();
                var arg1 = s.argAt(0);                
                if( ! arg1.isGround() ) return true;
                 
                var arg2 = s.argAt(1);
                
                var str = arg2.asStructure();
                if( str != null && str.atom == CONS_LIST ) queue.add(str);
                else if( ! arg2.isGround() ) return true;
            }
        }
        else {
            for( arg in args ) {
				if( ! arg.isGround() ) return true;
            }
        }
        
        return false;
    }

    public function gatherReferences( ?refs:Array<Reference> ):Array<Reference> {
        if( refs == null ) refs = [];
		
		for( arg in args ) {
			var vt = arg.asValueTerm();
			if( vt != null ) vt.gatherReferences( refs );
		}
        return refs; 
    }

    /**
     * Make a structure that is as dereferenced as possible
     */
    public function dereference():ValueTerm {
		if( ! hasRefs ) return this;

        if( atom == CONS_LIST ) {
			//make array of derefed structs - wire them up once done
			//so that hasRefs flag will be updated correctly
			var elems = []; 
			
			var head = this;
			while( true ) {				
				if( ! head.hasRefs ) {
				    elems.push( head );	
					break;
				}
				
				var headCopy = new Structure( head.getName() );
				headCopy.addArg( head.argAt(0).asValueTerm().dereference() );
				elems.push( headCopy );
				
				if( head.argAt(1) == null ) break;
				
				var next = head.argAt(1).asValueTerm();
				
				if( next.asStructure() != null ) {
                    head = next.asStructure();					
				}
				else {
					headCopy.addArg( next.dereference() );
					break;
				}
			}
			
			//backwards - add tail to parent so that hasRefs is maintained
			var tail = null;
			while( elems.length > 0 ) {
				var elem = elems.pop();
				if( tail != null ) elem.addArg( tail );
				tail = elem;
			}
			
			return tail.asStructure();
		}
		else {
			var copy = new Structure( atom );
			
            for( arg in args ) {
                //should never be vars in a struct that is being dereferenced
                var valTerm:ValueTerm = cast arg;
                
                copy.addArg( valTerm.dereference() );
            }
						        
            return copy;			
		}
    }

    /**
     * If this is a rule (Head :- Body) then return the head term otherwise
     * return self.
     */
    public function getHead():ClauseTerm {
        if( atom.text == ":-" 
		 && args.length == 2
		 && Std.is( args[0], ClauseTerm ) ) {
			return cast( args[0], ClauseTerm );
		 }
		  		
		return this;
    }

    /**
     * If this is a rule (Head :- Body) then return the body term otherwise
     * return null.
     */
    public function getBody():ClauseTerm {
		if( atom.text == ":-" 
		 && args.length == 2 
		 && Std.is( args[1], ClauseTerm ) ) return cast( args[1], ClauseTerm );
		
        return null;
    }


   /**
     * Make a VariableContext for this structure and nested structures.
     * Any Variables will be assigned environment indices.
     * Same-named vars will be replaced with a single instance.
     */
    function get_variableContext():VariableContext {
		if( varContext == null ) {
			var name2var  = new Map<String,Variable>(); 
            var index2var = new Array<Variable>();			
			initContext( new VariableContext( this, name2var, index2var ),
			             name2var, index2var ); 
		}
         
        return varContext;
    }   
	
	/**
	 * Use the given variable context
	 */
	public function useVarContext( context:VariableContext, 
                                   name2var:Map<String,Variable>, 
                                   index2var:Array<Variable> ) {
		initContext(context, name2var, index2var );
	}
	
    /**
     * @param size current size of environment
     * @param vars hash of var name to variable
     * @return new size of environment
     */
    function initContext( context:VariableContext, 
	                      name2var:Map<String,Variable>, 
                          index2var:Array<Variable> ) {
		varContext = context;
		
        for( i in 0...args.length ) {
			var arg = args[i];
			
			if( Std.is( arg, Variable )) {
				var argVar = cast( arg, Variable );
				if( argVar.name == "_" ) continue; //skip anon vars
				
				var v = name2var.get( argVar.name );
				
				if( v == null ) { //first time this var has been seen
				    if( argVar.index != -1 ) {
						trace( "OOPS " + argVar.name + " " + this );
					}
				
					argVar.initIndex( index2var.length );
					name2var.set( argVar.name, argVar );
					index2var.push( argVar );
				}
				else { //replace arg with canonical var instance
					args[i] = v;
				}
			}
			else if( Std.is( arg, Structure )) {
                var argStruct = cast( arg, Structure );
				argStruct.initContext( context, name2var, index2var );
            }
		}
    }

    /**
     * Get the arg at the given index
     */
    public function argAt( index:Int ):Term {
		return args[index];		
	}

    public function getArgs() { return args; }

    public function getArity():Int { return args.length; }
    public function getName():Atom { return atom; }

    public function getIndicator() { return new PredicateIndicator(atom,args.length); }	
	
	public function getFunctor() { return atom.text + "/" + args.length; }
	
	public function getNameText() { return atom.text; }
	
	/**
	 * Clone this structure with a function to transform each arg
	 */
	public function clone( fn:Term->Term ) {
		var s = new Structure( atom );		
        for( a in args ) s.addArg( fn(a) );
		return s;
	}

	/**
     * Make a structure with single arg
     */
    public static function make( functor:Atom, arg:Term ):Structure {
        var s = new Structure( functor, [arg] );
        return s;
    }
    
    /**
     * Make a structure with two args
     */
    public static function make2( functor:Atom, arg1:Term, arg2:Term ):Structure {
        var s = new Structure( functor, [arg1, arg2] );
        return s;
    }
	
	/**
	 * Make a list
	 */
    public static function makeList( elems:Array<Term> ):ListTerm {
		if( elems.length == 0 ) return EMPTY_LIST;

        var tail:ListTerm = EMPTY_LIST;
		
		while( elems.length > 0 ) {
			var elem = elems.pop();			
            var s = new Structure( CONS_LIST );
			s.addArg( elem );
			s.addArg( tail );
			tail = s;
		}
		
        return tail;
    }	
	
	/**
     * Flatten a tree of structures all with the same functor to produce
     * a list of terms. Only flatten nodes with 2 args.
     * 
     * @param func the functor to flatten, defaults to functor of this
     */
    public function flattenTree( ?func:String ):Array<Term>
    {
        if( func == null ) func = atom.text;
        var terms = new Array<Term>();
        var tree = this;
        
        while( true ) {           
            if( tree.atom.text == func && tree.args.length == 2 )
            {
                var args = tree.args;
                terms.push( args[0] );
                
                if( Std.is( args[1], Structure )) {
                    tree =  cast( args[1], Structure );
                }
                else {
                    terms.push( args[1] );
                    break;
                }
            }
            else
            {
                terms.push( tree );
                break;
            }
        }
        
        return terms;
    }
	
	public function commaSeparated() { return commaList(); }
	
	/**
     * If this is a comma then recursively add the args to the given array (or
     * allocate a new array). If this is not a comma then just add self to the
     * array.
     * 
     * @param array array to add elements to (and return)
     */
    public function commaList( ?array:Array<Term> ):Array<Term> {
		if( array == null ) array = new Array<Term>();
		
        if( atom.text == "," ) {
            array.push( args[0] ); //should not be a comma - if it is then it is nested
            
			var arg1struct = args[1].asStructure();
			if( arg1struct != null ) {
				arg1struct.commaList( array );
			}
            else array.push( args[1] );
			
            return array;
        }
        else array.push( this );
		
        return array;            
    }

    /**
     * Whether this could be a proper list - just check that it starts out
     * as a list but do not check the entire tree - use isList() for that.
     */
    public function couldBeList():Bool {
        return ( atom == CONS_LIST && getArity() == 2 );
	}
	
	/**
	 * Whether this is a proper list - check the entire list to see whether
	 * it ends with the empty list or an unbound ref.
	 */
	public function isList():Bool {
		var str = this;
		
        while( str.atom == CONS_LIST && str.getArity() == 2 ) {
			var tail = str.argAt(1);
			var atm  = tail.asAtom();
			if( atm != null ) return atm.isList();
			
			//tail is an unbound var
			var ref = tail.asReference();
			if( ref != null ) return true;  
			
			str = tail.asStructure();
			if( str == null ) return false;
        }
        
        return false;
	}
	
	/**
	 * Get an iterator for this list
	 */
	public function listIterator():Iterator<Term> {
		return new ListIterator(this);
	}
	
	/**
     * Get an iterator for this list, returning the structures
     */
    public function listStructureIterator():Iterator<Structure> {
        return new ListStructureIterator(this);
    }
	
    /**
     * ListTerm interface
     */
    public function listToArray():Array<Term> {
        return toArray();
    }	
	
	/**
     * Convert a list to an array 
     * 
     * @param array array to add elements to (and return)
     * @return null if this structure is not an array
     */
    public function toArray( ?array:Array<Term> ):Array<Term> {
        if( atom == CONS_LIST ) {
            if( array == null ) array = new Array<Term>();
            array.push( args[0] );
            
			var s = args[1].asStructure();
            if( s != null ) {
                s.toArray( array );
            }
            
            return array;
        }
        
        return null;            
    }
    
    private function listToString():String {
		var buf = new StringBuf();
		buf.add("[");
		
		var stru = this;
		
        while( true ) {
			var arg0 = stru.argAt(0);
            if( arg0 == null ) {
                buf.add("<???>");
                break;
            }
			
			buf.add( arg0.toString() );
			
			var tail = stru.argAt(1);
			if( tail == null ) {
                buf.add("|<???>");
				break;
			}

            if( tail.asReference() != null ) tail = tail.asReference().dereference(); 

			if( tail == EMPTY_LIST ) break;
			
			var tailS = tail.asStructure();
			if( tailS != null && tailS.atom == CONS_LIST ) {
				buf.add(",");
				stru = tailS;
				continue;
			}

            buf.add("|");
            buf.add( tail.toString() );
            break;
        }
        
		buf.add("]");
        return buf.toString();
    }
    
    private function commaToString( ?s:String = "(" ):String {
        if( atom.text == "," )
        {
            for( i in 0...args.length ) {
                if( i > 0 ) s += ",";

                if( Std.is( args[i], Structure )) {
                    s = cast(args[i], Structure).commaToString( s );
                }
                else {
                    s += "" + args[i];
                }
            }
        }               
        else {
            s += toString();
        }
        
        return s;
    }
    
    public function toString():String {
        if( atom == CONS_LIST ) return listToString();
        if( atom.text == "," ) return commaToString() + ")";
        
        var s = atom.toString();          
        s += "( ";
        
        var first = true;
        for( t in args ) {
            if( first ) first = false;
            else s += ", ";
            
            s += t;
        }
        
        s += " )";
        
        return s;
    }
}

private class ListStructureIterator {
    var s:Structure;
    
    public function new( s:Structure ) {
        this.s = s;
    }
    
    public function next():Structure {
        if( s.getName() == Structure.CONS_LIST ) {
            var stru = s;
            s = s.argAt(1).asStructure();
            return stru;
        }
        
        return null;
    }
    
    public function hasNext() {
        return s.getName() == Structure.CONS_LIST;
    }
}

private class ListIterator {
	var s:Structure;
	
	public function new( s:Structure ) {
		this.s = s;
	}
	
	public function next():Term {
		if( s.getName() == Structure.CONS_LIST ) {
			var elem = s.argAt(0);
			s = s.argAt(1).asStructure();
			return elem;
		}
		
		return null;
	}
	
	public function hasNext() {
		return s.getName() == Structure.CONS_LIST;
	}
}
