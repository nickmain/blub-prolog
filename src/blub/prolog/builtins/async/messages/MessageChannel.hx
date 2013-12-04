package blub.prolog.builtins.async.messages;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.builtins.BuiltinPredicate;
import blub.prolog.util.DLList;

class MessageChannel {
	
	var name:String;
	var channels:Map<String,MessageChannel>;
	var listeners:DLList<MessageListener>;
	
	public function new( name:String, channels:Map<String,MessageChannel> ) {
		this.name = name;
		this.channels = channels;
		
		listeners = new DLList<MessageListener>();
		
		channels.set( name, this );
	}
	
	/** Listen for a message - return a token for unlisten */
	public function listen( engine:QueryEngine, term:ValueTerm ):Dynamic {
		return listeners.append( new MessageListener( engine, term ) );
	}
	
	/** Unlisten */
	public function unlisten( token:Dynamic ) {
		if( token == null ) return;
		if( Std.is( token, Entry ) ) {
			var entry:Entry<MessageListener> = cast token;
			token.remove();
			
            if( listeners.size == 0 ) {
                channels.remove( name );
            }
		}
	}
	
	/** Send a message */
	public function send( msg:ValueTerm ) {
		for( listener in listeners.entries ) {
			if( listener.item.receive( msg ) ) listener.remove();
		}
		
		//clean up self if all listeners went away
		if( listeners.size == 0 ) {
			channels.remove( name );
		}
	}	
}

class MessageListener {
	var engine:QueryEngine;
	var term:ValueTerm;
	
	public function new( engine:QueryEngine, term:ValueTerm ) {
		this.engine = engine;
		this.term   = term;
	}
	
	/** Attempt to receive the message - return true if successful */
	public function receive( msg:ValueTerm ):Bool {
		var bindings = engine.bindings;
		if( ! term.unify( msg, engine )  ) {
			engine.undoBindings( bindings );
			return false;
		}
		
		engine.continueAsync();
		return true;
	}
}