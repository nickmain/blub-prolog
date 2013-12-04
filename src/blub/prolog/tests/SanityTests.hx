package blub.prolog.tests;

import blub.prolog.terms.Term;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Atom;
import blub.prolog.stopgap.parse.Parser;
import blub.prolog.stopgap.parse.Operators;
import blub.prolog.stopgap.parse.Operator;

class SanityTests extends haxe.unit.TestCase {

    public function testSanity() {
		
		//test that DCG preprocessing is sane
        var src:String = "
foo --> bar, bar, bar.
bar --> \"bar\".
";        

        var db:Database = new Database();
        db.loadString( src );
        
        assertTrue( true );
    }
}