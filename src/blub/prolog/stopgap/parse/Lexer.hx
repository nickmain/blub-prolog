package blub.prolog.stopgap.parse;

import blub.prolog.stopgap.parse.Token;

/**
 * Prolog lexer
 */
class Lexer {

    private var buffer:Array<Char>;
    private var token:Array<Char>;
    
    private var text:String;
    private var origin:String;

    /**
     * Read from the given string
     * 
     * @param origin the origin of the text - example: a file name
     */
    public function new( text:String, ?origin:String = "<unknown>", ?line:Int = 1, ?col:Int = 1 ) {
        this.text   = text;
        this.origin = origin;
        
        buffer = new Array<Char>();
        
        sanitize();
        readAllChars( line, col );
    }
    
    
    /**
     * Read the next token
     * 
     * @param skipWS true to skip leading whitespace
     * @return type=EOF if no more tokens are available
     * @throw ParseError if there is a lexical error in the source text
     */
    public function next( ?skipWS:Bool = true ) {
        token = new Array<Char>();
        
        if( skipWS ) this.skipWS(); 
        if( buffer.length == 0 ) return new Token( token_eof, token );  
        
        var type:String;

        while( isCommentStart() ) skipComment();
                
        var ch:Char = buffer[0];

        if( ch.isWhitespace() ) return gatherWS();
        if( ch.isUnderscore() || ch.isUppercase() ) return gatherVar();
        
        if( ch.isDigit()) return gatherNumber();
                    
        //detect end of term
        if( ch.isPeriod()
         && (buffer.length == 1
            || buffer[1].isWhitespace()
            || buffer[1].isLineComment()
            || (buffer.length > 2 
                && buffer[1].isSlash() 
                && buffer[2].isAsterisk()))) {
            token.push( buffer.shift() );
            return new Token( token_term_end, token );
        }

        if( ch.isOpChar()      ) return gatherOp();
        if( ch.isLowercase()   ) return gatherAtom();               
        if( ch.isSingleQuote() ) return gatherQuotedAtom(); 
        if( ch.isDoubleQuote() ) return gatherString();
        
        if( ch.isComma()        ) return one( token_atom );
        if( ch.isSemicolon()    ) return one( token_atom );
        if( ch.isExclamation()  ) return one( token_atom ); //the "cut"
        if( ch.isBar()          ) return one( token_atom );
        if( ch.isOpenParen()    ) return one( token_open_paren );
        if( ch.isCloseParen()   ) return one( token_close_paren );
        if( ch.isOpenBrace()    ) return one( token_open_brace );
        if( ch.isCloseBrace()   ) return one( token_close_brace );
        if( ch.isOpenBracket()  ) return one( token_open_bracket );
        if( ch.isCloseBracket() ) return one( token_close_bracket );
		
        throw new ParseError( "unrecognized character '" + ch.value + "'", origin, ch.line, ch.col );
    }

    //gather a quoted string - without the quotes 
    private function gatherString():Token {
        var start:Char = buffer.shift(); //drop initial doublequote
        var end:Char = null;
        
        while( true )
        {
            if( buffer.length == 0 ) 
            {
                var last:Char = token.pop();
                throw new ParseError( "unterminated string", origin, last.line, last.col );
            }
            
            //handle single-char escape sequences
            if( buffer[0].isBackslash() && buffer.length > 1 )
            {
                token.push( buffer.shift() );
                token.push( buffer.shift() );
                continue;                   
            }

            if( buffer[0].isDoubleQuote())
            {
                end = buffer.shift();
                break;
            }
                            
            //any old char
            token.push( buffer.shift() );
        }
        
        return new Token( token_string, token, start, end );
    }
    
    /**
     * Read char from buffer and decode escape chars
     * 
     * NOTE: does not handle octal escapes
     * 
     * @return null if eof
     */
    private function escapeReadChar():Char {
        if( buffer.length == 0 ) return null;
        
        var ch = buffer.shift();
        
        if( ch.isBackslash() ) {
            if( buffer.length == 0 ) throw new ParseError( "bad character escape", origin, ch.line, ch.col );
            
            var ch2:Char = buffer.shift();
            
            switch( ch2.value ) {
                case "a": ch.value = "\x07";
                case "b": ch.value = "\x09";
                case "f": ch.value = "\x0C";
                case "n": ch.value = "\n";
                case "r": ch.value = "\r";
                case "t": ch.value = "\t";
                case "v": ch.value = "\x0b";                     
                case "\\": ch.value = "\\";
                case "'":  ch.value = "'";
                case "`": ch.value = "`";
                case "\"": ch.value = "\"";

                case "X", "x": {
                    var s = "0x";
                    while( true )
                    {
                        if( buffer.length == 0 ) throw new ParseError( "unterminated escape char", origin, ch2.line, ch2.col );
                        
                        ch2 = buffer.shift();
                        if( ch2.isDigit() ) {
                            s += ch2.value;
                            continue;
                        }

                        if( ch2.isBackslash() ) {                               
                            var code = Std.parseInt(s);                                
                            ch.value = String.fromCharCode( code );                             
                            break;
                        }
                        
                        throw new ParseError( "non-digit in hex escape char", origin, ch2.line, ch2.col );
                    }
                }
                    
                default: throw new ParseError( "bad character escape", origin, ch.line, ch.col );
            }
        }
        
        return ch;
    }
    
    //gather a quoted atom 
    //NOTE: char code escapes are not handled
    //NOTE: end-of-line escapes are not enforced
    private function gatherQuotedAtom():Token {
        //token.push( buffer.shift() );
		buffer.shift(); //drop the quote
        
        while( true )
        {
            if( buffer.length == 0 ) 
            {
				var buf = new StringBuf();
                for( c in token ) buf.add( c.value );
				
                var last:Char = token.pop();
                throw new ParseError( "unterminated atom: " + buf, origin, last.line, last.col );
            }
            
            //handle single-char escape sequences
            if( buffer[0].isBackslash() && buffer.length > 1 )
            {
				buffer.shift(); //drop slash
				var escChr = buffer.shift();
				
				escChr.value = 
				switch( escChr.value ) {
					case "n" : "\n";
					case "r" : "\r";
					case "t" : "\t";
					case "\\": "\\";
					default:   "\\" + escChr.value;
				};
				
				token.push( escChr );
				
                continue;                   
            }
            
            if( buffer[0].isSingleQuote())
            {
                //double single quotes
                if( buffer.length > 1 && buffer[1].isSingleQuote() )
                {
                    token.push( buffer.shift() );
                    buffer.shift();
                    continue;
                }

                //token.push( buffer.shift() );
                buffer.shift(); //drop the quote

                break;
            }

            //any old char
            token.push( buffer.shift() );
        }
        		
        return new Token( token_atom, token );
    }
    
    //gather only atom chars
    private function gatherAtom():Token
    {
        token.push( buffer.shift() );
        
        while( buffer.length > 0 && buffer[0].isAtomChar() )
        {
            token.push( buffer.shift() );
        }
        
        return new Token( token_atom, token );
    }
    
    //gather only operator chars
    private function gatherOp():Token
    {
        while( buffer.length > 0 && buffer[0].isOpChar() )
        {
            token.push( buffer.shift() );
        }
        
        return new Token( token_atom, token );
    }
    
    /** 
     * Gather a number. 
     * NOTE: not supporting octal
     * NOTE: not supporting binary
     */
    private function gatherNumber():Token
    {
        var ch:Char = buffer.shift();
        token.push( ch );           
        
        var type:TokenType = token_int;
        
        //check for hex signifier
        if( ch.isZero() && buffer.length > 0 && buffer[0].isHexX() )
        {
            token.push( buffer.shift() );
            return gatherHex(); 
        }
        
        gatherDigits();
        
        //decimal point
        if( buffer.length > 1 && buffer[0].isPeriod() && buffer[1].isDigit() ) 
        {
            type = token_float;
            token.push( buffer.shift() );
            gatherDigits();
        }
                    
        //exponent
        if( buffer.length > 1 && buffer[0].isExponentE()
          && (buffer[1].isDigit()
              || (buffer.length > 2 && buffer[1].isNumericSign() && buffer[2].isDigit())))
        {
            type = token_float;
            token.push( buffer.shift() ); //consume the E
            if( buffer[0].isNumericSign()) token.push( buffer.shift() ); //consume sign
            gatherDigits();
        }
        
        //following a number must not be a letter or underscore
        if( buffer.length > 0 
            && (buffer[0].isLetter() || buffer[0].isUnderscore()))
        {
            throw new ParseError( "invalid char after a number '" + buffer[0].value + "'", origin, buffer[0].line, buffer[0].col );
        }
        
        return new Token( type, token );
    }       

    //gather only digits
    private function gatherDigits() {
        while( buffer.length > 0 && buffer[0].isDigit() )
        {
            token.push( buffer.shift() );
        }           
    }
    
    //gather only hex digits
    private function gatherHex():Token
    {
        while( buffer.length > 0 && buffer[0].isHexDigit() )
        {
            token.push( buffer.shift() );
        }
        
        return new Token( token_int, token );
    }
    
    /** Make a one char token of the given type */
    private function one( type:TokenType ):Token
    {
        token.push( buffer.shift() );
        return new Token( type, token );
    }
    
    /** Gather a variable */
    private function gatherVar():Token
    {
        while( buffer.length > 0 && buffer[0].isVarChar() )
        {
            token.push( buffer.shift() );
        }
        
        return new Token( token_variable, token );
    }       
    
    /** Gather whitespace */
    private function gatherWS():Token
    {
        while( buffer.length > 0 && buffer[0].isWhitespace() )
        {
            if( isCommentStart() ) skipComment(); 
            token.push( buffer.shift() );
        }
        
        return new Token( token_whitespace, token );
    }       
    
    /** Skip over leading whitespace */
    private function skipWS() {
        while( buffer.length > 0 
            &&( buffer[0].isWhitespace() || isCommentStart()))
        {
            if( isCommentStart() ) {
				skipComment();
				continue; 
			}
			
            buffer.shift();
        }
    }
    
    /** Whether head of buffer is a comment */
    private function isCommentStart() {
        if( buffer.length > 0 && buffer[0].isLineComment() ) return true;
        if( buffer.length > 1 && buffer[0].isSlash() && buffer[1].isAsterisk() ) return true;
        return false;
    }
    
    /**
     * Skip over a comment
     */
    private function skipComment() {
        if( buffer[0].isLineComment() ) {
            skipToEndOfLine();
        }
        else
        {
            while( buffer.length > 0 )
            {
                if( buffer.shift().isAsterisk()
                    && buffer.length > 0 
                    && buffer[0].isSlash() ) {
                    
                    buffer.shift();
                    break;
                }
            }                           
        }           
    }
    
    private function skipToEndOfLine() {
        while( buffer.length > 0 )
        {
            if( buffer.shift().isNewline() ) break;
        }           
    }
    
    /**
     * Sanitize the text to remove malformed line-ends 
     */
    private function sanitize() {
        text = StringTools.replace( text, "\r\n", "\n" );
        text = StringTools.replace( text, "\r", "\n" );
    }
    
    /** Read all chars from the input text into the Char buffer */ 
    private function readAllChars( line:Int, col:Int ) {
        for( i in 0...text.length ) {
            var c = new Char( line, col, text, i );
            
            if( c.isNewline() ) {
                line++;
                col = 1;
            }
            else col++;
            
            buffer.push( c );
        }
    }    
    
}