package blub.prolog.debug;

import blub.prolog.engine.QueryEngine;
import blub.prolog.Query;
import blub.prolog.Result;
import js.html.Element;

/**
 * An HTML based query stepper
 */
@:expose
class HtmlStepper {

    var engine:QueryEngine;
	var query:Query;
	
	var spanIsHalted:Element; 
    var spanSolnFound:Element;
    var spanContext:Element;
    var environCell:Element;
	var argsCell:Element;
			
	var codeStack:Element;
    var envStack:Element; 
    var choiceStack:Element;
    var cutStack:Element;
    var bindingStack:Element;
				
    var status:Element;
	
	var results:Array<Result>;	
		
	public function new( query:Query ) {
		this.query = query; 
		this.engine = query.engine;

        results = [];

        status        = js.Browser.document.getElementById("status");
        spanIsHalted  = js.Browser.document.getElementById("ishalted");
        spanSolnFound = js.Browser.document.getElementById("solnfnd");
        spanContext   = js.Browser.document.getElementById("context");
        environCell   = js.Browser.document.getElementById("env");
        argsCell      = js.Browser.document.getElementById("args");

        codeStack    = js.Browser.document.getElementById("code-stack");
        envStack     = js.Browser.document.getElementById("env-stack");
        choiceStack  = js.Browser.document.getElementById("choice-stack");
        cutStack     = js.Browser.document.getElementById("cut-stack");
        bindingStack = js.Browser.document.getElementById("binding-stack");
		
		showEngineState();
	}

    /**
     * Single step
     */
    public function step() {
		try {
		    engine.executeStep();
		}
		catch( e:Dynamic ) {
			untyped setResult( "<p style='color:red'>Exception: " + e + "</p>" );
		}
		  
		showEngineState();
		
		if( engine.codePointer == null && engine.solutionFound ) {
			results.push( query.grabCurrentSolution() );
			untyped showResults( results, "n/a" );
		}
	}

    /**
     * Run to breakpoint or exception
     */
    public function run() {
        try {
            engine.debugRun();
        }
        catch( e:Dynamic ) {
            untyped setResult( "<p style='color:red'>Exception: " + e + "</p>" );
        }
          
        showEngineState();
        
        if( engine.codePointer == null && engine.solutionFound ) {
            results.push( query.grabCurrentSolution() );
            untyped showResults( results, "n/a" );
        }		
	}

    public function showEngineState() {
		
		if( engine.atBreakpoint ) {
			status.innerHTML = "BREAKPOINT";
		}
		else if( engine.exception != null ) {
            status.innerHTML = engine.exception.toString();
        }
        else {
            status.innerHTML = "";
        }		
		
		spanIsHalted .innerHTML = if( engine.isHalted ) "YES" else "NO";
		spanSolnFound.innerHTML = if( engine.solutionFound ) "YES" else "NO";
		spanContext.innerHTML =  if( engine.context != null ) engine.context.head.toString()
		                         else "-";
		
		environCell.innerHTML = if( engine.environment != null ) engine.environment.toString()
                                 else "-";
        argsCell   .innerHTML = if( engine.arguments != null ) engine.arguments.toString()
                                 else "-";
								 
		codeStack   .innerHTML = makeTable( getCodeList(), "instruction" );
        envStack    .innerHTML = makeTable( getCodeStack(), "code-frame" );
        choiceStack .innerHTML = makeTable( getChoices(), "choicepoint" );
        cutStack    .innerHTML = makeTable( getCutBarriers(), "cut-barrier" );
        bindingStack.innerHTML = makeTable( getBindings(), "binding" );
	}

    private function getCutBarriers() {
		var cbs = [];
		
		var cb = engine.cutBarrier;
		while( cb != null ) {
			cbs.push( "cut choice: " + cb.choice.getId() );
			cb = cb.prev;
		}
		
		return cbs;
	}

    private function getBindings() {
	   var binds = [];
	   
	   var bind = engine.bindings;
	   while( bind != null ) {
		   binds.push( bind.ref.toString() );
		   bind = bind.next;
	   }	   
	   
	   return binds;	
	}

    private function getChoices() {
        var choices = [];
        
        var choice = engine.choiceStack;
        while( choice != null ) {
            choices.push( choice.getId() + ": " + choice.toString() );
            choice = choice.prev;
        }
        
        return choices;
    }

    private function getCodeStack() {
		var frames = [];
		
		var frame = engine.codeStack;
		while( frame != null ) {
			frames.push( "" + frame.environment );
			frame = frame.codeStack;
		}
		
		return frames;
	}

    private function getCodeList() {
		var ops = [];
		
		var ptr = engine.codePointer;
		while( ptr != null ) {
			if( ptr.asm != null ) {
				blub.prolog.compiler.Assembler.dumpInstruction( ptr.asm, function(s:String){
				    ops.push( s );
				});				
			}
			else {
				ops.push( "..." );
			}
			
			ptr = ptr.next;
		}
		
		return ops;
	}

    private function makeTable( rows:Array<String>, style:String ) {
		
		var s:StringBuf = new StringBuf();
		s.add( "<table cellspacing='1'>" );
		
		for( r in rows ) {
			s.add( "<tr><td class='" + style + " stack-item'>" + r + "</td></tr>" );
		}
                    
        s.add( "</table>" );
		
		return s.toString();
	}

    public static function show() {		
		js.Browser.document.getElementById('stepper').innerHTML = HTML;
	}

    public static function hide() {
        js.Browser.document.getElementById('stepper').innerHTML = "";
    }
 
    private static var HTML = 
"   <hr />
    <table cellspacing='1' class='stepper'>
        <tr>
            <td style='text-align: left'>
                <input type='submit' value='STEP' onclick='htmlstepper.step()' />&nbsp;&nbsp;
                <input type='submit' value='RUN' onclick='htmlstepper.run()' />
            </td>
            <td style='text-align: center; color:red;' colspan='4' id='status'>
            </td>
        </tr>
        <tr>
            <td class='flag'>isHalted: <span id='ishalted' class='flag-value'>false</span></td>
            <td class='flag'>solutionFound: <span id='solnfnd' class='flag-value'>false</span></td>
            <td class='flag'  colspan='3'>context: <span id='context' class='flag-value'>foo(bar)</span></td>
        </tr>
        <tr>
            <td class='envcell' >Environment: </td>
            <td class='env-value' id='env' colspan='4'>ENVIRONMENT</td>
        </tr>
        <tr>
            <td class='envcell' >Arguments: </td>
            <td class='env-value' id='args' colspan='4'>ARGUMENTS</td>
        </tr>
        <tr>
            <td class='stack-title'>Code</td>
            <td class='stack-title'>Stack</td>
            <td class='stack-title'>Choices</td>
            <td class='stack-title'>Cut Barriers</td>
            <td class='stack-title'>Bindings</td>
        </tr>    
        <tr>
            <td class='stack-cell' id='code-stack'>
            </td>
            <td class='stack-cell' id='env-stack'>
            </td>
            <td class='stack-cell' id='choice-stack'>
            </td>
            <td class='stack-cell' id='cut-stack'>
            </td>
            <td class='stack-cell' id='binding-stack'>
            </td>
        </tr>    
    </table>
";
}
