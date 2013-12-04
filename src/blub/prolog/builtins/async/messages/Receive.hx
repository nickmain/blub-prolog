package blub.prolog.builtins.async.messages;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;

import blub.prolog.builtins.async.AsyncOperation;

/**
 * Receive a message.
 * Arg[0] is atom indicating the channel for the message.
 * Arg[1] is ground term to unify against message 
 * Incoming message must unify with the second arg - otherwise it is ignored.
 * 
 * This is an asynchronous predicate.
 */
class Receive extends BuiltinPredicate {

    var channels:Map<String,MessageChannel>;

    public function new( channels:Map<String,MessageChannel> ) {
		super( "receive", 2 );
		
		this.channels = channels;
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

        var msgChannel = channels.get( channel.text );
        if( msgChannel == null ) {
            msgChannel = new MessageChannel( channel.text, channels );
        }
        
		var listener = msgChannel.listen( engine, msg );
		
		//receive
        engine.beginAsync( new AsyncOperationImpl( "receive(" + channel.text + "," + msg.toString + ")",
            //cancel the listener
            function() {
				msgChannel.unlisten( listener );
            }
        ));
	}
}
