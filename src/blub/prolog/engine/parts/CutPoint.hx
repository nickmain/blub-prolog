package blub.prolog.engine.parts;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.Operations;

/**
 * serves as a cut barrier
 */
class CutPoint extends ChoicePoint {
    public function new( eng:QueryEngine ) {
        super( eng );
    }
    
    override public function nextChoice():Bool {        
        frame.engine.choiceStack = prev;
        return false; //cause backtracking to jump to previous choice point
    }
}