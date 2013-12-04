package blub.prolog.engine.parts;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.Operations;

/**
 * Choice among a number of clauses
 */
class ClauseChoices extends ChoicePoint {
    public var clauses:Array<Clause>;
    public var index:Int;
    
    public function new( eng:QueryEngine, clauses:Array<Clause> ) {
        super( eng );
                
        this.clauses = clauses;
        index = 0;
        jumpToChoice(); //call the first clause
    }
    
    override public function nextChoice():Bool {
        frame.restore();
        return jumpToChoice();
    }
    
    function jumpToChoice():Bool {          
        var clause = clauses[index++];
        
        //pop this if no more clauses
        if( index == clauses.length ) {
            //trace( "Last clause" );
            popThisChoicePoint();
        }
        //else trace( "Next clause" );
        
        engine.pushCutBarrier( this );      
        
        //call the clause
        engine.context     = clause;        
        engine.codePointer = clause.code;
        
        return true;
    }   
		   
    override public function toString() {
        return "Next clause: " + clauses[index].head;
    }
}
