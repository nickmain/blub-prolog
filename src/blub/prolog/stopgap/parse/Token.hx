package blub.prolog.stopgap.parse;

/**
 * A Prolog token
 */
class Token {

    public var startLine(default,null):Int;
    public var startCol (default,null):Int;
    public var endLine  (default,null):Int;
    public var endCol   (default,null):Int;     
    
    public var value(default,null):Dynamic;  //Int, Float, String
    public var type (default,null):TokenType;
    
    public function new( type:TokenType, chars:Array<Char>, ?start:Char, ?end:Char ) {
        this.type = type;        
        if( type == token_eof ) return; 
        
        if( start == null ) start = chars[0];
        if( end   == null ) end   = chars[chars.length-1];
        
        startLine = start.line;
        startCol  = start.col;
        endLine   = end.line;
        endCol    = end.col;

        var s = chars.join("");
        
        if     ( type == token_int   ) value = Std.parseInt( s );
        else if( type == token_float ) value = Std.parseFloat( s );
        else value = s;
    }
    
    public function toString() {
        return type + " [" + startLine + ":" + startCol + "-" + 
               endLine + ":" + endCol + "] = '" + value + "'";  
    }
}

enum TokenType {
	token_variable;
	token_atom;
	token_int;
	token_float;
	token_whitespace;
	token_string;
	token_term_end;
	token_eof;
	token_open_paren;
	token_close_paren;
	token_open_brace;
	token_close_brace;
	token_open_bracket;
	token_close_bracket;
}