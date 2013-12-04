package blub.prolog.builtins.async;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;
import blub.prolog.builtins.async.AsyncOperation;

/**
 * Sleep for a given number of millisecs and then continue.
 * This is an asynchronous predicate.
 */
class Sleep extends BuiltinPredicate {

    public function new() {
		super( "sleep", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var time = args[0].toValue(env).asNumber();
		 
		if( time == null ) {
			engine.raiseException( 
			    RuntimeError.typeError( 
				    TypeError.VALID_TYPE_number, time, engine.context ) );
		}
				
		var millis = Std.int( time.value );
        engine.beginAsync( new AsyncOperationImpl( "sleep(" + millis + ")", null ));				
				
	    //sleep then resume..
		haxe.Timer.delay( function() { engine.continueAsync(); }, millis );
	}
}
