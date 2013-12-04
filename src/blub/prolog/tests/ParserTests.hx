package blub.prolog.tests;

import blub.prolog.terms.Term;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Atom;
import blub.prolog.stopgap.parse.Parser;
import blub.prolog.stopgap.parse.Operators;
import blub.prolog.stopgap.parse.Operator;

class ParserTests extends haxe.unit.TestCase {

    public function testRawNumbers() {
        var parser:Parser = makeParser( "234 . -1 . 2.34 . 1e-3 . 0xfe . -0.1 . 93 ." );
        
        number( parser.nextTerm(), 234 );
        number( parser.nextTerm(), -1 );
        number( parser.nextTerm(), 2.34 );
        number( parser.nextTerm(), 0.001 );
        number( parser.nextTerm(), 254 );
        number( parser.nextTerm(), -0.1 );
        number( parser.nextTerm(), 93 );
        
        assertTrue( parser.nextTerm() == null );
    }

    public function testRawStructs() {
        var parser:Parser = makeParser( "foo(bar) :-  1 +X - -4 / {3,4} * (a,b,foo(c))." );
              
        term(parser.nextTerm(), Structure,
             ":-( foo( bar ), -( +( 1, X ), *( /( -4, {}( (3,4) ) ), (a,b,foo( c )) ) ) )" );
             
        assertTrue( parser.nextTerm() == null );
    }
    
    public function testLists() {
        var parser:Parser = makeParser( "[]. [a]. [a,b]. [a,2|C]." );

        term( parser.nextTerm(), Atom, "[]" ); 
        term( parser.nextTerm(), Structure, "[a]" );
        term( parser.nextTerm(), Structure, "[a,b]" );
        term( parser.nextTerm(), Structure, "[a,2|C]" );
        assertTrue( parser.nextTerm() == null );
    }

    public function testNestedLists() {
        var parser:Parser = makeParser( "[[ x ] ]. [[]]." );

        term( parser.nextTerm(), Structure, "[[x]]" );
        term( parser.nextTerm(), Structure, "[[]]" );
        assertTrue( parser.nextTerm() == null );
    }

    public function testString() {
        var parser:Parser = makeParser( "\"\". \"hello world\"." );
        
        term( parser.nextTerm(), Atom, "[]" ); 
        term( parser.nextTerm(), Structure, "[104,101,108,108,111,32,119,111,114,108,100]" );
        assertTrue( parser.nextTerm() == null ); 
    }

    public function testDirectives() {
        var parser:Parser = makeParser( ":- foo(bar).\n  :- dynamic(@@##@@)." );
        
        term( parser.nextTerm(), Structure, ":-( foo( bar ) )" );
        term( parser.nextTerm(), Structure, ":-( dynamic( @@##@@ ) )" );
        assertTrue( parser.nextTerm() == null );
    }
    
    public function testOperators() {
        var src:String = ":-op(1105,xfx,'**>>'). foo(a). A **>> B.";
        
        var db:Database = new Database();
        db.loadString( src );
        
        var t:Structure = cast TermParse.parse( "a **>> b", db.context, db.operators );
        
        assertEquals( "**>>", t.getName().text );
    }
    
    //this was a bug in parsing a query
    public function testPlusComma() {
        var t:Structure = cast TermParse.parse( "A=B+1,B=1" );
        term( t, Structure, "(=( A, +( B, 1 ) ),=( B, 1 ))" );
        assertEquals(",", t.getName().text );
    }
    
    private function term( t:Term, type, tostring:String ) {
        assertEquals( type, Type.getClass( t ));
        assertEquals( tostring, t.toString() );    
    }
    
    private function number( t:Term, n:Float ) {
        if( ! Std.is( t, NumberTerm ) ) {
            throw new PrologError( "expected NumberTerm, got " + 
                                    Type.getClassName( Type.getClass( t ) ));
        }
        var nt:NumberTerm = cast t;
        assertEquals( n, nt.value );
    }
    
    private function makeParser( text:String ) {
        var ops:Operators = new Operators();
        ops.addStandardOps();
        var parser:Parser = new Parser( AtomContext.GLOBALS, ops, text );            
        return parser;
    }

}