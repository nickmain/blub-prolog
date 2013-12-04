package blub.prolog.tests;

import blub.prolog.Database;
import blub.prolog.Result;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Variable;

class UnificationTests extends haxe.unit.TestCase {

    public function testAtoms() {
        //trace( "\nUnify Atoms.." );

        var t1:ValueTerm = cast TermParse.parse( "foo." );
        var t2:ValueTerm = cast TermParse.parse( "foo." );
        var t3:ValueTerm = cast TermParse.parse( "'foo'." );
        var t4:ValueTerm = cast TermParse.parse( "bar." );
        var t5:ValueTerm = cast TermParse.parse( "bar(foo)." );
        var t6:ValueTerm = cast TermParse.parse( "34." );
        var t7:ValueTerm = cast TermParse.parse( "A." );
        
        assertTrue( t1.unify( t2 ));  
        assertTrue( t2.unify( t1 ));
        
        assertTrue( t1.unify( t3 ));

        assertFalse( t1.unify( t4 ));
        assertFalse( t4.unify( t1 ));
        assertFalse( t4.unify( t5 ));
        assertFalse( t4.unify( t6 ));
        
        assertTrue( t6.unify( t7, bind( "A", new NumberTerm(34)) ));
        
        var out:Map<String,Term> = new Map<String,Term>();
        assertTrue( t6.unify( t7, new Map<String,Term>(), out ));
        assertTrue( Std.is(out.get("A"), NumberTerm ));
        assertEquals( cast(out.get("A"), NumberTerm).value , 34 );
    }
    
    public function testStructs() {
        //trace( "\nUnify Structs.." );
        
        var t1:ValueTerm = cast TermParse.parse( "foo(bar,23)." );
        var t2:ValueTerm = cast TermParse.parse( "foo(bar,23.0)." );
        var t3:ValueTerm = cast TermParse.parse( "foo(bar(foo))." );
        var t4:ValueTerm = cast TermParse.parse( "foo(bar(foo))." );
        var t5:ValueTerm = cast TermParse.parse( "(1,2)." );
        var t6:ValueTerm = cast TermParse.parse( "'()'(','(1,2))." );
        var t7:ValueTerm = cast TermParse.parse( "foo(bar)." );
        var t8:ValueTerm = cast TermParse.parse( "foo(bar(A))." );

        assertTrue( t1.unify( t2 ));  
        assertTrue( t2.unify( t1 ));

        assertTrue( t3.unify( t4 ));  

        assertTrue( t5.unify( t6 ));  
        
        assertFalse( t1.unify( t7 ));
        
        assertTrue( t3.unify( t8, bind("A", new Atom("foo")) ));
        
        var out:Map<String,Term> = new Map<String,Term>();
        assertTrue( t3.unify( t8, new Map<String,Term>(), out ));
        assertTrue( Std.is(out.get("A"), Atom ));
        assertEquals( cast(out.get("A"), Atom).text, "foo" );
    }

    //this is a problem that was encountered while debugging..
    public function testStructs2() {
        //trace( "\nUnify Structs 2.." );
        
        var zA:ValueTerm = cast TermParse.parse( "z(A)" );
        var t :ValueTerm = cast TermParse.parse( "X" );

        var tBinds:Map<String,Term> = new Map<String,Term>();
        var zABinds:Map<String,Term> = bind("A",new NumberTerm(1));
        
        assertTrue( t.unify( zA, tBinds, zABinds ));
        
        //now X=z(A) but A should also have been resolved           
        //trace( Result.bindingsToString( tBinds ));
        
        assertTrue( Std.is(tBinds.get("X"), Structure ));
        assertTrue( cast(tBinds.get("X"), Term).equals( TermParse.parse( "z(1)" )) );
    }
    
    //another bug..
    public function testUnifyVarAndStructWithVar() {
        //trace( "\nVar=foo(Var).." );
        
        var varA  :Term = TermParse.parse( "A" );
        var struct:Term = TermParse.parse( "foo(A)" );
        
        var bindsA:Map<String,Term> = new Map<String,Term>();
        var bindsS:Map<String,Term> = new Map<String,Term>();
        
        assertTrue( varA.unify( struct, bindsA, bindsS ));
        
        //trace( "bindsA->" + Result.bindingsToString( bindsA ));
        //trace( "bindsS->" + Result.bindingsToString( bindsS ));
        
        assertEquals( "foo", cast(bindsA.get("A"), Structure).functor.text );
        
        var subVar:String = cast( cast(bindsA.get("A"), Structure).args[0], Variable).name; 
        assertTrue( subVar != "A" );
        assertEquals( subVar, cast(bindsS.get("A"), Variable).name );
    }
    
    public function testLists() {
        //trace( "\nUnify Lists.." );
        
        var t1:Term = TermParse.parse( "[1, 2, 3]." );
        var t2:Term = TermParse.parse( "[1, 2 | [3]]." );
        
        assertTrue( t1.unify( t2 ));  

        var t3:Term = TermParse.parse( "[1, 2, A]." );
        
        assertTrue( t1.unify( t3, bind("A", new NumberTerm(3)) ));  
    }

    public function testVars() {
        //trace( "\nUnify Vars.." );

        var a :Variable = new Variable("A");
        var a2:Variable = new Variable("A");
        var b:Variable = new Variable("B");
        var c:Variable = new Variable("C");
        var d:Variable = new Variable("D");
        
        var out:Map<String,Term> = new Map<String,Term>();
        var out2:Map<String,Term> = new Map<String,Term>();

        assertTrue( a.unify( a2 ) );
                
        assertTrue( a.unify( b ) );
        assertTrue( a.unify( b, bind("B",new Atom("foo")) ) );
        assertTrue( a.unify( b, out, bind("B",new Atom("foo")) ) );
        assertEquals( "foo", cast(out.get("A"), Atom).text );
        assertTrue( a.unify( b, bind("A",new Atom("foo")),bind("B",new Atom("foo")) ) );
        assertFalse( a.unify( b, bind("A",new Atom("foo")),bind("B",new Atom("bar")) ) );

        assertTrue( a.unify( b, bind("A",new Atom("foo")),bind("B",c,"C",new Atom("foo")) ) );
        assertFalse( a.unify( b, bind("A",new Atom("foo")),bind("B",c,"C",new Atom("bar")) ) );
        
        out = new Map<String,Term>();
        out2 = new Map<String,Term>();
        a.unify( b, out, out2 );
        
        assertTrue( Std.is(out.get("A"), Variable )); 
        assertTrue( Std.is(out2.get("B"), Variable )); 
        assertTrue( out.get("A") == out2.get("B") );         
    }
    
    public function testResolve() {
        //test that variable resolution chases multiple levels
        var A:Variable = new Variable( "A" );
        var B:Variable = new Variable( "B" );
        var C:Variable = new Variable( "C" );
        var n:NumberTerm = new NumberTerm( 23 );
        
        assertTrue( A.resolve( bind("A",n) ).equals( n ));    
        assertTrue( A.resolve( bind("A",B,"B",n) ).equals( n ));    
        assertTrue( A.resolve( bind("A",B,"B",C,"C",n) ).equals( n ));    
    }
    
    private function bind( key, term, ?key2, ?term2, ?key3, ?term3 ) {
        var hash = new Map<String,Term>();
        hash.set( key, term );
        if( key2 != null ) hash.set( key2, term2 );
        if( key3 != null ) hash.set( key3, term3 );
        return hash;
    }
}