package blub.prolog.builtins.display;

import blub.prolog.Marshal;
import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Reference;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.ChoicePoint;
import blub.prolog.builtins.BuiltinPredicate;
import blub.prolog.builtins.objects.ObjectWrapper;
import blub.prolog.builtins.async.AsyncOperation;

/**
 * Receive an event from an object that extends EventDispatcher.
 * Arg[0] is atom wrapping the object.
 * Arg[1] is atom denoting the event type.
 * Arg[2] is the var with which the event object is unified
 * 
 * This is an asynchronous predicate. It also implements an infinite set of
 * choice points.
 */
class ReceiveEvent extends BuiltinPredicate {

    public function new() {
		super( "receive", 3 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var atom = args[0].toValue(env).dereference().asAtom();
		var type = args[1].toValue(env).dereference().asAtom(); 
		var ref  = args[2].toValue(env).dereference().asReference(); 
		 
		if( atom == null ) {
			engine.raiseException( 
			    RuntimeError.typeError( 
				    TypeError.VALID_TYPE_atom, args[0], engine.context ) );
		}

        if( type == null ) {
            engine.raiseException( 
                RuntimeError.typeError( 
                    TypeError.VALID_TYPE_atom, args[1], engine.context ) );
        }

        if( ref == null ) {
            engine.raiseException( 
                RuntimeError.typeError( 
                    TypeError.VALID_TYPE_variable, args[2], engine.context ) );
        }
		
		var object = atom.object;
	    if( object == null || ! Std.is( object, ObjectWrapper ) ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom("is not an atom wrapping a native object: " + atom ), 
                    engine.context ));
		}
		
		var wrapper:ObjectWrapper = cast object;
		object = wrapper.getObject();

        if( object == null || ! Std.is( object, flash.events.EventDispatcher ) ) {
            engine.raiseException( 
                new PrologException( 
                    Atom.unregisteredAtom( "is not an EventDispatcher: " + atom ), 
                    engine.context ));            
        }
		
		var dispatcher:EventDispatcher = cast object;
		
		//add a repeating choicepoint to listen for events
		new EventChoicePoint( engine, dispatcher, type.text, ref );
	}
}

typedef EventDispatcher = flash.events.EventDispatcher;
typedef EventFunction   = flash.events.Event->Void;

//repeating choicepoint
class EventChoicePoint extends ChoicePoint { 
	
	var dispatcher:EventDispatcher;
    var listenerFn:EventFunction; 
	var eventType :String;
	var isActive:Bool;
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