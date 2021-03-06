import blub.prolog.Database;
import blub.prolog.Query;

import blub.prolog.terms.Term;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Variable;

import haxe.Timer;

using blub.prolog.Result.ResultUtil; 

/**
 * The "8 queens" and "Zebra" problems as tools for driving the instruction set design.
 */
@:expose
class TimingTests {
	var db:Database;
	var query:Query;
	
	public function new( theory:String ) {
        db = new Database();		
		db.loadString( theory, true );
	}

    public static function log(v:Dynamic) {
        trace(v);
    }

    public static function clear() {
        #if js
        final traceDiv = js.Browser.document.getElementById("haxe:trace");
        while(true) {
            final child = traceDiv.firstChild;
            if(child == null) break;
            traceDiv.removeChild(child);
        }        
        #end
	}

    public static function stressTestQueens( count:Int ) {
        trace('Running 8 Queens * $count ...');
        final solutions = stressTest( queens_theory, "run_queens", count );
        if(count == 1) {
            trace( "solution count = " + solutions.length );
            for( solution in solutions ) {
                trace( solution.toString() );           
            }
        }
	}

    public static function stressTestOKeefeQueens( count:Int ) {
        trace('Running O\'Keefe 8 Queens * $count ...');
        final solutions = stressTest( okeefe_queens_theory, "run_queens", count );
        if(count == 1) {
            trace( "solution count = " + solutions.length );
            for( solution in solutions ) {
                trace( solution.toString() );           
            }
        }
	}

    public static function stressTestZebra( count:Int ) {
        trace('Running Zebra * $count ...');
        stressTest( zebra_theory, "zebra", count );
    }
	
	static function stressTest( theory:String, predName:String, count:Int ): Array<Term> {
        var test = new TimingTests( theory );
        
        var time = 0.0;
        var solutions: Array<Term> = [];

        for( i in 0...count ) {	
            var timestamp = haxe.Timer.stamp();
            solutions = test.run( predName );
            time += haxe.Timer.stamp() - timestamp;           
        }
        
        trace( "Average time = " + (time/count) );
        return solutions;
    }
	
    public function run( predName:String ):Array<Term> {		
		
		var qterm = new Structure( db.context.getAtom(predName), [cast new Variable("Result")]);
		query = new Query( db, qterm );
		
		var solutions = [];
		for( result in query ) {
			if( result.isSuccess() ) solutions.push( result.getBindings().get("Result") );
		}
		
		return solutions;	
	}

    public static function main() {
        #if js
        haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
            final traceDiv = js.Browser.document.getElementById("haxe:trace");
            final logLine = js.Browser.document.createParagraphElement();
            logLine.innerText = '${infos.className}[${infos.lineNumber}]: $v';
            logLine.className = "log-line";
            traceDiv.appendChild(logLine);
        }
        #end

        #if !(cpp)
        haxe.Timer.delay( function() {
        #end
        
        //try {
            trace( "Starting...." );
			var zebra  = new TimingTests( zebra_theory );			
            var timestamp = haxe.Timer.stamp();
            var solutions = zebra.run("zebra");
            trace( "Zebra in " + (Timer.stamp() - timestamp) + " seconds" );
            trace( "solution count = " + solutions.length );            
            for( solution in solutions ) {
                trace( solution.toString() );           
            }
                        
            stressTestOKeefeQueens(10);
            
            var queens = new TimingTests( queens_theory );
            
            timestamp = haxe.Timer.stamp();
            var solutions = queens.run("run_queens");
            trace( "8 queens in " + (Timer.stamp() - timestamp) + " seconds" );
            trace( "solution count = " + solutions.length );
            
            #if !(flash10 || flash11 || flash9)
            
            for( solution in solutions ) {
                trace( solution.toString() );           
            }
            #end
        //}
        //catch( e:Dynamic ) trace(e);
        
        #if !(cpp)
        }, 500 );
        #end
    }
	
	public static var queens_theory = theories.EightQueens.theory; 
	public static var okeefe_queens_theory = theories.OKeefe8Queens.theory; 
	public static var zebra_theory  = theories.Zebra.theory;
}

