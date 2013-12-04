package blub.prolog.builtins.async;

/**
 * An asynchronous operation, as referenced by the QueryEngine to allow
 * cancellation.
 */
interface AsyncOperation {

    /** Cancel the operation */
    public function cancel():Void;

    /** Get a description of the operation */
    public function getDescription():String;
}

/** AsyncOperation that calls a function for cancellation */
class AsyncOperationImpl implements AsyncOperation {
	
	var description:String;
	var cancelFn:Void->Void;
	
	public function new( description:String, cancelFn:Void->Void ) {
		this.description = description;
		this.cancelFn    = cancelFn;
	}

    public function cancel() { if( cancelFn != null ) cancelFn(); }
    public function getDescription() { return description; }	
}