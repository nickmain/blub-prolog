package blub.prolog.stopgap.parse;

import blub.prolog.terms.Atom;

/**
 * An operator definition
 */
class Operator {

    public var atom(default,null):Atom;
    public var spec(default,null):OperatorSpec;
    public var priority(default,null):Int;
    public var arity(default,null):Int;
	public var functor(default,null):String;
	
    public function new( atom:Atom, spec:OperatorSpec, priority:Int ) {
        this.priority = priority;
        this.spec     = spec;
        this.atom     = atom;
		
		arity = switch( spec ) {
            case op_fx, op_fy, op_xf, op_yf: 1;
			case op_xfx, op_yfx, op_xfy: 2;
        }		
		
		functor = functorForOp( atom.text, arity );
    }

    inline public static function functorForOp( name:String, arity:Int ) {
		 return name + "/" + arity;
	}

    /** Whether the operator expects a left arg */
    public function expectsLeft() {
        return leftSpec != null;
    }
    
    /** Whether the operator expects a right arg */
    public function expectsRight() {
        return rightSpec != null;
    }

    /** Get the right specifier - either x or y, null if none */
    public var rightSpec(get,null):Specifier;
    function get_rightSpec() {
        return switch( spec ) {
            case op_xf, op_yf         : null;
            case op_fx, op_xfx, op_yfx: spec_x;            
            case op_fy, op_xfy        : spec_y;
        }
    }

    /** Get the left specifier - either x or y, null if none */
    public var leftSpec(get,null):Specifier;
    function get_leftSpec() {
        return switch( spec ) {
            case op_fy, op_fx         : null;
            case op_xf, op_xfx, op_xfy: spec_x;
            case op_yf, op_yfx        : spec_y;
        }
    }
    
    /**
     * Compare this op to the one to the right of it.
     * 
     * Assumes that this op and the other expect an arg in the appropriate
     * positions.
     * 
     * @return 0 if there is a clash,
     *         1 if this op has a higher priority, 
     *         2 if the other op is higher
     */
    public function compareToRight( right:Operator ) {
        if( priority > right.priority ) return 1;
        if( priority < right.priority ) return 2;
        
        var rspec = rightSpec;
        var lspec = right.leftSpec;
        
        if( rspec == lspec ) return 0;
        
        if( rspec == spec_y ) return 1;  //.fy xf.
        return 2;  //.fx yf.     1 yfx 2 yxf 3  -> (1 yfx 2) yxf 3
    }
    
    public static function opSpec( s:String ):OperatorSpec {
        return switch( s ) {
            case "fx" : op_fx;
            case "fy" : op_fy;
            case "xf" : op_xf;
            case "yf" : op_yf;
            case "xfx": op_xfx;
            case "yfx": op_yfx;
            case "xfy": op_xfy;
            default: null;        
        }
    }
}

enum Specifier { spec_x; spec_y; }

enum OperatorSpec {
    op_fx;
    op_fy;
    op_xf;
    op_yf;
    op_xfx;
    op_yfx;
    op_xfy;
}