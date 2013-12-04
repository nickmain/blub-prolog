package blub.prolog.terms;

import blub.prolog.terms.Term;

/**
 * The context for a set of variables - the single instance of Variable for
 * a given name and the indices of the vars in a given Structure tree.
 * 
 * Variables are given indices in order of appearance from left to right.
 */
class VariableContext {

    public static var EMPTY:VariableContext =
		new VariableContext( null, new Map<String,Variable>(), [] );
    
	/** The root of this context */
    public var root (default,null):Structure;

    /** The number of variables */
    public var count (get_count,null):Int;

    var name2var :Map<String,Variable>;
	var index2var:Array<Variable>;

    public function new( root:Structure, 
	                     name2var:Map<String,Variable>, 
						 index2var:Array<Variable> ) {
		this.root = root;
		this.index2var = index2var;
		this.name2var  = name2var;
	}
	
	/**
	 * Get a named var - null if not known
	 */
	public function varNamed( name:String ):Variable {
		return name2var.get(name);
	}
	
	/**
	 * Get the var at the given index
	 */
	public function varAt( index:Int ):Variable {
		return index2var[index];
	}
	
	/**
	 * Get the vars in index order
	 */
	public function variables():Iterator<Variable> {
		return index2var.iterator();
	}

    /**
     * Get the vars names 
     */
    public function variableNames():Array<String> {
		var names = new Array<String>();
		for( v in variables() ) {
			names.push( v.name );
		}
        return names;
    }
	
	/**
	 * Create an environment for the variables in this context - may be null
	 */
	public function createEnvironment():TermEnvironment {
		var c = count;
		if( c == 0 ) return null;
		
		var environment = new TermEnvironment();
        for( i in 0...c ) environment.push( new Reference() );
		return environment;
	}


    /**
     * Create an environment for the variables in this context - may be null.
     * Create References using Variable names.
     */
    public function createNamedEnvironment():TermEnvironment {
        if( count == 0 ) return null;
        
        var environment = new TermEnvironment();
        for( v in index2var ) environment.push( new Reference( v.name ) );
        return environment;
    }
	
	function get_count() { return index2var.length; }
	
	public function toString() {
		return "VariableContext:" + index2var;
	}
}
