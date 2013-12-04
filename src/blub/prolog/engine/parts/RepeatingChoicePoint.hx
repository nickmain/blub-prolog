package blub.prolog.engine.parts;

import blub.prolog.engine.QueryEngine;

/**
 * Choice point that repeats forever 
 */
class RepeatingChoicePoint extends ChoicePoint { 
    public function new( eng:QueryEngine ) {
        //save the code frame of the caller of Repeat
        super( eng, eng.codeStack );
    }
    
    override public function nextChoice():Bool {
        frame.restore();
        return true;
    }
	
    override public function toString() {
        return "Repeating: " + frame;
    }
}
