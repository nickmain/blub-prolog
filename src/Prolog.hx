import blub.prolog.Database;
import blub.prolog.Query;
import blub.prolog.Result;

/**
 * A simple string-in, array-of-map interface for using the Prolog engine from
 * Javascript
 */
@:expose
class Prolog {

    var db:Database;

    /**
     * Create a new Prolog database and load the given theory
     */
    public function new( theory:String ) {
        db = new Database();        
        db.loadString( theory, true );
    }

    /**
     * Perform the given query and return a JS array of result bindings for the
     * given variable name
     */
    public function query( queryTerm:String, resultVarName:String ):Dynamic {
		var q:Query = db.query( queryTerm );
		var results = q.allBindings();
		
		var values = new Array();
		for( result in results ) {
			var binding = result.get( resultVarName );
			if( binding != null ) values.push( binding.asAtom().text );
		}
		return values;
	}

    public static function main() {
	   //nothing
	}
}
