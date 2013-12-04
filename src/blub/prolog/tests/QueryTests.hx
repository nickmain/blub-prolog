package blub.prolog.tests;

import blub.prolog.Database;
import blub.prolog.Predicate;
import blub.prolog.Query;
import blub.prolog.Result;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Term;

import haxe.ds.StringMap;

class QueryTests extends haxe.unit.TestCase {

    private function dump( s:String ) { trace(s); }
    private var traceTest:Bool;       
	private var dumpCompile:Bool; 
			
    public function testSanity() {
        //trace( "\nSanity Query.." );
        //dump;
            
        queryTest( 
            "foo(a,b).
            foo(A,B) :- B = z(A).
            bar(A) :- A = 1 ; A = a.",
            
            "bar(X),foo(X,Y)",
            
            [ bind("X","1","Y","z(1)"), 
              bind("X","a","Y","b"),
              bind("X","a","Y","z(a)")]
        );
    }

    /**
     * This was a bug where a cut in a single clause predicate would leak upwards.
     */
    public function testCutInSingleClause() {
        queryTest( 
           "foo(1).
            foo(2).
            foo(3).
            foo(4).
            
            bar(A,B) :- (A > B ; A is B * 2).",
            
			"foo(A),foo(B),bar(A,B)",
			
            [ bind("A","2","B","1"), 
              bind("A","2","B","1"),
              bind("A","3","B","1"),
              bind("A","3","B","2"),
              bind("A","4","B","1"),
              bind("A","4","B","2"),
              bind("A","4","B","2"),
              bind("A","4","B","3")]
        );
		
		//add the cut to remove duplicate pairs
        queryTest( 
           "foo(1).
            foo(2).
            foo(3).
            foo(4).
            
            bar(A,B) :- (A > B ; A is B * 2), !.",
            
            "foo(A),foo(B),bar(A,B)",
            
            [ bind("A","2","B","1"), 
              bind("A","3","B","1"),
              bind("A","3","B","2"),
              bind("A","4","B","1"),
              bind("A","4","B","2"),
              bind("A","4","B","3")]
        );		
	}

    public function testAppend() {
        //trace( "\nAppend.." );
        
        
        queryTest( 
            "append([],L,L). 
            append([H|T],L2,[H|L3]) :- append(T,L2,L3). ",
            
            "append([1,2,3],[a,b,c],X)",
            
            [bind("X","[1,2,3,a,b,c]")]
        );
        
        queryTest( 
            "append([],L,L).
            append([H|T],L2,[H|L3]) :- append(T,L2,L3). ",
            
            "append([1,2,3],X,[1,2,3,a,b,c])",
            
            [bind( "X","[a,b,c]" )]
        );
        
        queryTest( 
            "append([],L,L).
            append([H|T],L2,[H|L3]) :- append(T,L2,L3). ",
            
            "append([1,2,3],[a,X,c],[1,2,3,a,b,c])",
            
            [bind( "X", "b" )]
        );
    }
 
    public function testCut() {
        //trace( "\nCut Query.." );
        
        
        queryTest( 
            "foo(a,b).
            foo(A,B) :- B = z(A).
            bar(A) :- A = a ; A = 1.",
            
            "bar(X),!,foo(X,Y)",
            
            [bind( "X","a", "Y","b" ),
             bind( "X","a", "Y","z(a)" )]
        );
        
        queryTest( 
            "foo(a,b) :- !.
            foo(A,B) :- B = z(A).
            bar(A) :- A = 1 ; A = a.",
            
            "bar(X),foo(X,Y)",

            [bind( "X","1", "Y","z(1)" ),
             bind( "X","a", "Y","b" )]
        );
    }
    
    public function testAddition() {
        //trace( "\nAddition.." );
        
        
        queryTest( 
            "foo(1). foo(2). foo(3). ",
            
            "foo(X),Y is X+2",
            
            [bind( "X", "1", "Y", "3" ),
             bind( "X", "2", "Y", "4" ),
             bind( "X", "3", "Y", "5" )]
        );
        
        queryTest( 
            "",
            
            "A=B+C , C=1 , B=2 , Y is A",
            
            [bind( "A", "2+1", "B", "2", "C", "1", "Y", "3" )]            
        );
    }

    public function testSubtraction() {
        //trace( "\nSubtraction.." );
        
        
        queryTest( "", "A is 2 - 3",      [bind("A", "-1")]);
        queryTest( "", "A is 2 - 3 +4",   [bind("A", "3")]);
        queryTest( "", "A is 2 - (3 +4)", [bind("A", "-5")]);
    }

    public function testMultDiv() {
        //trace( "\nMult + Div .." );
        
        
        queryTest( "", "A is 2 * 3",       [bind("A", "6")]);
        queryTest( "", "A is 2 * 3 /4",    [bind("A", "" + (6/4))]);
        queryTest( "", "A is 2 * (3 / 4)", [bind("A", "" + (2*(3/4)))]);
    }

    public function testSquaredOp() {
        //trace( "\nSquared Operator .." );
        
        
        queryTest( 
            ":- op(300,xfx,squared).
            A squared B :- A is B * B. ",
            
            "A squared 3", 
            [bind("A", "9")]);
    }

    public function testArithEqual() {
        queryTest( "", "6 =:= 2 * 3", [true]);
        queryTest( "", "2 * 3 =:= 6", [true]);
        queryTest( "", "6 =:= 2 * 2", [false]);
        
        queryTest( "", "A is 3 + 3, A =:= 2 * 3", [bind("A", "6")]);
        queryTest( "", "A is 3 + 3, B is 3 *2, A=:=B", [bind("A", "6", "B", "6")]);
    }

    public function testArithNotEqual() {
        queryTest( "", "7 =\\= 2 * 3", [true]);
        queryTest( "", "2 * 3 =\\= 6.01", [true]);
        queryTest( "", "6 =\\= 2 * 3", [false]);
    }

    public function testArithGreaterThan() {
        queryTest( "", "7 > 2 * 3", [true]);
        queryTest( "", "2 * 3 > 5.99", [true]);
        queryTest( "", "6 > 2 * 3", [false]);
    }

    public function testArithLessThan() {
        queryTest( "", "5.99 < 2 * 3", [true]);
        queryTest( "", "2 * 3 < 6.01", [true]);
        queryTest( "", "6 < 2 * 3", [false]);
    }

    public function testArithGreaterEqual() {
        queryTest( "", "7 >= 2 * 3", [true]);
        queryTest( "", "6 >= 2 * 3", [true]);
        queryTest( "", "5.99 >= 2 * 3", [false]);
    }

    public function testArithLessEqual() {
        queryTest( "", "5.99 =< 2 * 3", [true]);
        queryTest( "", "2 * 3 =< 6", [true]);
        queryTest( "", "6.01 =< 2 * 3", [false]);
    }

    public function testNested() {
		//traceTest = true;
		//dumpCompile = true;
		
        queryTest( 
            "foo(A,D) :- bar(A,B),(bar(B,C);C is B*3),D is C + 1. 
             bar(1,2). 
             bar(2,3). ",
            
            "foo(A,D)",
            
            [bind( "A","1", "D","4" ),
             bind( "A","1", "D","7" ),
             bind( "A","2", "D","10" )]
        );
    }

    public function testCall() {
        //trace( "\nCall.." );
        
        
        queryTest( 
            "foo(1). foo(2). foo(3). ",
            
            "A=foo(B),call(A)",
            
            [bind( "A","foo(1)", "B","1" ),
             bind( "A","foo(2)", "B","2" ),
             bind( "A","foo(3)", "B","3" )]
        );
		
		queryTest( 
            "foo(1). ",
            
            "A=foo(D),B=(C is D),call((A,B))",
            
            [bind( "A","foo(1)", "B","(1 is 1)", "C","1" , "D","1" )]
        );
		
		//TODO: test cut barrier
    }
    
    public function testNotProvable() {
        //trace( "\nNot Provable.." );
                  
        queryTest( "foo(1). foo(2). foo(3). ", "\\+foo(2)", [false] );
        queryTest( "foo(1). foo(2). foo(3). ", "\\+foo(4)", [true] );
        queryTest( "foo(1). foo(2). foo(3). ", "\\+foo(A)", [false] );
    }
    
    public function testRepeat() {
        //trace( "\nRepeat.." );
                  
        queryTest( "", "repeat,A=1", [bind("A","1"),bind("A","1"),bind("A","1"),null] );
    }
    
    public function testOnce() {
        //trace( "\Once.." );
                  
        queryTest( 
            "foo(1). foo(2). foo(3). ",
            
            "A=foo(B),once(A)",
            
            [bind( "A","foo(1)", "B","1" )]
        );
        
        
        queryTest( 
            "foo(1). foo(2). foo(3). ",
            
            "A=foo(4),once(A)",
            
            [false]
        );
    }
    
    public function testNotUnifiable() {
        //trace( "\nNot Unifiable.." );
                  
        queryTest( "", "A \\= 2", [false] );
        queryTest( "", "A \\= B", [false] );
        queryTest( "", "B=1,A=2,A \\= B", [bind("A","2", "B","1")] );
        queryTest( "", "a \\= b", [true] );
    }

    public function testAssertA() {
        //trace( "\nAssertA.." );
                  
        var db:Database = queryTest( "
            :- dynamic foo/1.
            foo(1).", 
			"asserta(foo(2)),asserta(foo(3)),foo(A)", 
			[bind("A","1")] 
		);
		
        queryTest( db, "foo(A)", 
                   [bind("A","3"),
                    bind("A","2"),
                    bind("A","1")] );
    }

    public function testAssertZ() {
        //trace( "\nAssertZ.." );
                  
        var db:Database = queryTest( "
            :- dynamic foo/1.
            foo(1).", 
			"assertz(foo(2)),assertz(foo(3)),foo(A)", 
			[bind("A","1")] );
			
        queryTest( db, "foo(A)", 
                    [bind("A","1"),
                     bind("A","2"),
                     bind("A","3")] );
    }       
    
    public function testRetract() {
        //trace( "\nRetract.." );
                  
        var db:Database = queryTest( "foo(1). foo(2). foo(3).", "foo(A)", [bind("A","1"),bind("A","2"),bind("A","3")] );

        queryTest( db, "retract(foo(2)),foo(A)", [bind("A","1"),bind("A","2"),bind("A","3")] );
        queryTest( db, "foo(A)", [bind("A","1"),bind("A","3")] );

        queryTest( db, "retract(foo(_)),foo(A)", [bind("A","1"),bind("A","3")] );
        queryTest( db, "foo(A)", [bind("A","3")] );
    }               
    
    public function testAbolish() {
        //trace( "\nAbolish.." );
                  				  
        var db:Database = queryTest( "foo(1). foo(2). bar(3).", "foo(A),bar(B)", 
            [bind("A","1", "B","3"),bind("A","2", "B","3")] );
        
        assertTrue( db.lookup( PredicateIndicator.fromString("bar/1") ) != null );
        queryTest( db, "abolish(bar/1),foo(A),bar(B)", [bind("A","1", "B","3"),bind("A","2", "B","3")] );
        assertTrue( db.lookup( PredicateIndicator.fromString("bar/1") ) == null );
                    					
        queryTest( db, "foo(A)", [bind("A","1"),bind("A","2")] );
    }
    
    public function testIfThen() {
        //trace( "\nIf Then.." );

        queryTest( "", "true -> A=1, B=2 ", [bind("A","1", "B","2")] );
        queryTest( "", "fail -> A=1, B=2", [false] );
        
        queryTest( "", "true -> A=1 ; A=2", [bind("A","1")] );
        queryTest( "", "fail -> A=1 ; A=2", [bind("A","2")] );
        
        queryTest( "", "fail -> A=1 ; A=2 ; A=3", [bind("A","2"),bind("A","3")] );  
        queryTest( "", "fail -> A=1 ; (A=2 ; A=3)", [bind("A","2"),bind("A","3")] );  
        queryTest( "", "fail -> A=1 ; A=2 , A=3", [false] ); 
    }

    public function testSameVarUnification() {
        queryTest( "foo(a,b). bar(A,B):-foo(A,B).", "bar(A,B)", [bind("A","a","B","b")] );

        
        queryTest( "foo(a,b). bar(A,B):-foo(A,B).", "bar(A,A)", [false] );
    }
    
    public function testNullaryGoal() {
        
        queryTest( "test :- true.", "test", [true] );
    }
        
    private function queryTest( theoryOrDB:Dynamic, query:String, results:Array<Dynamic> ):Database
    {
        var db:Database;
        
        if( Std.is(theoryOrDB, Database )) db = cast( theoryOrDB, Database );
        else if( Std.is(theoryOrDB, String)) db = makeDB( cast( theoryOrDB, String ));
        else throw new PrologError( "must be Database or theory String" );
        
        var queryTerm = TermParse.parse( query, db.operators );		
        var qury = new Query( db, cast queryTerm );
		
		if( traceTest ) {
			#if query_trace
			trace( "*** QUERY TRACE ON ***" );
            qury.traceQuery = true;
            #end
            
			traceTest = false;			
		}
        
        for( expected in results ) {
            var result = qury.nextSolution();
			
            if( result == null ) {
                assertEquals( "result count expected:" + results.length, "fewer results" );
            };
            
            if( expected == null ) return db;
                
            if( Std.is( expected, Bool )) {
                assertEquals( cast(expected,Bool), ResultUtil.isSuccess(result) );
            }
            else if( Std.is( expected, StringMap )) {
                var bindings:Map<String,Term> = cast expected; 
                if( ! ResultUtil.equalsBindings( result, bindings )) { 
                    //this should fail - but it will display a more meaningful message
                    assertEquals( ResultUtil.bindingsToString( bindings ), ResultUtil.toString( result ));
                } 
                assertTrue( ResultUtil.equalsBindings(result, bindings)); //keep TestRunner happy
            }
            else {
				throw "BAD RESULT TYPE";
			}
        }
        
        var result = qury.nextSolution();
        assertTrue( result == null ); // fail( "More results than expected" ); 
        return db;
    }
    
    //make a test database
    private function makeDB( src:String ):Database {
        var db:Database = new Database();
		
		#if compile_dump
		blub.prolog.compiler.CompilerBase.dumpCompile = dumpCompile;
		dumpCompile = false;
		#end		
		
        db.loadString( src );
        return db;
    }    
    
    private function bind( key, term, ?key2, ?term2, ?key3, ?term3, ?key4, ?term4 ) {
        var hash = new Map<String,Term>();
        hash.set( key, TermParse.parse( term ));
        if( key2 != null ) hash.set( key2, TermParse.parse( term2 ));
        if( key3 != null ) hash.set( key3, TermParse.parse( term3 ));
        if( key4 != null ) hash.set( key4, TermParse.parse( term4 ));
        return hash;
    }
}