package blub.prolog.stopgap.parse;

import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Term;

class ParseNode {
    public var term:Term;
    public var op:Operator;
    public var left:ParseNode;
    public var right:ParseNode;
    public var parent:ParseNode;
    private var parser:Parser;
    
    public function new( parser:Parser, term:Term ) { 
        this.parser = parser;
        this.term = term; 
        
        if( term != null && Std.is( term, Atom )) {
            op = parser.operators.lookupAny( cast(term, Atom).text );
        }
    }
    
	public function toString() { return term.toString(); }
	
    /** get the root node */
    public function getRoot():ParseNode {
        var root = this;
        while( root.parent != null ) root = root.parent;
        return root;
    }
        
    /**
     * Assemble the term - building any necessary structure
     * 
     */
    public function assembleTerm():Term {
        if( op != null ) {
            var struct = new Structure( cast(term, Atom) );
            if( left  != null ) struct.addArg( left.assembleTerm() ); 
            if( right != null ) struct.addArg( right.assembleTerm() );
                            
            struct = checkIfThenElse( struct ); 
            
            return struct;
        }
        
        return term;
    }
    
    /**
     * Check whether a structure is an if-then-else and make it so.
     * 
     * If-then-else is a semi-colon with a '->' as the first child. This
     * needs to be built as a special case here since the semantics of the
     * predicate are different from normal disjunction and detecting
     * this case is harder once a larger disjunction has been flattened.
     */
    private function checkIfThenElse( struct:Structure ):Structure {
        
        if( struct.getName().text == ";"
          && struct.getArity() == 2 
          && Std.is( struct.argAt(0), Structure )
          && cast(struct.argAt(0), Structure).getName().text == "->" )
        {
            var ifThen:Structure = cast( struct.argAt(0), Structure );

            return new Structure( parser.context.getAtom( "#if_then_else" ), [ 
                                  ifThen.argAt(0),
                                  ifThen.argAt(1),
                                  struct.argAt(1) ]);
        }
        
        return struct;
    }
    
    /**
     * Assimilate the next token in the stream by reconfiguring the
     * node tree to include it. This takes account of operator 
     * specifications and priority.
     *
     * @param node the next node to be incorporated - null to signify the
     *             end of the token stream (to allow validation of the
     *             tree).
     *  
     * @return the node that can assimilate the next token - usually the
     *         node passed in, null if no more assimilation is possible 
     */
    public function assimilate( node:ParseNode ):ParseNode
    {           
        if( node == null )
        {
            //check that operator is satisfied
            if( op != null ) {
                
                //if op has no parent and no args then OK - i.e. (op)
                if( parent == null && left == null && right == null ) return null; 
                
                if( right == null && op.expectsRight() )
                    throw parser.oops( "operator '" + op.atom.text + "' expects a term to the right" );
            }
            
            return null;
        }
        
        //this is an operator, other is not
        if( op != null && node.op == null )
        {
            if( ! op.expectsRight()) throw parser.oops( "operator '" + op.atom.text + "' does not expect a term to the right" );
        
            if( right != null ) throw parser.oops( "*** IMPL ERROR - op right arg not empty ***" );
            right = node; 
            node.parent = this;
        }
        
		//this is an operator, so is other
        else if( op != null && node.op != null )
        {
            var op2:Operator = node.op;
            if( op.expectsRight() && ! op2.expectsLeft() ) {
                right = node; 
                node.parent = this;
			}
            else throw parser.oops( "*** IMPL ERROR - op clash *** " + op + " " + op2 );
        }        
		
        //other is an operator
        else if( node.op != null )
        {
            var op2:Operator = node.op;
            if( ! op2.expectsLeft() ) throw parser.oops( "operator '" + op2.atom.text + "' {" + op2.priority + "} does not expect a term to the left: " + op.atom + " {" + op.priority + "}" );
            
            var leftChild:ParseNode = findInsertionPoint( op2 );
            leftChild.makeLeftChildOf( node );
        }
        
        //this is not an operator, other is not
        else if( op == null && node.op == null )
        {
            throw parser.oops( "unexpected term - operator expected: " + node );
        }
        
        return node;
    }
    
    /**
     * Make this node the left child of another - rewiring the current
     * parent if necessary
     */
    private function makeLeftChildOf( node:ParseNode ) {
        node.left = this;
        
        if( parent != null )
        {
            node.parent = parent;
            
            if( parent.left == this ) parent.left = node; 
            else parent.right = node;
        }
        
        parent = node;
    }
    
    /**
     * Find the node that should become the left-child of the given operator.
     */
    private function findInsertionPoint( op:Operator ):ParseNode {
        //this is an operator
        if( this.op != null )
        {
            switch( this.op.compareToRight( op ))
            {
                case 0: throw parser.oops( "operator priority clash " + this + " " + op.atom );
                    
                //this is higher priority
                case 1: return right;
                    
                //other is higher priority
                case 2: 
                    if( parent != null ) return parent.findInsertionPoint( op );
                    return this;
            }
        }
        
        //this is not an op
        if( parent != null ) return parent.findInsertionPoint( op );
        return this;
    }       
}