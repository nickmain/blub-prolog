package blub.prolog.stopgap.parse;

/**
 * A character read from a string
 */
class Char {

    public var line(default,null):Int;
    public var col (default,null):Int;
    
    public var value:String;
    public var code (default,null):Int;
    
    public static inline var OP_CHARS  :String = "#$&*+-./:<=>?@^~\\";
    public static inline var WHITESPACE:String = " \n\r\t\x0C";
    
    public function new( line:Int, col:Int, text:String, index:Int ) {
        this.line = line;
        this.col  = col;
        
        value = text.substr( index, 1 );
        code  = value.charCodeAt(0);
    }
    
    public function toString() { return value; }
    
    /** Whether is an operator char */
    public function isOpChar() {
        return OP_CHARS.indexOf( value ) >= 0;
    }

    /** Whether is an operator char */
    public static function isOpChar_( value:String ) {
        return OP_CHARS.indexOf( value ) >= 0;
    }

    /** Whether the char is a comma */
    public function isComma() {
        return value == ",";
    }

    /** Whether the char is an exclamation */
    public function isExclamation() {
        return value == "!";
    }
    
    /** Whether the char is a semicolon */
    public function isSemicolon() {
        return value == ";";
    }

    /** Whether the char is a bar */
    public function isBar() {
        return value == "|";
    }
    
    /** Whether the char is an underscore */
    public function isUnderscore() {
        return value == "_";
    }

    /** Whether the char is a single quote */
    public function isSingleQuote() {
        return value == "'";
    }

    /** Whether the char is a double quote */
    public function isDoubleQuote() {
        return value == "\"";
    }
    
    /** Whether the char is an uppercase letter */
    public function isUppercase() {
        return code >= 65 && code <= 90;
    }

    /** Whether the char is a lowercase letter */
    public function isLowercase() {
        return code >= 97 && code <= 122;
    }

    /** Whether the char is a letter */
    public function isLetter() {
        return isUppercase() || isLowercase();
    }

    /** Whether the char is valid in an atom (other than start) */
    public function isAtomChar() {
        return isUppercase() || isLowercase() || isDigit() || isUnderscore();
    }

    /** Whether the char is valid in a variable name (other than start) */
    public function isVarChar() {
        return isUppercase() || isLowercase() || isDigit() || isUnderscore();
    }
    
    /** Whether the char is a decimal digit */
    public function isDigit() {
        return code >= 48 && code <= 57;
    }

    /** Whether the char is a hex digit */
    public function isHexDigit() {
        return isDigit() ||
            (code >= 65 && code <= 70) ||
            (code >= 97 && code <= 102);
    }

    /** Whether the char is an uppercase or lowercase X */
    public function isHexX() {
        return value == "x" || value == "X";
    }

    /** Whether the char is an uppercase or lowercase E */
    public function isExponentE() {
        return value == "e" || value == "E";
    }

    /** Whether the char is a plus or minus */
    public function isNumericSign() {
        return value == "-" || value == "+";
    }
    
    /** Whether the char is a zero */
    public function isZero() {
        return value == "0";
    }
    
    /** Whether the char is a newline */
    public function isNewline() {
        return value == "\n";
    }
    
    /** Whether the char is a carriage return */
    public function isReturn() {
        return value == "\r";
    }       

    /** Whether the char is a period */
    public function isPeriod() {
        return value == ".";
    }       

    /** Whether the char is a minus */
    public function isMinus() {
        return value == "-";
    }       

    /** Whether the char is a line comment start */
    public function isLineComment() {
        return value == "%";
    }       

    /** Whether the char is a slash */
    public function isSlash() {
        return value == "/";
    }       

    /** Whether the char is a backslash */
    public function isBackslash() {
        return value == "\\";
    }       
    
    /** Whether the char is a star */
    public function isAsterisk() {
        return value == "*";
    }       
    
    public function isOpenParen()    { return value == "("; }      
    public function isCloseParen()   { return value == ")"; }     
    public function isOpenBrace()    { return value == "{"; }      
    public function isCloseBrace()   { return value == "}"; }     
    public function isOpenBracket()  { return value == "["; }        
    public function isCloseBracket() { return value == "]"; }               
    
    /** Whether the char is whitespace */
    public function isWhitespace() {
        return WHITESPACE.indexOf( value ) >= 0;
    }
}