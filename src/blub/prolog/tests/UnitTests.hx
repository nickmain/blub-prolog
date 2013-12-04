package blub.prolog.tests;
import Main;

import blub.prolog.tests.SanityTests;
import blub.prolog.tests.LexerTests;
import blub.prolog.tests.ParserTests;
import blub.prolog.tests.LoaderTests;
import blub.prolog.tests.QueryTests;
import blub.prolog.tests.AsyncQueryTests;

#if js
import blub.prolog.debug.HtmlStepper;
import blub.prolog.tests.ExampleTheories;
#end

class UnitTests {
    static var tests:Array<Class<haxe.unit.TestCase>> = [
	      SanityTests
/** */     		  
        , LexerTests
		, ParserTests
		, LoaderTests
		, QueryTests
		, AsyncQueryTests

/** * /		
        , ObjectManagerTests
        , EightQueensTest
        , ConstraintTest
        , UnificationTests
        , UtilTests 
//*/
    ];

    public static function main() {
        var r = new haxe.unit.TestRunner();
        for( test in tests ) r.add( Type.createInstance( test, [] ) );        
        r.run();
    }
}
