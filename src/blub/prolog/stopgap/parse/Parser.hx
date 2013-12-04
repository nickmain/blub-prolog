package blub.prolog.stopgap.parse;

import blub.prolog.AtomContext;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Term;
import blub.prolog.terms.Variable;
import blub.prolog.stopgap.parse.Token;

/**
 * A Prolog parser
 */
class Parser {

    private var lexer:Lexer;
    private var origin:String;
    private var next:Token;
    
	public var context  :AtomContext;
    public var operators:Operators;    
    public var lastReadToken:Token;
    
    //used to detect numeric minus sign
    private var lastWasOp:Bool;
    
    public function new( context:AtomContext, operators:Operators, text:String, ?origin:String = "<unknown>", ?line:Int = 1, ?col:Int = 1 ) {
        lastWasOp = true;
        this.origin = origin;
        this.operators = operators;
		
        this.context = context;
		if( this.context == null ) this.context = new blub.prolog.AtomContext();
		
        lexer = new Lexer( text, origin, line, col );
    }

    /**
     * Read the next term
     * 
     * @return null if no more terms
     * @throw ParseError if there is a lexical or parse error in the source 
     */
    public function nextTerm():Term {
        var tok:Token = getNext( true );
        if( tok.type == token_eof ) return null;  
        
        if( tok.type == token_atom && tok.value == ":-" ) {
            var directive = readUntil( token_term_end );
            var stru = null;

            if( directive != null ) {
                stru = directive.asStructure();
                if( stru != null ) {
					stru = stru.unpackParentheses().asStructure();										
				}
			}
						
            if( stru == null ) {
                throw oops( "Malformed directive", tok );
            }
            
            return Structure.make( context.getAtom(":-"), stru );
        }
        else pushback( tok );
        
        var term = readUntil( token_term_end );
		var s = term.asStructure();
		if( s != null ) term = s.unpackParentheses();
		
		return term;
    }           
    
    /**
     * Read raw terms until the given terminator and build a composite
     * term from them.
     */
    private function readUntil( tokenType:TokenType ):Term {           
        lastWasOp = true;
        
        var node:ParseNode = null;
        var term:Term;
        
        while((term = nextRawTerm( tokenType )) != null )
        {
            var newNode = new ParseNode( this, term );

            if( node != null ) {
                node = node.assimilate( newNode );
            }
            else node = newNode;
        }
        
        if( node != null ) {
            node.assimilate( null );
            return node.getRoot().assembleTerm();
        }
        else return null;
    }
    
    
    /**
     * Read the next raw term without looking ahead for operators.
     * 
     * @param endType token type that can end this sub-stream
     * @return null if no more terms
     * @throw ParseError if there is a lexical or parse error in the source 
     */
    function nextRawTerm( ?endType:TokenType ):Term
    {
        var t = _nextRawTerm( endType );
        if( t == null ) return null;
	    
		var atom = t.asAtom();
		lastWasOp = ( atom != null
		            && (( operators.lookup( atom.text, 1 ) != null )
				      ||( operators.lookup( atom.text, 2 ) != null )));
        
        return t;
    }
    
    private function _nextRawTerm( endType:TokenType ):Term {
        if( endType == null ) endType = token_term_end; 
        
        var tok = getNext( true );
        
        if( tok.type == endType ) return null;
        
        switch( tok.type ) {
            case token_eof:      throw oops( "unexpected end of source" );                 
            case token_term_end: throw oops( "unexpected end of term", tok );                  
                
            case token_atom: return structureCheck( tok );
                
            case token_variable: return new Variable( cast( tok.value, String ));
            case token_int, token_float: return new NumberTerm( cast( tok.value, Float ));
            case token_string: return stringList( cast( tok.value, String ));
                
            case token_open_paren:   return Structure.make( context.getAtom("()"), readUntil( token_close_paren ));
            case token_open_brace:   return Structure.make( context.getAtom("{}"), readUntil( token_close_brace ));
            case token_open_bracket: return readList();

            default:
        }
        
        throw oops( "unexpected token: " + tok, tok );
    }       

    //convert string to list of char codes
    private function stringList( s:String ):Term {
        var t:Term = Structure.EMPTY_LIST; 
        
        var i = s.length - 1;
        while( i >= 0 ) {
            var bar = new Structure( Structure.CONS_LIST, [ new NumberTerm( s.charCodeAt( i )), t ] );
            t = bar;
            i--;
        }   
        
        return t;
    }
    
    private function readList():Term {
        var t:Term = readUntil( token_close_bracket );
		
        if( t == null ) return Structure.EMPTY_LIST; //empty list 
        
        var tail:Term;
        var head:Term;
        
        // [ head | tail ]
        if( Std.is( t, Structure )) {
            var s = cast(t, Structure);

            if( s.getName().text == "|" ) {
                if( s.getArity() != 2 ) throw oops( "list bar '|' requires terms on either side" );
                tail = s.argAt(1);
                head = s.argAt(0);
            }                           
            else {
                tail = Structure.EMPTY_LIST;
                head = s;
            }
        }
        else {
            tail = Structure.EMPTY_LIST;
            head = t;               
        }
        
        //flatten the comma-separated elements in head
        if( Std.is( head, Structure ) && cast(head, Structure).getName().text == "," )
        {
            var headTerms = cast( head, Structure ).flattenTree( "," ); 
            
            while( headTerms.length > 0 ) {
                var tailNode = new Structure( Structure.CONS_LIST, [ headTerms.pop(), tail ] );
                tail = tailNode;
            }
            
            return tail;
        }
        
        var list = new Structure( Structure.CONS_LIST, [ head, tail ] );
        
        return list;
    }
    
    /**
     * Check whether the given atom is the functor of a structure and
     * return that structure, or just return the atom otherwise.
     * 
     * ALSO - check for numeric minus sign
     */
    private function structureCheck( atom:Token ):Term
    {
        var tok:Token = getNext( false ); //whitespace is important
        
        //a minus after an operator and immediately before a number
        // is a negation of that number
        if( lastWasOp && atom.value == "-" 
          && (tok.type == token_int || tok.type == token_float) ) {
          
            var val = cast( tok.value, Float );
            val = -val;
            
            return new NumberTerm( val );
        }
        
        if( (!operators.couldBeOp( atom.value ))
          && tok.type == token_open_paren ) return readStructure( atom );
        
        pushback( tok );
		var text:String = cast atom.value;
        var a = context.getAtom( text );
		return a;
    }
    
    /**
     * Read a structure term - assuming the opening paren has been read
     */
    private function readStructure( functor:Token ):Term
    {
        var args:Term = readUntil( token_close_paren );
        
        if( args == null ) throw oops( "invalid structure - empty parentheses", functor );
        
        var argTerms:Array<Term>;
		var stru = args.asStructure();		
        if( stru != null ) {
			argTerms = stru.flattenTree( "," ); 
		}
        else 
        {
            argTerms = new Array<Term>();
            argTerms.push( args );
        }
        
        return new Structure( context.getAtom(cast(functor.value, String )), argTerms );
    }
    
    //push back a term
    private function pushback( tok:Token ) {
        if( next != null ) throw oops( "Pushback queue is too small", tok );
        next = tok;
    }
    
    //allows for a backlog of read tokens
    private function getNext( ?skipWS:Bool = true ):Token {
        var tok:Token;
        
        if( next == null ) {
            tok = lexer.next( skipWS );
        }           
        else if( skipWS && next.type == token_whitespace ) {
            tok = lexer.next( true );
        }
        else  {
            tok = next;
        }
        
        next = null;            
        if( tok.type != token_eof ) lastReadToken = tok;
        return tok;         
    }
    
    //helper to make a parse exception
    public function oops( msg:String, ?tok:Token ):ParseError {
        if( tok == null ) tok = lastReadToken; 
        return new ParseError( msg, origin, tok.startLine, tok.startCol );
    }

}