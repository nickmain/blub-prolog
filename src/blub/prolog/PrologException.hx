package blub.prolog;

import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Term;
import blub.prolog.Clause;
import blub.prolog.AtomContext;


/**
 * An exception that is part of the Prolog spec and can be thrown and/or
 * caught by Prolog theories
 */
class PrologException extends PrologError {

    public var context:Clause;
    public var errorTerm (default,null):Term;
    
    public function new( errorTerm:Term, context:Clause ) {
        super( errorTerm.toString() );        
        this.errorTerm = errorTerm;
		this.context   = context;
    }    
}

/** ISO Runtime Errors */
class RuntimeError extends PrologException {
    static var ERROR   = AtomContext.GLOBALS.getAtom( "error" );
    static var CONTEXT = AtomContext.GLOBALS.getAtom( "context" );
    static var NONE    = AtomContext.GLOBALS.getAtom( "none" );

    static var INSTANTIATION_ERROR  = AtomContext.GLOBALS.getAtom( "instantiation_error" );
    static var TYPE_ERROR           = AtomContext.GLOBALS.getAtom( "type_error" );
    static var EXISTENCE_ERROR      = AtomContext.GLOBALS.getAtom( "existence_error" );
    static var DOMAIN_ERROR         = AtomContext.GLOBALS.getAtom( "domain_error" );
    static var PERMISSION_ERROR     = AtomContext.GLOBALS.getAtom( "permission_error" );
    static var REPRESENTATION_ERROR = AtomContext.GLOBALS.getAtom( "representation_error" );
    static var EVALUATION_ERROR     = AtomContext.GLOBALS.getAtom( "evaluation_error" );
    static var RESOURCE_ERROR       = AtomContext.GLOBALS.getAtom( "resource_error" );
    static var SYNTAX_ERROR         = AtomContext.GLOBALS.getAtom( "syntax_error" );
    static var SYSTEM_ERROR         = AtomContext.GLOBALS.getAtom( "system_error" );

    static var EXIST_PROCEDURE = AtomContext.GLOBALS.getAtom( "procedure" );
    static var EXIST_SRC_SINK  = AtomContext.GLOBALS.getAtom( "source_sink" );
    static var EXIST_STREAM    = AtomContext.GLOBALS.getAtom( "stream" );

    function new( term:Term, context:Clause ) {
		super( new Structure( ERROR, [
		               term, 
					   new Structure( CONTEXT, cast [ 
					           if( context != null ) context.head else NONE 
						   ]) 
				   ] ), 
			   context ); 
	}
    
    public static function instantiationError( context:Clause ) {
		return new RuntimeError( INSTANTIATION_ERROR, context );
	}

	public static function existenceError( type:ExistenceError, culprit:Term, context:Clause ) {
		return new RuntimeError( 
		    new Structure( EXISTENCE_ERROR, [
			    switch( type ) {
					case ee_procedure:   EXIST_PROCEDURE;
					case ee_source_sink: EXIST_SRC_SINK;
					case ee_stream:      EXIST_STREAM;
				},
				culprit
			]), context );
	}

    public static function typeError( validType:Atom, culprit:Term, context:Clause  ) {
        return new RuntimeError( new Structure( TYPE_ERROR, [validType, culprit] ), context );
    }
	
    public static function domainError( msg:String, culprit:Term, context:Clause  ) {
		return new RuntimeError( new Structure( DOMAIN_ERROR, [Atom.unregisteredAtom(msg), culprit] ), context );
    }
	
	//TODO add more static constructors when needed
}

enum ExistenceError {
	ee_procedure;
    ee_source_sink;
    ee_stream;	
}

class TypeError extends RuntimeError {    
    public static var VALID_TYPE_atom                = AtomContext.GLOBALS.getAtom( "atom" );
    public static var VALID_TYPE_atomic              = AtomContext.GLOBALS.getAtom( "atomic" );
    public static var VALID_TYPE_byte                = AtomContext.GLOBALS.getAtom( "byte" );
    public static var VALID_TYPE_callable            = AtomContext.GLOBALS.getAtom( "callable" );
    public static var VALID_TYPE_character           = AtomContext.GLOBALS.getAtom( "character" );
    public static var VALID_TYPE_evaluable           = AtomContext.GLOBALS.getAtom( "evaluable" );
    public static var VALID_TYPE_in_byte             = AtomContext.GLOBALS.getAtom( "in_byte" );
    public static var VALID_TYPE_in_character        = AtomContext.GLOBALS.getAtom( "in_character" );
    public static var VALID_TYPE_integer             = AtomContext.GLOBALS.getAtom( "integer" );
    public static var VALID_TYPE_list                = AtomContext.GLOBALS.getAtom( "list" );
    public static var VALID_TYPE_number              = AtomContext.GLOBALS.getAtom( "number" );
    public static var VALID_TYPE_predicate_indicator = AtomContext.GLOBALS.getAtom( "predicate_indicator" );
    public static var VALID_TYPE_variable            = AtomContext.GLOBALS.getAtom( "variable" );	
    public static var VALID_TYPE_compound            = AtomContext.GLOBALS.getAtom( "compound" );  
}