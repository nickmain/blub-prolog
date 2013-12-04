package blub.prolog;

import blub.prolog.stopgap.parse.Operators;
import blub.prolog.stopgap.parse.Operator;
import blub.prolog.stopgap.parse.Parser;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.NumberTerm;
import blub.prolog.builtins.Builtins;
import blub.prolog.builtins.lazy.LazyLoadPredicates;

import blub.prolog.Predicate;
import blub.prolog.Listeners;

/**
 * A Prolog database
 */
@:expose
class Database {
 
    public var operators  (default,null):Operators;
    public var context(default,null):AtomContext; 
    
	public var listeners (default,null):Listeners<PredicateListener>;
	
	public var preprocessor:Preprocessor;
	
    var predicates:Map<String,Predicate>;
	
	var lazyPredicates:LazyLoadPredicates;
	var compileQueue:List<Predicate>;

    /** Global values accessible via the <= and => operators */
    public var globals (default,null):Map<String,ValueTerm>;

    public function new( ?context:AtomContext, ?operators:Operators ) {
		this.context = if( context != null ) context else new AtomContext();
		predicates = new Map<String,Predicate>(); 
        listeners = new Listeners<PredicateListener>();
		
		if( operators  == null ) {
			operators = new Operators();
			operators.addStandardOps();
		}
		
		this.operators = operators;
		
		Builtins.register( this );
		
		globals = new Map<String,ValueTerm>();
	}

    /**
     * Set a global value
     */
    public function setGlobal( key:String, value:Dynamic ) {
		var atom = Atom.unregisteredAtom( key );
		atom.object = value;
		globals.set( key, atom );
	}

    /**
     * Get a global value
     */
    public function getGlobal( key:String ):Dynamic {
        var atom = globals.get( key );
		if( atom == null || atom.asAtom() == null ) return null;
		return atom.asAtom().object;
    }

    /**
     * Add or replace a predicate
     */
    public function addPredicate( indicator:PredicateIndicator, ?isDynamic:Bool = false ):Predicate {
		var pred = new Predicate( this, indicator, isDynamic );
		predicates.set( indicator.toString(), pred );
		
		for( lis in listeners ) lis.predicateAdded( pred );
		
		return pred;
	}

    /**
     * Add or replace a predicate, given the predicate source - used primarily
     * for lazy loading.
     */
    public function addPredicateSrc( functor:String, src:String, ?filename:String = "lazy-load" ):Predicate {
		var parser = new Parser( context, operators, src, filename );

        var pred = null;
		
		while( true ) {
            var t = parser.nextTerm();            
            if( t == null ) break;

            if( Std.is(t, ClauseTerm )) {
				var clause:ClauseTerm = cast( t, ClauseTerm );
				if( pred == null ) {				
                    var head  = clause.getHead();
				    pred = addPredicate( head.getIndicator(), false );
				}
				 
				pred.appendClause( clause );                 
                continue;
            }
            else throw new PrologError( "Invalid top-level clause: " + t );		
		}
        
        //if compilation is under way..
        if( compileQueue != null && pred != null ) compileQueue.add( pred );
		
        return pred;
    }
	
	/**
	 * Look up a predicate by its indicator.
	 * @return null if no such predicate is known.
	 */
	public function lookup( indicator:PredicateIndicator ):Predicate {
		var pred = predicates.get( indicator.toString() );

        //lazy load during compilation...		
		if( pred == null && compileQueue != null ) {
			if( lazyPredicates == null ) lazyPredicates = new LazyLoadPredicates(this);
			if( lazyPredicates.load( indicator ) ) {
				pred = predicates.get( indicator.toString() );				
			}
		}
		
		return pred;
	}
	
	/**
	 * Compile all current predicates.
	 * Uses a queue to allow lazy-load predicates to be appended.
	 */
	public function compile() {		
		compileQueue = new List<Predicate>();
		for( pred in predicates ) compileQueue.add( pred );
		
		while( ! compileQueue.isEmpty() ) {
			var pred = compileQueue.pop();
			pred.compile();
		}
		
		compileQueue = null;
	}
	
	/**
     * Assert a new fact or rule at the start of the database
     */
    public function assertA( term:ClauseTerm, ?isQuery:Bool = false ) {
        assert( term, true, isQuery );
    }
	
	/**
     * Assert a new fact or rule at the end of the database
     */
    public function assertZ( term:ClauseTerm, ?isQuery:Bool = false ) {
        assert( term, false, isQuery );
    }
            
    private function assert( clause:ClauseTerm, atFront:Bool, isQuery:Bool ) {
		var head  = clause.getHead();
		var indic = head.getIndicator();
        
        var pred:Predicate = lookup( indic );
		if( pred == null ) {
			pred = addPredicate( indic, isQuery ); //if during query then pred is dynamic
		}
		else if( isQuery && ! pred.isDynamic ) {
			throw new PrologError( "Cannot assert clauses to a non-dynamic predicate: " + indic );
		}
		 
		var c = if( atFront ) pred.prependClause( clause )
		        else pred.appendClause( clause );
		
		//compile clause added via a query assert
        if( isQuery ) c.compile();
    }
	
	/**
	 * Abolish the given predicate
	 */
	public function abolish( indicator:PredicateIndicator ) {
        var pred = predicates.get( indicator.toString() );
		
		if( pred != null ) {
            predicates.remove( indicator.toString() );
			pred.isAbolished();
            for( lis in listeners ) lis.predicateAbolished( pred );
		}
	}
	
    /**
     * Load a source string and (by default) compile.
     * The source terms are passed through a Preprocessor
     */
    public function loadString( source:String,
	                            ?compileAll:Bool = true, 
								?filename:String = "<unknown>",
								?preprocessor:Preprocessor ) {
									
        var parser = new Parser( context, operators, source, filename );
        
		if( preprocessor == null ) preprocessor = this.preprocessor;
		
		if( preprocessor == null ) {
			this.preprocessor = Preprocessor.getAStandardPreprocessor();
			preprocessor = this.preprocessor;
		}
		
        while( true ) {
            var t = parser.nextTerm();
            if( t == null ) break;

            //handle "op" directives before preprocessor so that operator parsing works
            var stru = t.asStructure();            
            if( stru != null && stru.getNameText() == ":-" && stru.getArity() == 1
               && stru.argAt(0).asStructure() != null ) {
				
				var directive = stru.argAt(0).asStructure();
				if( directive.getNameText() == "op" && directive.getArity() == 3 ) {
                    processDirective( stru.argAt(0).asStructure() );
                    continue;
			    }
            }

            var terms = preprocessor.process( this, t );
			for( t in terms ) loadTerm( t );
        }    

		if( compileAll ) compile();
    }
	
	/**
	 * Load a term - interpret it as a directive, clause or rule.
	 */
	public function loadTerm( t:Term ) {
		var stru = t.asStructure();
		
        if( stru != null && stru.getNameText() == ":-" && stru.getArity() == 1
		   && stru.argAt(0).asStructure() != null ) {
            processDirective( stru.argAt(0).asStructure() );
            return;
        }
        
        if( Std.is(t, ClauseTerm )) {
            
            //fact or prolog rule
            var ct:ClauseTerm = cast t;                 
            assertZ( ct );                  
            return;
        }
        
        throw new PrologError( "Invalid top-level clause: " + t );		
	}
		
	/**
	 * declare a dynamic predicate
	 */
	function declareDynamic( indicator:PredicateIndicator  ) {
		var pred = lookup( indicator );
		
		if( pred == null ) {
            pred = addPredicate( indicator, true );			
        }
		else throw new PrologError( "cannot declare existing predicate to be dynamic: " + indicator );
	}
	
	private function processDirective( directive:Structure ) {
		var text = directive.getNameText();
		
        //op
        if( text == "op" ) {
            var op = directive;
            if( op.getArity() != 3 ) throw new PrologError( "op/3 directive requires 3 args: " + op );            
            
            var priority = cast( op.argAt(0), NumberTerm );
            if( priority == null ) throw new PrologError( "op/3 directive requires numeric priority as first arg: " + op );
            if( priority.value < 0 || priority.value > 1200 ) throw new PrologError( "op/3 directive requires numeric priority from 0 to 1200: " + op );
            if( Std.int(priority.value) != priority.value ) throw new PrologError( "op/3 directive requires integer priority: " + op );
            
            if( ! Std.is(op.argAt(1), Atom)) throw new PrologError( "op/3 directive requires spec as 2nd arg: " + op );
            if( ! Std.is(op.argAt(2), Atom)) throw new PrologError( "op/3 directive requires operator as 3rd arg: " + op );
            
			//trace( "Adding operator " + op.argAt(2) );
            operators.newOp( cast(op.argAt(2), Atom).text, 
                             Operator.opSpec( cast(op.argAt(1), Atom).text ), 
                             Std.int(priority.value),
							 context );             
            return;
        }
        
		//dynamic
		else if( text == "dynamic" ) {
			var preds = directive.argAt(0).asStructure();
			if( preds == null ) throw new PrologError( "dynamic/1 directive requires one or more predicate specs: " + directive );
			
			var specs = preds.commaList();
			
			for( spec in specs ) {
				var indic = PredicateIndicator.fromTerm( spec );
                declareDynamic( indic );
			}
		}
		
        //TODO include
        //TODO ensure_loaded
    }
	
	/**
	 * Dump a listing of non-builtin predicates
	 */
	public function listing( logger:String->Void ) {
		for( pred in predicates ) {
			if( ! pred.isBuiltin ) {
				pred.listing( logger );
			}
		}
	}
	
	/**
	 * Convenience for performing a query
	 */
	public function query( term:String ):Query {
		var t = TermParse.parse( term, context, operators );
		if( ! Std.is( t, ClauseTerm ) ) {
			throw new PrologError( "Query is not a valid atom or structure: " + term );
		}
		
		return new Query( this, cast( t, ClauseTerm ));
	}
}
