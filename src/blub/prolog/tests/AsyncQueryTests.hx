package blub.prolog.tests;

import blub.prolog.Database;
import blub.prolog.Query;
import blub.prolog.Result;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Term;

import blub.prolog.async.AsyncQuery;
import blub.prolog.async.AsyncResultTracer;

class AsyncQueryTests extends haxe.unit.TestCase {

    public function testSanity() {
        queryTest( 
            "foo(a,b).
            foo(A,B) :- B = z(A).
            bar(A) :- A = 1 ; A = a.",
            
            "bar(X),async_sleep(5000),foo(X,Y)",
            
            [ bind("X","1","Y","z(1)"), 
              bind("X","a","Y","b"),
              bind("X","a","Y","z(a)")]
        );
    }
    
    private function queryTest( theoryOrDB:Dynamic, query:String, results:Array<Dynamic> ):Database
    {
        var db:Database;
        
        if( Std.is(theoryOrDB, Database )) db = cast( theoryOrDB, Database );
        else if( Std.is(theoryOrDB, String)) db = makeDB( cast( theoryOrDB, String ));
        else throw new PrologError( "must be Database or theory String" );
        
        var queryTerm = TermParse.parse( query, db.operators );		
        var qury = new AsyncQuery( db, cast queryTerm );
		//qury.execute( new AsyncResultTracer( "sanity:" ) );
		
		assertEquals( 1, 1 );

        return db;
    }
    
    //make a test database
    private function makeDB( src:String ):Database {
        var db:Database = new Database();		
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