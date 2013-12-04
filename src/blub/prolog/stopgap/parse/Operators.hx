package blub.prolog.stopgap.parse;

import blub.prolog.AtomContext;
import blub.prolog.terms.Atom;
import blub.prolog.stopgap.parse.Operator;

/**
 * A set of built-in and user-defined operators.
 * 
 * NOTE: does not allow operator overloading - only one operator with a
 * given name can exist.
 */
class Operators {
    private var operators:Map<String,Operator>;
    
    public function new() {
        operators = new Map<String,Operator>();
    }
    
    /**
     * Add an operator
     */
    public function add( op:Operator ) {         
        operators.set( op.functor, op );
    }
    
    /**
     * Make a new Operator and add it
     */
    public function newOp( name:String, spec:OperatorSpec, priority:Int, context:AtomContext ) {
        var op = new Operator( context.getAtom( name ), spec, priority );
        add( op );
        return op;
    }
    
    /**
     * Get the operator with the given name and arity
     */
    public function lookup( name:String, arity:Int ) {
        return operators.get( Operator.functorForOp( name, arity ) );
    }

    /**
     * Get the operator with the given name (check arity 1 first, then 2)
     */
    public function lookupAny( name:String ) {
        var op = lookup(name, 1);
		if( op != null ) return op;
		return lookup(name, 2);
    }

    /**
     * Whether the name could be an op (of arity 1 or 2)
     */
    public function couldBeOp( name:String ) {
        return ( lookup(name,1) != null || lookup(name,2) != null );
    }
    
	private function new_op( name:String, spec:OperatorSpec, priority:Int ) {
		 newOp( name, spec, priority, AtomContext.GLOBALS );
	}
	
    /**
     * Add the standard Prolog operators
     */
    public function addStandardOps() {
        new_op( "dynamic"      , op_fx, 1150 );
        new_op( "discontiguous", op_fx, 1150 );
        new_op( "multifile"    , op_fx, 1150 );
		
        new_op( ":-"  , op_xfx, 1200 );
        new_op( "-->" , op_xfx, 1200 );
        new_op( "?-"  , op_fx , 1200 );
        new_op( ";"   , op_xfy, 1100 );
        new_op( "|"   , op_xfy, 1100 );
        new_op( "->"  , op_xfy, 1050 );
        new_op( ","   , op_xfy, 1000 );
        new_op( "\\+" , op_fy , 900  );
        new_op( "<"   , op_xfx, 700  );
        new_op( "="   , op_xfx, 700  );
        new_op( "=.." , op_xfx, 700  );
        new_op( "=@=" , op_xfx, 700  );
        new_op( "=:=" , op_xfx, 700  );
        new_op( "=<"  , op_xfx, 700  );
        new_op( "=="  , op_xfx, 700  );
        new_op( "=\\=", op_xfx, 700  );
        new_op( ">"   , op_xfx, 700  );
        new_op( ">="  , op_xfx, 700  );
        new_op( "@<"  , op_xfx, 700  );
        new_op( "@=<" , op_xfx, 700  );
        new_op( "@>"  , op_xfx, 700  );
        new_op( "@>=" , op_xfx, 700  );
        new_op( "\\=" , op_xfx, 700  );
        new_op( "\\==", op_xfx, 700  );
        new_op( "is"  , op_xfx, 700  );
        new_op( ":"   , op_xfy, 600  );
        new_op( "+"   , op_yfx, 500  );
        new_op( "-"   , op_yfx, 500  );
        new_op( "/\\" , op_yfx, 500  );
        new_op( "\\/" , op_yfx, 500  );
        new_op( "xor" , op_yfx, 500  );
        new_op( "?"   , op_fx , 500  );
        new_op( "*"   , op_yfx, 400  );
        new_op( "/"   , op_yfx, 400  );
        new_op( "//"  , op_yfx, 400  );
        new_op( "<<"  , op_yfx, 400  );
        new_op( ">>"  , op_yfx, 400  );
        new_op( "mod" , op_yfx, 400  );
        new_op( "rem" , op_yfx, 400  );
        new_op( "**"  , op_xfx, 200  );
        new_op( "^"   , op_xfy, 200  );
		
        //FIXME - conflict with CHR until overloaded ops implemented: new_op( "\\"  , op_fy , 200  );

        //arithmetic evaluator
        new_op( "#", op_fx, 1 );
		
		//global vars
		new_op( "from_global", op_xfx, 530  );
        new_op( "to_global", op_xfx, 530  );

		//native accessors		
		new_op( "<-"  , op_xfx, 510  );
		new_op( "."   , op_yfx, 100  );

        //rebindable variables      
        new_op( "<=&" , op_xfx, 510  ); //with backtracking
        new_op( "<="  , op_xfx, 510  ); //no backtracking
        new_op( "<#&" , op_xfx, 510  ); //arithmetic with backtracking
        new_op( "<#"  , op_xfx, 510  ); //arithmetic
		
		//async
		new_op( "spawn", op_fx, 910  );
		new_op( "spawns", op_xfx, 910  );
		
		//property changes
		new_op( "change_in", op_xfx, 910  );

        //Constraint Rules
        new_op( "@"  , op_fx, 110 );    //suppress dirty notification in expression graphs
        new_op( "@=" , op_xfx, 700  );  //passive assign in expression graphs		
		
		//Constraint Handling Rules
		new_op( "chr_constraint", op_fx, 1150 );
		new_op( "<=>", op_xfx, 1190 );
        new_op( "==>", op_xfx, 1190 );
		new_op( "\\" , op_xfx, 1150 );
		new_op( "or" , op_xfy, 950 );
        new_op( "and", op_xfy, 930 );
		new_op( "~"  , op_fx , 100 );
		
		//State machine edge labels and expression functions
		new_op( "=>"  , op_xfx, 1200 );
    }
}