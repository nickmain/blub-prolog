package blub.prolog.builtins.objects;

import blub.prolog.Marshal;
import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.ChoicePoint;
import blub.prolog.builtins.BuiltinPredicate;
import blub.prolog.builtins.objects.ObjectWrapper;
import blub.prolog.builtins.async.AsyncOperation;

/**
 * Listen for property changes.
 * 
 * Arg[0] is term to unify with object and prop name dot pair
 * Arg[1] is atom(s) or dot pair(s) denoting object(+prop name) to listen on.
 * 
 * This is an asynchronous predicate.
 */
class PropertyChanges extends BuiltinPredicate {

    public function new() {
		super( "change_in", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var receiver  = args[0].toValue(env).dereference();
		var propSpecs = args[1].toValue(env).dereference();  		 		
		 
		if( propSpecs == null ) {
			engine.raiseException( 
			    RuntimeError.typeError( 
				    TypeError.VALID_TYPE_atom, args[0], engine.context ) );
		}
		
		
		
	}
	
	function objPropsArrayFrom( engine:QueryEngine, term:ValueTerm ):Map<String,ObjectProperties> {
		if( term.asReference() != null ) {
			engine.raiseException( RuntimeError.instantiationError( engine.context ));
			return null;
		}
		
		var terms = new Array<Term>();
		
		var comma = term.asStructure();
		if( comma != null ) comma.commaList( terms );
		else terms.push( term );
		
		var objProps = new Map<String,ObjectProperties>();
		
		for( t in terms ) {
			if( ! objPropsFrom( engine, t, objProps ) ) return null; 			
		}
		
		return objProps;
	}
	
	function objPropsFrom( engine:QueryEngine, term:ValueTerm, objProps:Map<String,ObjectProperties> ):Bool {
        
    }
	
}



//represents an object and a set of property names 
class ObjectProperties {
	public var object (default,null):ObjectWrapper;
	public var props  (default,null):Map<String,Bool>;
	
	public function new( object:ObjectWrapper ) {
		this.object = object;
	}
	
	public function addProp( name:String ) {
		if( props == null ) props = new Map<String,Bool>();
		props.set( name, true );
	}
}

//repeating choicepoint
class EventChoicePoint extends ChoicePoint { 
    
    var dispatcher:EventDispatcher;
    var listenerFn:EventFunction; 
    var eventType :String;
    var isActive:Bool;
    var engine:QueryEngine;
    var ref:Reference;
    
    public function new( eng:QueryEngine, 
                         dispatcher:EventDispatcher, eventType:String,
                         ref:Reference ) {
                            
        //save the code frame of the caller
        super( eng, eng.codeStack );

        this.ref = ref;
        this.engine     = eng;
        this.dispatcher = dispatcher;
        this.eventType  = eventType;
        listenerFn = handler;
        
        dispatcher.addEventListener( eventType, listenerFn );
        nextChoice();
    }
    
    function handler( e:flash.events.Event ):Void {
        if( ! isActive ) return; //could be that some other async pred is active
        isActive = false;
                    
        var atom = Marshal.valueToTerm( e );
        
        engine.unify( ref, atom );
        engine.continueAsync();
    }
    
    override public function nextChoice():Bool {
        frame.restore();
        isActive = true;
        
        engine.beginAsync( 
            new AsyncOperationImpl( "receive( .. ," + eventType + ", .. )", halt ));             
        
        return true;
    }
    
    override public function halt() {
        isActive = false;
        
        if( listenerFn != null ) {
            dispatcher.removeEventListener( eventType, listenerFn );            
            listenerFn = null;
        }
    }
}