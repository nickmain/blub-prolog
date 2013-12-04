package blub.prolog.builtins.display;

import blub.prolog.builtins.BuiltinPredicate;

class DisplayBuiltins {

    public static function get():Array<BuiltinPredicate> {
        return cast [ 
		#if !java
			new Sprite(),
			new KillSprite(),
			new ReceiveEvent()
		#end               
        ];
    }

}
