package blub.prolog;

import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Variable;
import haxe.Resource;
import blub.prolog.Predicate;
import blub.prolog.terms.ListTerm;

/**
 * Clause preprocessor.
 */
class Preprocessor {

    //the standard preprocessor theories
    static var THEORIES = [  
	    "DefiniteClauseGrammar.prolog",
		"ConstraintHandlingRules.prolog"
	];

	static var nullPreprocessor:Preprocessor;

    /**
     * Get a standard preprocessor
     */
    public static function getAStandardPreprocessor() {
		var standardPreprocessor = new Preprocessor( new Database( AtomContext.GLOBALS ));
		standardPreprocessor.loadStandardTheories();
		return standardPreprocessor;
	}

    /**
     * Get the do-nothing preprocessor singleton
     */
    public static function getNullPreprocessor() {
        if( nullPreprocessor == null ) {
            nullPreprocessor = new Preprocessor(null);            
        }
        
        return nullPreprocessor;
    }

    var macroDatabase (default,null):Database;
	
	/**
	 * The predicate names for the preprocessor queries to execute.
	 * This is built from the results of the "preprocessor(Name)" query.  
	 */
	var preprocessorPredicates (default,null):Array<String>;
	
	/**
	 * @param macroDatabase containing the preprocessor macro predicates
	 */
	public function new( macroDatabase:Database ) {
		this.macroDatabase = macroDatabase;
	}

    /**
     * Load the the standard theories.
     * Currently - DCG and CHR
     */
    public function loadStandardTheories() {
		for( theory in THEORIES ) {
			var source = Resource.getString( theory );
			macroDatabase.loadString(source, true, theory, getNullPreprocessor());
		}
	}

    /**
     * Lazy init of the preprocessor predicate names
     */
    private function getPreprocessorNames() {				
		if( preprocessorPredicates == null ) {
			var preprocAtom = macroDatabase.context.getAtom("preprocessor");
			
			preprocessorPredicates = [];
			
			//check that there are any preprocessors defined at all
			if( macroDatabase.lookup( new PredicateIndicator( preprocAtom, 1 ) ) == null ) {
				return preprocessorPredicates;
			}
			
			var nameVar = "Name";
			var query = new Query( macroDatabase, Structure.make( preprocAtom, new Variable(nameVar)));									   
            var bindings = query.allBindings();
			
            if( bindings != null ) {
				for( binding in bindings ) {
    				var name = binding.get(nameVar).asAtom();
    			    if( name != null ) preprocessorPredicates.push( name.text );
    			}
			}
		}
		
		return preprocessorPredicates;
	}

    /**
     * Preprocess a clause and return another array of clauses to be
     * asserted (or directives to be executed).
     * 
     * Query the macro database with "preprocess(Database,TermIn,TermsOut)". 
     * 
     * If the query fails, the original clause is returned.
     */
    public function process( db:Database, clause:Term ):Array<Term> {
		if( macroDatabase == null ) return [clause];
		
		var procNames = getPreprocessorNames();
		
		if( procNames.length == 0 ) return [clause];
		
		var dbWrapper:Atom = cast Marshal.valueToTerm( db );
				
		if( clause.asStructure() != null ) clause = clause.asStructure().varsToReferences();
				
		var termQ = [clause];
				
        //apply all the preprocessors
        for( procName in procNames ) {
			var outQ:Array<Term> = [];
			
			for( c in termQ ) {				
			    var clausesOut = callPreprocessor( procName, dbWrapper, c );

				for( out in clausesOut ) {
                    outQ.push( out );
				}
			}
			
			//use result queue as input for next preprocessor
			termQ = outQ;
		}
		
		var results:Array<Term> = [];
	
        for( t in termQ ) {
            var stru = t.asStructure();
            if( stru != null ) {
                results.push( stru.variablize() );
            }
            else {
                results.push( t );
            }
        }	
		
		return results;
	}
	
	private function callPreprocessor( name:String, dbWrapper:Atom, clause:Term ):Array<Term> {
		var varOut = new Variable();
        var queryTerm = new Structure( macroDatabase.context.getAtom(name), 
                                       [dbWrapper,clause,varOut] );
        
        var query = new Query( macroDatabase, queryTerm );      
        
		//just find the first solution
		if( ! query.engine.findSolution() ) return [clause]; 
        
		var result = query.environment[ varOut.index ].dereference();
		
		if( result.asReference() != null ) return [];
		
		var list = result.asStructure();
		if( list == null ) return [result]; 

        return list.commaList();		
	}
}
