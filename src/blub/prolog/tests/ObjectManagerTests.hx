package mind.prolog.tests;

import mind.prolog.Database;
import mind.prolog.Query;
import mind.prolog.terms.Term;
import mind.prolog.internals.Clause;
import mind.prolog.objects.AtomObjectManager;
import mind.prolog.objects.AtomObject;

class ObjectManagerTests extends haxe.unit.TestCase {

//    public function testSanity() {
//        var db = new Database();
//        db.loadString("
//            object(foo,23).
//            object(bar,24).
//        ");
//   
//        var manager = new AtomObjectManager( db );
//        
//        assertEquals( "obj_foo", manager.get("foo"));
//        assertEquals( "obj_bar", manager.get("bar"));
//        
//        assertTrue( manager.get( "baz" ) == null ); 
//        db.assertZ( Term.parse( "object(baz,whatever)" ) );
//        assertEquals( "obj_baz", manager.get("baz"));
//        
//        assertTrue( manager.get( "wombat" ) == null );
//        manager.set( "wombat", "hello" );
//        assertEquals( "hello", manager.get("wombat"));
//        assertTrue( new Query( db, Term.parse( "object(wombat,_)" )).nextSolution().success );
//    }
//
//    function constructor( key:Term, args:Term, atFront:Bool ) {
//        return "obj_" + key.toString();
//    }
//    
//    public function testLifecycle() {
//        var db = new Database();
//        db.loadString("
//            object(foo,23).
//        ");
//   
//        var manager = new AtomObjectManager( db, 
//                function( key:Term, args:Term, atFront:Bool ) {
//                    return new Managed( key.toString() + args.toString());
//                });
//        
//        var foo = cast(manager.get("foo"), Managed);
//        
//        assertEquals( "foo23", foo.log.shift() );
//        assertEquals( "asserted object( foo, 23 ).", foo.log.shift() );
//        assertTrue( foo.log.length == 0 );
//        
//        new Query( db, Term.parse( "retract(object(foo,_))" )).complete();
//        assertEquals( "retracted", foo.log.shift() );
//        assertTrue( foo.log.length == 0 );
//    }
}

//private class Managed implements AtomObject {
//
//    public var log:Array<String>;
//    
//    public function new( id:String ) {
//        super( id );
//        log = [ id ];
//    }
//
//    public function asserted( clause:Clause ) {
//        log.push( "asserted " + clause.toString() );
//    }
//    
//    public function retracted() {
//        log.push( "retracted" );    
//    }
//} 