package blub.prolog.compiler;

import blub.prolog.Database;
import blub.prolog.terms.Term;
import blub.prolog.terms.ClauseTerm;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.compiler.Instruction;
import blub.prolog.engine.Operations;

/**
 * Base for compilers
 */
class CompilerBase {

    #if compile_dump
    public static var dumpCompile:Bool = false;
    #end

    public static var ADD_LOGGING = true;

    public var database (default,null):Database;

    var instructions:InstructionList;

    function new( database:Database ) {
        this.database = database;
		instructions = new InstructionList();
	}

    /**
     * Assemble the instructions
     */
    public function assemble():OperationList {
		var asm = new Assembler( database );
		asm.translateList( instructions );
		return asm.operations;
	}

    /**
     * Cast to ClauseTerm or throw up
     */
    public function clauseTerm( term:Term ):ClauseTerm {
		if( ! Std.is(term,ClauseTerm)) throw new PrologError( "Bad clause term: " + term );
		return cast term;
	}

    /**
     * Compile a term.
     * 
     * @param tail true to call final predicate(s) as a tail-call
     */
    public function compileTerm( term:ClauseTerm, ?tail:Bool = false ) {
		var stru = term.asStructure();
		var args = null;
		if( stru != null ) {
			switch( term.getIndicator().toString() ) {				
				case ",/2" : { compileConjunction( stru, tail ); return; }
				case ";/2" : { compileDisjunction( stru, tail ); return; }	
				
				default: 
			}

            args = stru.getArgs();			
			
            //TODO arg tracking/optimization - avoid copying arg if already set up
            //TODO roll arg setting into the pred call instruction ?
		}
		
		//is a single call to a predicate
        var pred = database.lookup( term.getIndicator() );	
		if( pred != null ) {			
			//built-in predicate
			if( pred.isBuiltin ) {
				pred.builtin.compile( this, pred, term );
				
				if( tail ) add( succeed );
				return;
			}			
		}
		
        //user predicate
        if( tail ) add( tail_call( term.getIndicator().toString(), args ) )
        else       add( call_pred( term.getIndicator().toString(), args ) );
	}

    /**
     * Compile a nested term 
     * 
     * @param cutBarrier true to place a cut-barrier at the start of the
     *                   nested code
     */
    public function compileNestedTerm( term:Term, ?cutBarrier:Bool = false ) {
		//compile with tail calls/succeed at end - these will pop the frame
		//that is pushed by the call_nested instruction
        var nestedCode = compileOther( clauseTerm(term), true );
		
		//cut barrier which will be removed when the call_nested frame is poppped
		if( cutBarrier ) {
			nestedCode.unshift( cut_point );
		}
		
        add( call_nested( nestedCode ) );
	}

    function compileConjunction( stru:Structure, ?tail:Bool = false ) {
        var t1 = clauseTerm( stru.argAt(0) );
        var t2 = clauseTerm( stru.argAt(1) );
        
		var t1s = t1.asStructure();
		if( t1s != null && t1s.isDisjunction() ) {
			
			//surround LHS disjunction with a frame and compile with tail=true
			compileNestedTerm( t1 );
		}
		else {
            compileTerm( t1, false ); //compile LHS inline
		}
		
        compileTerm( t2, tail );  //compile RHS with given tail-call option		
	}

    function compileDisjunction( stru:Structure, ?tail:Bool = false ) {
        var t1 = clauseTerm( stru.argAt(0) );
        var t2 = clauseTerm( stru.argAt(1) );
        
        //compile the alternative branch
        var alternative = compileOther( t2, tail );
        
        //push a choicepoint to run the alternative
        add( choice_point( alternative ));
        
        //compile the primary branch
        compileTerm( t1, tail );
	}
	
	/** Compile a term in a separate compiler */
	public function compileOther( term:ClauseTerm, ?tail:Bool = false ):InstructionList {
		var altCompiler = new CompilerBase( database );
        altCompiler.compileTerm( term, tail );
        return altCompiler.instructions;
	}
	
	/**
	 * Add an instruction to the list
	 */
	public function add( instruction:Instruction ) {
		instructions.push( instruction );		
	}
	
	/**
	 * Add a logging operation
	 */
	function logOp( msg:String ) {
		if( ADD_LOGGING ) add( log( msg ) );
	}
}
