package blub.prolog.tests;
import blub.prolog.chr.ConstraintStore;
import blub.prolog.chr.ConstraintRules;
import blub.prolog.chr.ConstraintRule;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Reference;
import blub.prolog.terms.Structure;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Variable;
import blub.prolog.chr.Constraint;
import blub.prolog.chr.GuardCondition;
import blub.prolog.chr.RuleGoal;

import blub.prolog.engine.QueryEngine;
import blub.prolog.Database;
import blub.prolog.Marshal;
import mind.slime.util.Set;
import blub.prolog.chr.impl.StoredConstraint;
import blub.prolog.Query;
import blub.prolog.terms.Term;
import blub.prolog.chr.impl.PermutationIterator;

class ConstraintTest extends haxe.unit.TestCase {

    public function testSanity() {
		var stack = make( ["count/1","sum/1"], 
		[
            "count(A) ==> A < 10 | B is A + 1, count(B)",
            "count(A), sum(B) <=> nonvar(B) | C is B + A, sum(C)",
            "sum(B) ==> var(B) | sum(0)",
            "sum(B), sum(C) <=> nonvar(C) | B = C"		
		]);
						
		var ref = new Reference();
		stack.activate( stack.store.addConstraint( "count/1", [new NumberTerm(1)]));
		stack.processAll();
		stack.activate( stack.store.addConstraint( "sum/1"  , [ref]));
	    stack.processAll();
		
		assertEquals( 55.0, ref.dereference().asNumber().value );		
		assertEquals( 0, stack.store.getRemainingConstraints().length );
    }
		
    public function testVarAwaking() {
        var stack = make( ["foo/1","bar/1"], 
        [
		    "foo(A) \\ bar(B) <=> B > 10 | A = B.",
            "foo(A), foo(B) <=> nonvar(A), var(B) | B is A + 1."
        ]);
                        
        var A = new Reference();
		var B = new Reference();
        stack.activate( stack.store.addConstraint( "foo/1", [A]));
		stack.processAll();
        stack.activate( stack.store.addConstraint( "foo/1", [B]));
        stack.processAll();
        stack.activate( stack.store.addConstraint( "bar/1"  , [new NumberTerm(11)]));
        stack.processAll();
        
        assertEquals( 12.0, A.dereference().asNumber().value );       
        assertEquals( 11.0, B.dereference().asNumber().value );       
        assertEquals( 0, stack.store.getRemainingConstraints().length );
    }

    public function testPrologGoal() {
        var stack = make( ["foo/1,obj/1"], 
        [
            "obj(A) \\ foo(B), foo(C) <=> A.x <- B + C, A.fun(hello)."
        ]);
        
        var result = [];
		var test:Atom = cast Marshal.valueToTerm({
            x:0,
            fun:function(s:String) { result.push(s); }
        });
		
        stack.activate( stack.store.addConstraint( "foo/1", [new NumberTerm(3)]));
        stack.activate( stack.store.addConstraint( "foo/1", [new NumberTerm(5)]));
        stack.activate( stack.store.addConstraint( "obj/1", [test]));
        stack.processAll();
		
        assertEquals( 8, test.object.getProperty("x") );
		assertEquals( "hello", result[0] );
    }
	
	public function testNegation() {
		var stack = make( ["foo/1","bar/1"], 
        [
			"foo(A), bar(C)  <=> A > C | true.",
			"foo(A), ~bar(A) <=> bar(A)."
        ]);
		
        var A = new Reference();
        var B = new Reference();
        stack.activate( stack.store.addConstraint( "foo/1", [new NumberTerm(3)]));
        stack.activate( stack.store.addConstraint( "bar/1", [new NumberTerm(3)]));
        stack.processAll();
        assertEquals( 2, stack.store.getRemainingConstraints().length );        

        //add foo(4) to remove the bar(3)
        stack.activate( stack.store.addConstraint( "foo/1", [new NumberTerm(4)]));
        stack.processAll();
        assertEquals( 1, stack.store.getRemainingConstraints().length );        
        
		check( ["bar/1 [3]"], stack.store.getRemainingConstraints());
	}
	
	public function testStateMachine() {
		var stack = make(["state/1","message/1","enter/1","exit/1","init/0","history/2"],
		[
    		"init <=> state(a).",
    
            "state(a) \\ message(start) <=> exit(a), enter(b).",
            "state(a) \\ message(test1) <=> exit(a), enter(a1).",
    		
    		"enter(a1), ~state(ab) ==> enter(ab).",
    		"enter(ab), ~state(aa) ==> enter(aa).",
            
            "state(a1) \\ message(test2) <=> exit(a1), exit(ab), enter(a2).",
            
            "state(c) \\ message(go)   <=> exit(c), enter(d).",
            "state(d) \\ message(wait) <=> exit(d), enter(e).",
            "state(i) \\ message(stop) <=> exit(i), enter(j).",
            "state(e) \\ message(stop) <=> exit(e), enter(c).",
            
            "state(f) \\ message(fk) <=> exit(f), enter(k).",
            "state(k) \\ message(kf) <=> exit(k), enter(f).",
            
            "state(g) \\ message(advance) <=> exit(g), enter(h).",
            "state(h) \\ message(advance) <=> exit(h), enter(l).",
            "state(l) \\ message(advance) <=> exit(l), enter(g).",
            
            "state(_) \\ message(_) <=> true.",
            
            //-----------------------
            // Exit Actions
            //-----------------------
           // "state(A), exit(A) ==> write(exiting(A)).",
            
            "exit(A), history(A,B), state(B) ==> exit(B).",
            
            "exit(e) ==> exit(i), exit(j).",
            
            "state(A), exit(A) <=> true.",
            "exit(A)           <=> true.",
            
            //-----------------------
            // Entry Actions 
            //-----------------------
           // "enter(A)  ==> write(entering(A)).",
            "enter(aa) <=> state(aa).",
            "enter(ab) <=> state(ab).",
            "enter(a1) <=> state(a1).",
            
            "enter(b)  <=> state(b), enter(c), enter(f).",
            
            "enter(e)  <=> state(e), enter(i).",
            
            "history(f,S) \\ enter(f) <=> state(f), enter(S).",
            "enter(f)                 <=> state(f), enter(g), history(f,g).",
            
            "enter(g) \\ history(f,S) <=> S \\== g | history(f,g).",
            "enter(h) \\ history(f,S) <=> S \\== h | history(f,h).",
            "enter(l) \\ history(f,S) <=> S \\== l | history(f,l).",
            
            "enter(A)  <=> state(A)."
		]);
		
        stack.activate( stack.store.addConstraint( "init/0", []));
        stack.processAll();		
		check( ["state/1 [a]"], stack.store.getRemainingConstraints());
		
        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("test1")]));
        stack.processAll();     
		check( ["state/1 [aa]","state/1 [ab]","state/1 [a1]"], stack.store.getRemainingConstraints());

        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("test2")]));
        stack.processAll();     
        check( ["state/1 [aa]","state/1 [a2]"], stack.store.getRemainingConstraints());

        stack.store.clear();
        stack.activate( stack.store.addConstraint( "init/0", []));
        stack.processAll();     
        check( ["state/1 [a]"], stack.store.getRemainingConstraints());
        
        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("start")]));
        stack.processAll();     
        check( ["state/1 [b]","state/1 [c]","state/1 [f]","state/1 [g]",
		        "history/2 [f,g]"], 
		       stack.store.getRemainingConstraints());

        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("advance")]));
        stack.processAll();     
        check( ["state/1 [b]","state/1 [c]","state/1 [f]","state/1 [h]",
                "history/2 [f,h]"], 
               stack.store.getRemainingConstraints());

        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("fk")]));
        stack.processAll();     
        check( ["state/1 [b]","state/1 [c]","state/1 [k]",
                "history/2 [f,h]"], 
               stack.store.getRemainingConstraints());

        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("kf")]));
        stack.processAll();     
        check( ["state/1 [b]","state/1 [c]","state/1 [f]","state/1 [h]",
                "history/2 [f,h]"], 
               stack.store.getRemainingConstraints());

        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("go")]));
        stack.processAll();     
        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("wait")]));
        stack.processAll();     
        check( ["state/1 [b]","state/1 [e]","state/1 [f]","state/1 [h]","state/1 [i]",
                "history/2 [f,h]"], 
               stack.store.getRemainingConstraints());

        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("stop")]));
        stack.processAll();     
        check( ["state/1 [b]","state/1 [e]","state/1 [f]","state/1 [h]","state/1 [j]",
                "history/2 [f,h]"], 
               stack.store.getRemainingConstraints());

        stack.activate( stack.store.addConstraint( "message/1", [Atom.unregisteredAtom("stop")]));
        stack.processAll();     
        //trace(stack.store.getRemainingConstraints());
        check( ["state/1 [b]","state/1 [c]","state/1 [f]","state/1 [h]",
                "history/2 [f,h]"], 
               stack.store.getRemainingConstraints());
        
	}
	
	function testCallFromProlog() {
		var db = new Database();
		db.loadString("
            :- chr_constraint foo/1, bar/1.
            
            foo(A), bar(B) <=> B is A + 2. 

            test(A) :- foo(23), bar(A).
        ");
		
		var q = new Query( db, cast TermParse.parse( "test(B)" ) );
		assertEquals( 25.0, q.allBindings()[0].get("B").asNumber().value );
	}
	
	private function check( expected:Array<String>, cons:Array<StoredConstraint> ) {
		var expectedSet = new Map<String,Bool>();
		for( e in expected ) expectedSet.set( e, true );
		
		assertEquals(expected.length, cons.length );
		
		for( c in cons ) {
			assertTrue( expectedSet.exists( c.toDerefString() ) );			
		}
	}
	
	private function make( constraints:Array<String>, rulesrcs:Array<String> ):ActivationStack {
        var store = new ConstraintStore();
        var rules = new ConstraintRules();

        for( functor in constraints ) rules.declareConstraint( functor );
        for( rule    in rulesrcs    ) rules.parseRule( rule );

        return new ActivationStack( rules, store );	
	}
	
}