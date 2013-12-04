package blub.prolog.tests;
import haxe.unit.TestCase;
import blub.prolog.Database;
import blub.prolog.Query;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Variable;
import blub.prolog.terms.Structure;

/**
 * Base for test cases that run a prolog query
 */
class PrologTestCase extends TestCase {

    function new() { super(); }

    /**
     * Load the given source into a Database and call the query "test(Msg)".
     */
    function query( source:String ) {
		var db = new Database();
		db.loadString( source );
		var query = new Query( db, Structure.make( Atom.unregisteredAtom("test"), new Variable("Msg") ));
		var bindings = query.allBindings();
		if( bindings == null ) {
			assertEquals("Pass","Prolog query failed");
			return;
		}
		for( bind in bindings ) {
			var msg = bind.get( "Msg" );
			if( msg.asValueTerm() != null ) {				
				assertEquals("Pass", msg.toString() );
			}
		}
		
		assertTrue(true); //to keep the test framework happy.
	}

}
