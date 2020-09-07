package blub.prolog;

import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.NumberTerm;

import blub.prolog.Database;
import blub.prolog.PrologException;
import blub.prolog.engine.Operations;
import blub.prolog.engine.QueryEngine;
import blub.prolog.compiler.PredicateCompiler;
import blub.prolog.builtins.BuiltinPredicate;

import blub.prolog.Listeners;

/**
 * A predicate indicator
 */
class PredicateIndicator {
    public static var SLASH:Atom = AtomContext.GLOBALS.getAtom("/"); 
	
    public var name (default,null):Atom;
    public var arity(default,null):Int; 
	
	/** The indicator as a structure of the form /(name,arity) */
    public var term (get,null):Structure; 
	
	public function new( name:Atom, arity:Int ) { 
		this.name = name;
		this.arity = arity;
	}

    /** From a string name/arity - assumes arity of zero if no slash is found */
    public static function fromString( text:String, ?context:AtomContext ) {
        var slash = text.lastIndexOf( "/" );
		var atom  = text;
		var arity = 0;
		
		if( slash >= 0 ) {
			atom = text.substr( 0, slash );
			arity = Std.parseInt( text.substr(slash+1) );
		}
		
		return new PredicateIndicator( 
		    (if( context != null ) context else AtomContext.GLOBALS).getAtom( atom ),
			arity );		
	}
	
	/** From a structure of the form /(name,arity) - exception if malformed */
	public static function fromTerm( term:Term, ?clauseContext:Clause ) {
		var structure = term.asStructure();
	
		if( structure == null
		 || structure.getArity() != 2 
		 || (! structure.getName().equals( SLASH ))
		 || structure.argAt(0).asAtom() == null 
         || structure.argAt(1).asNumber() == null ) {
		
		    throw RuntimeError.typeError( 
			    TypeError.VALID_TYPE_predicate_indicator, term, clauseContext );  	
		}
		
		return new PredicateIndicator( 
		               structure.argAt(0).asAtom(),
		               Std.int( structure.argAt(1).asNumber().value ));
	}
	
	var _string:String;
	public function toString() {
		if( _string == null ) _string = name.text + "/" + arity;
		return _string;
	}
	
	var _term:Structure;
	function get_term() {
		if( _term == null ) _term = new Structure( SLASH, [name,new NumberTerm(arity)] );
		return _term;
	}	
}

/**
 * A predicate
 */
class Predicate {

    public var database (default,null):Database;
    public var isDynamic (default,null):Bool;
	public var isBuiltin (default,null):Bool;
	public var indicator (default,null):PredicateIndicator;
	
	public var listeners (default,null):Listeners<AssertionListener>;
	
	/** Builtin function - null for non-built-in predicates */
	public var builtin (default,null):BuiltinPredicate;
	
	/** Compiled code - null for built-in predicates */
	public var code (default,null):OperationList;
	
    var clauseList:Array<Clause>;

    public function new( database:Database, indicator:PredicateIndicator, isDynamic:Bool ) {
		this.database = database;
		this.indicator = indicator;
		this.isDynamic = isDynamic;
		this.isBuiltin = false;
		
		listeners = new Listeners<AssertionListener>();
		
		clauseList = new Array<Clause>();
	}
	
	/**
	 * Find the clauses that could possibly match the given set of arguments.
	 * Only unreferenced numbers, atoms and structure functors/arities are considered.
	 */
	public function findMatchingClauses( args:Arguments ):Array<Clause> {
		if( indicator.arity == 0 ) return clauseList; //no args -> nothing to check
		
		var result = new Array<Clause>();
		
		//TODO indexing of clauses by first arg atom
		
		for( c in clauseList ) if( c.possibleMatch(args)) result.push( c );
		
		return result;
	}
	
	/** Append a new clause */
	public function appendClause( clause:ClauseTerm  ):Clause {
		if( isBuiltin ) throw "cannot add clauses to a built-in predicate: " + indicator.toString();
		var c = new Clause( this, clause );
		clauseList.push( c );
        for( lis in listeners ) lis.clauseAsserted( c, false );  
		return c;
	}

    /** Prepend a new clause */
    public function prependClause( clause:ClauseTerm  ):Clause {
		if( isBuiltin ) throw "cannot add clauses to a built-in predicate: " + indicator.toString();
        var c = new Clause( this, clause );
		
        clauseList.unshift( c );
		for( lis in listeners ) lis.clauseAsserted( c, true );	
        return c;
    }
	
	/**
	 * Retract a clause
	 */
	public function retractClause( clause:Clause ) {
		clauseList.remove( clause );
		clause.isRetracted();
	}
	
	public function clauseAt( index:Int ) { return clauseList[ index ]; }	
	public function clauseCount() { return clauseList.length; }	
 	public function clauses():Iterator<Clause> { return clauseList.iterator(); }
	
	/**
	 * Compile this predicate
	 */
	public function compile() {
		if( isBuiltin ) return; //cannot compile builtin preds
		
		//make sure clauses compiled first since pred code may reference them
		for( clause in clauseList ) clause.compile();
		
		code = new PredicateCompiler( database ).compile( this );
	}
	
	public function toString() { return indicator.toString(); }
	
	/** Explicitly set the built-in function and set the isBuiltin flag to true */
	public function setBuiltin( builtin:BuiltinPredicate ) {
		this.builtin = builtin;
		isBuiltin = true;
	}

    /**
     * Remove this predicate from the database
     */
    public function abolish() {
		database.abolish( indicator );
	}
	
	/**
	 * Called when this is abolished - do not call directly
	 */
	public function isAbolished() {
		//notify clauses
		for( clause in clauseList ) clause.isRetracted();
	}
	
    /**
     * Dump a listing of the clauses
     */
    public function listing( logger:String->Void ) {
        for( clause in clauseList ) {
            logger( clause.term.toString() );
        }
    }
}
