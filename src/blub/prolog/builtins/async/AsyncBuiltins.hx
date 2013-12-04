package blub.prolog.builtins.async;

import blub.prolog.builtins.BuiltinPredicate;

class AsyncBuiltins {

    public static function get():Array<BuiltinPredicate> {
		
		//make send/receive pair with shared channels
		var send = new blub.prolog.builtins.async.messages.Send();
		var receive = new blub.prolog.builtins.async.messages.Receive( send.channels );
		
        return cast [ 
            new Sleep(),
			send,
			receive,
			new Spawn(),
			new Spawns(),
			new Stop() 
        ];
    }

}
