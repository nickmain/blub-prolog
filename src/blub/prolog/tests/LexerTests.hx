package blub.prolog.tests;

import blub.prolog.stopgap.parse.Lexer;
import blub.prolog.stopgap.parse.Token;

class LexerTests extends haxe.unit.TestCase {

    public function testSanity() {
        var tokens = tokenize(
            "mother_child('miss emelia trude', sally).         
            father_child(tom, sally). 
            father_child(tom, erica). 
            father_child(mike, tom).
        
            sibling(X, Y)      :- parent_child(Z, X), parent_child(Z, Y). 
                
            parent_child(X, Y) :- father_child(X, Y). 
            parent_child(X, Y) :- mother_child(X, Y)." );
        
        token( tokens[0], token_atom, "mother_child" );            
        token( tokens[1], token_open_paren, "(" );         
        token( tokens[2], token_atom, "miss emelia trude" ); 
        
        //TODO...
    }
 	
    public function testComment() {
        var tokens = tokenize( "234 %asjdhasjdh" );
        assertEquals( 2, tokens.length );
        token( tokens[0], token_int, 234 );
        token( tokens[1], token_eof, null );
        
        tokens = tokenize( "foo. %asjdhasjdh
                            bar." );
        assertEquals( 5, tokens.length );
        token( tokens[0], token_atom, "foo" );
        token( tokens[1], token_term_end, "." );
        token( tokens[2], token_atom, "bar" );
        token( tokens[3], token_term_end, "." );
        token( tokens[4], token_eof, null );
        
    }

    public function testMultipleComments() {
        var tokens = tokenize( "234 %asjdhasjdh
%second line" );

        assertEquals( 2, tokens.length );
        token( tokens[0], token_int, 234 );
        token( tokens[1], token_eof, null );        
    }
    
    public function testNumbers() {
        var tokens = tokenize( "234 1 2.34 1e-3 0xfe 0.1 93" );
        
        token( tokens[0], token_int, 234 );
        token( tokens[1], token_int, 1 );
        token( tokens[2], token_float, 2.34 );
        token( tokens[3], token_float, 0.001 );
        token( tokens[4], token_int, 254 );
        token( tokens[5], token_float, 0.1 );
        token( tokens[6], token_int, 93 );
    }
    
    
    private function tokenize( s:String, ?skipWS:Bool = true ) {
    
        var lexer = new Lexer( s, "test" );
        
        var tokens = new Array<Token>();
        while( true )
        {
            var t = lexer.next( skipWS );
            tokens.push( t );
            if( t.type == token_eof ) break;               
        }

        return tokens;
    }
    
    private function token( t:Token, type:TokenType, value:Dynamic ) {
        assertEquals( type, t.type );
        assertEquals( value, t.value );
    }
}