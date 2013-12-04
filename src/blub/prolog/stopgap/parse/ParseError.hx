package blub.prolog.stopgap.parse;

class ParseError extends blub.prolog.PrologError {

    public var origin(default,null):String;
    public var line  (default,null):Int;
    public var col   (default,null):Int;
    
    public function new( msg:String, origin:String, line:Int, col:Int ) {
        super( msg );
        this.origin = origin;
        this.line   = line;
        this.col    = col;
    }

    override public function toString():String {
        return origin + "<" + line + ":" + col + "> " + this.message;
    }
}