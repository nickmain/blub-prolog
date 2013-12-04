package blub.prolog.engine.parts;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.Operations;

/**
 * A choice point that can be backtracked to
 */
class ChoicePoint {
    public var bindings:Binding; //entry before new bindings
    public var frame:CodeFrame; 
    public var prev:ChoicePoint;
	
	private var engine:QueryEngine;
    
    public function new( eng:QueryEngine, ?frame:CodeFrame ) {
        this.frame = if( frame != null ) frame else new CodeFrame( eng );
        bindings = eng.bindings;
        prev = eng.choiceStack;
        eng.choiceStack = this;
		this.engine = eng;
    }
    
	/** Return true if there is a next choice */
    public function nextChoice():Bool {
        frame.restore();
        popThisChoicePoint();
        return true;
    }
    
    /** Undo all the bindings made since this choice point */
    public function undoBindings() {
        engine.undoBindings( bindings );
    }

    function popThisChoicePoint() {		
        engine.choiceStack = prev;
    }
    
    /**
     * Called when the engine is halted - override to allow cleanup of any
     * resources associated with the choicepoint (for example - if the
     * choicepoint is an event listener then deregister)
     */
    public function halt() {
        //override
    }
	
	public function toString() {
		return "Choicepoint: " + frame;
	}
	
	public function getId() {
		if( _id < 1 ) _id = ID++;
		return _id;
	}
	private var _id:Int;
	private static var ID = 1;
}