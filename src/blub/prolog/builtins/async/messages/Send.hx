package blub.prolog.builtins.async.messages;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;

/**
 * Send or a message.
 * Arg[0] is atom indicating the channel for the message.
 * Arg[1] is ground term to send 
 * 
 * This is NOT an asynchronous predicate.
 */
class Send extends BuiltinPredicate {

    public var channels (default,null):Map<String,MessageChannel>;

    public function new() {
		super( "send", 2 );
		
		channels = new Map<String,MessageChannel>();
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var channel = args[0].toValue(env).asAtom();
		var msg     = args[1].toValue(env).dereference();
		 		
		if( channel == null ) {
			engine.raiseException( 
			    RuntimeError.typeError( 
				    TypeError.VALID_TYPE_atom, channel, engine.context ) );
		}

        //send
        if( msg.isGround() ) {
			var msgChannel = channels.get( channel.text );
			if( msgChannel == null ) return;
			msgChannel.send( msg );
			return; 
		}
		
		//non-ground
	    engine.raiseException( RuntimeError.instantiationError( engine.context ) );		
	}
}
