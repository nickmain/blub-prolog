package blub.prolog;

/**
 * Base for Prolog errors
 */
class PrologError {
    public var message(default,null):String;    
    
    public function new( msg:String ) { this.message = msg; }
    
    public function toString():String { return message; }
}