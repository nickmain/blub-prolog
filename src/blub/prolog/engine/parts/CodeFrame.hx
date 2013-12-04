package blub.prolog.engine.parts;

import blub.prolog.terms.Term;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.Operations;

/**
 * Context within which code is executing (other than choice points)
 */
class CodeFrame {  
	
    public var engine     :QueryEngine;
    public var codeStack  :CodeFrame;    
    public var codePointer:OperationList;   
    public var cutBarrier :CutBarrier;    
    public var arguments  :Arguments;    
    public var environment:TermEnvironment;
    public var context    :Clause;
    
    public function new( eng:QueryEngine, ?continuation:OperationList ) {
        engine = eng;

        codeStack   = engine.codeStack;    
        codePointer = if( continuation == null ) engine.codePointer else continuation;
        cutBarrier  = engine.cutBarrier;    
        arguments   = engine.arguments;    
        environment = engine.environment;
        context     = engine.context;  
    }
    
    public function restore() {
        engine.codeStack   = codeStack;    
        engine.codePointer = codePointer;   
        engine.cutBarrier  = cutBarrier;    
        engine.arguments   = arguments;    
        engine.environment = environment;
        engine.context     = context;
    }
	
	public function toString() {
        return "Frame: " + environment;
    }
}