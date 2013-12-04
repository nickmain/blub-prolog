package blub.prolog;

import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Variable;
import blub.prolog.terms.VariableContext;
import blub.prolog.terms.Structure;

import blub.prolog.engine.Operations;
import blub.prolog.engine.QueryEngine;
import blub.prolog.compiler.ClauseCompiler;

import blub.prolog.Listeners;

/**
 * A single clause of a predicate
 */
class Clause {
    
	public var predicate  (default,null):Predicate;
	
	public var listeners (default,null):Listeners<RetractionListener>;	
	
	/** Compiled code */
    public var code(default,null):OperationList;

    public var term(default,null):ClauseTerm;

    public var variableContext (default,null):VariableContext;

    public var head (default,null):ClauseTerm;
	public var body (default,null):ClauseTerm;


    public function new( predicate:Predicate, clause:ClauseTerm ) {
		this.predicate = predicate;
		this.term = clause;
		
		listeners = new Listeners<RetractionListener>();
		
		variableContext = if( Std.is( clause, Structure ))       
			cast( clause, Structure ).variableContext;        
            else VariableContext.EMPTY;
		
		head = clause.getHead();
		body = clause.getBody();
	}

    /**
     * Whether this clause could possibly match the given set of args.
     * Assumes that the head is a structure and that the arity matches the
     * number of args.
     */
    public function possibleMatch( args:Arguments ):Bool {
		var headStruct = head.asStructure();		
		var arity = headStruct.getArity();
		
		for( i in 0...arity ) {
			if( ! headStruct.argAt( i ).couldMatch( args[i] ) ) return false;
		}
		
		return true;
	}

    /**
     * Get the head argument at the index - null if head is not a struct
     */
    public function headArg( index:Int ) {
		if( Std.is( head, Structure )) return cast( head, Structure ).argAt(index);
		return null;
	}

    /**
     * Retract this clause
     */
    public function retract() {
		predicate.retractClause( this );
	}
    
	/**
	 * Called from Predicate when this clause is retracted - do not call directly
	 */
	public function isRetracted() {
		for( lis in listeners ) lis.clauseRetracted( this );		
	}
	
    /**
     * Compile this clause
     */
    public function compile() {
        code = new ClauseCompiler( predicate.database ).compile( this );
    }
	
	/** Explicitly set the code */
    public function setCode( code:OperationList ) {
        this.code = code;
    }
}
