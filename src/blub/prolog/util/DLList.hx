package blub.prolog.util;

interface DLListListener<T> {
	public function entryHasBeenAdded( entry:Entry<T> ):Void;
	public function entryWillBeRemoved( entry:Entry<T> ):Void;
	public function listWillBeCleared( list:DLList<T> ):Void;
}

/**
 * An Iterable that produces an Iterator that always starts at the same item,
 * ignoring any items prepended to the list.
 */
class TailIterable<T> {
	var entry:Entry<T>;
	var list:DLList<T>;
	
	public function new( list:DLList<T> ) {
		this.list  = list;
		entry = list.first; 
	}
	
	public function iterator():Iterator<T> {
		return new ItemIter<T>( list, entry );
	}
}

class EntryDeletionListener<T> implements DLListListener<T> {
    var callBack:T->Void;
	public function new( callBack:T->Void ) { this.callBack = callBack; }	
    public function entryHasBeenAdded( entry:Entry<T> ) {}
    public function entryWillBeRemoved( entry:Entry<T> ) { callBack( entry.item ); }
    public function listWillBeCleared( list:DLList<T> ) {}
}

/**
 * Doubly linked list - to allow cheap insertion and removal
 */
class DLList<T> {
    
    public var first(get,null):Entry<T>;
    public var last (get,null):Entry<T>;
    public var size (default,null):Int;
    public var items(get,null):Iterator<T>;
    public var entries(get,null):Iterator<Entry<T>>;
    
    var _first:EntryImpl<T>;
    var _last :EntryImpl<T>;
    
	var listeners:Array<DLListListener<T>>;
	var internals:ListInternals<T>;
	
    public function new() {
        size = 0;
		internals = {
			remove:removeEntry,
			setFirst:setFirst,
			setLast:setLast
		};
    }
    
    function get_first() { return _first; }
    function get_last () { return _last; }
    
	/**
	 * Add a listener (with no way to unlisten)
	 */
	public function listen( listener:DLListListener<T> ) {
		if( listeners == null ) listeners = new Array<DLListListener<T>>(); 
		listeners.push( listener );
	}
	
    /** Clear the list */
    public function clear() {
		if( listeners != null ) for( listener in listeners ) listener.listWillBeCleared( this );
		
        size = 0;
        _last = null;
        _first = null;
    }
    
    public function removeFirst():T {
        if( _first == null ) return null;
        return _first.remove();
    }

    public function removeLast():T {
        if( _last == null ) return null;
        return _last.remove();
    }

    public function remove( entry:Entry<T> ):T {
		if( entry == null || entry.list != this ) return null;
        return entry.remove();
    }
    
    public function append( item:T ):Entry<T> {
        return insertAfter( item, _last );
    }
    
    public function prepend( item:T ):Entry<T> {
        return insertAfter( item, null );
    }
    
	/** Remove first occurence of the given item - true if found */
	public function removeItem( item:T ):Bool {
		for( e in get_entries() ) {
			if( e.item == item ) {
				e.remove();
				return true;
			}
		}
		
		return false;
	}
	
    private function removeEntry( e:EntryImpl<T> ) {    
        if( e == null ) return;
        if( e.list != this ) return;
    
        if( listeners != null ) for( listener in listeners ) listener.entryWillBeRemoved( e );
	
        if( e.prev == null ) _first = cast e.next;  //was first
        if( e.next == null ) _last  = cast e.prev;  //was last
        size--;
    }
    
    public function insertAfter( item:T, entry:Entry<T> ):Entry<T> {    
        var prev:EntryImpl<T> = if( entry != null ) (cast entry) else null;
        if( prev != null && prev.list != this ) return null;
        
        var next = if( prev != null ) (cast prev.next) else _first;
        
        var entry = new EntryImpl<T>( item, this, prev, next, internals );
        
        if( prev == null ) _first = entry;        
        if( next == null ) _last = entry;
        size++;
		
		if( listeners != null ) for( listener in listeners ) listener.entryHasBeenAdded( entry );
		
        return entry;
    }

    public function iterator():Iterator<T> {
        return get_items();
    }
    
    function get_items():Iterator<T> {
        return new ItemIter<T>( this );
    }
    
    function get_entries():Iterator<Entry<T>> {
        return new EntryIter<T>( this );
    }
	
	function setFirst( entry:EntryImpl<T> ) {
        _first = entry;
		if( _last == null ) _last = entry;
    }
	
	function setLast( entry:EntryImpl<T> ) {
		_last = entry;
		if( _first == null ) _first = entry;
	}
	
	public function toString() {
		var buf = new StringBuf();
		buf.add("[ ");
		var first = true;
		
		for( i in items ) {
			if( first ) first = false;
			else buf.add(", ");
			
			buf.add( Std.string( i ) );
		}
 		
		buf.add(" ]");
		return buf.toString();
	}
}

typedef ListInternals<T> = {
	var remove  :EntryImpl<T>->Void;
	var setFirst:EntryImpl<T>->Void;
	var setLast :EntryImpl<T>->Void;
};

interface Entry<T> {
    public var item(default,null):T;
    
    public var prev(get,null):Entry<T>;
    public var next(get,null):Entry<T>;
    
	/** null if removed from list */
	public var list(default,null):DLList<T>;
	
    public function remove():T;
    
    public function get_prev():Entry<T>;
    public function get_next():Entry<T>;
	
	public function moveToFirst():Void;
	public function moveToLast():Void;
}

private class ItemIter<T> {
    var iter:EntryIter<T>;

    public function new( list:DLList<T>, ?first:Entry<T> ) {
        iter = new EntryIter<T>( list, first );
    }

    public function hasNext() {
        return iter.hasNext();
    }

    public function next():T {
		var entry = iter.next();
		return if( entry == null ) null else entry.item;
    }
}

private class EntryIter<T> {
    var nextEntry:Entry<T>;

    public function new( list:DLList<T>, ?first:Entry<T> ) {
        nextEntry = if( first == null ) list.first else first;
    }

    public function hasNext() {
		advanceToLiveEntry();
        return nextEntry != null;
    }

    private function advanceToLiveEntry() {
		while( nextEntry != null && nextEntry.list == null ) {
            nextEntry = nextEntry.next;
        }
	}

    public function next():Entry<T> {
		advanceToLiveEntry();
        if( nextEntry == null ) return null;
        var result = nextEntry;
		nextEntry = result.next;        
        return result;        
    }
}

private class EntryImpl<T> implements Entry<T> {
    public var item(default,null):T;
    public var prev(get,null):Entry<T>;
    public var next(get,null):Entry<T>;
    
    public var list(default,null):DLList<T>;
	
    private var _prev:EntryImpl<T>;
    private var _next:EntryImpl<T>;
    private var _internals:ListInternals<T>;
	
    public function get_prev():Entry<T> { return _prev; }
    public function get_next():Entry<T> { return _next; }
    
    public function new( item:T, list:DLList<T>, prev:EntryImpl<T>, next:EntryImpl<T>, internals:ListInternals<T> ) {
        this.item = item;
		this.list = list;
		_prev = prev;
		_next = next;
		_internals = internals;
		
		if( prev != null ) prev._next = this;
		if( next != null ) next._prev = this;
    }
    
	public function moveToFirst() {
	    if( list == null ) return;
		if( _prev == null ) return;
	
	    yank();
		_next = cast list.first;
		_next._prev = this;
		_internals.setFirst( this );
	}
	
    public function moveToLast() {
        if( list == null ) return;
        if( _next == null ) return;
    
        yank();
		_next = null;
        _prev = cast list.last;
        _prev._next = this;
        _internals.setLast( this );	
	}

    //yank out of the list
    private function yank() {
        if( _prev != null ) _prev._next = _next;
		else _internals.setFirst( _next ); 
		
        if( _next != null ) _next._prev = _prev;
		else _internals.setLast( _prev );
		
        _prev = null;
		
		//do not null _next - to allow iterators to find their way back to the list
        //_next = null;
	}
	
    public function remove():T {
        if( list == null ) return item;
        _internals.remove( this );

        yank();		
		list = null;
		
		var it = item;
		item = null;
		return it;
    }
}