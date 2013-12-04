package blub.prolog.tests;

/**
 * Some Prolog theories for loading into the unit-test web page
 */
@:expose
class ExampleTheories {

    public static var examples = [
	    [ "8 queens"   ,"run_queens(B)", theories.EightQueens.theory ],
	    [ "zebra"      ,"zebra(Owner)" , theories.Zebra.theory ],
	   	[ "sprite demo","test"         , theories.SpriteDemo.theory ],
		
		[ "Max List Probs", "range(1,15000,List)", 
"range(Start,End,List) :- Start =< End, !, 
                         Start2 is Start+1, 
                         List = [Start|Rest], 
                         range(Start2,End,Rest).
range(_,_,[])." ]
	];

    /** Make HTML for the buttons */
    public static function makeButtons( theoryFieldId:String, queryFieldId:String ):String {
		var buf = new StringBuf();
		
	    for( i in 0...examples.length ) {
		    buf.add( "<input type='submit' value='&lt;-- " );
			buf.add( examples[i][0] );
			buf.add( "' onclick='blub.prolog.tests.ExampleTheories.loadExample(" );
			buf.add( "\"" + theoryFieldId + "\"" );
			buf.add( ",\"" + queryFieldId + "\"" );
			buf.add( "," + i );
			buf.add( ")' /><br />" );
		}
		
		buf.add( "<br />" );
		
		var storage = untyped window.localStorage;
		if( storage.theory != null ) {
            buf.add( "<input type='submit' value='&lt;-- RESTORE' onclick='blub.prolog.tests.ExampleTheories.loadStorageExample(" );
            buf.add( "\"" + theoryFieldId + "\"" );
            buf.add( ",\"" + queryFieldId + "\"" );
            buf.add( ")' /><br />" );			
		}
		
		buf.add( "<input type='submit' value='--&gt; SAVE' onclick='blub.prolog.tests.ExampleTheories.saveStorageExample(" );
        buf.add( "\"" + theoryFieldId + "\"" );
        buf.add( ",\"" + queryFieldId + "\"" );
        buf.add( ")' /><br />" );
		
		return buf.toString();
	}

    /** Callback from the buttons to load example from localStorage */
    public static function loadStorageExample( theoryFieldId:String, queryFieldId:String ) {
        var storage = untyped window.localStorage;
        var localTheory = storage.theory;
        var localQuery = storage.query;

        untyped js.Browser.document.getElementById( theoryFieldId ).value = localTheory;
        untyped js.Browser.document.getElementById( queryFieldId  ).value = localQuery;
    }

    /** Callback from the buttons to save example to localStorage */
    public static function saveStorageExample( theoryFieldId:String, queryFieldId:String ) {
        var storage = untyped window.localStorage;
        storage.theory = untyped js.Browser.document.getElementById( theoryFieldId ).value;
        storage.query  = untyped js.Browser.document.getElementById( queryFieldId  ).value;
    }

    /** Callback from the buttons to load an example */
    public static function loadExample( theoryFieldId:String, queryFieldId:String, index:Int ) {
		untyped js.Browser.document.getElementById( theoryFieldId ).value = examples[index][2];
		untyped js.Browser.document.getElementById( queryFieldId  ).value = examples[index][1];
	}
}
