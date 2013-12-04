package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Atom;
import blub.prolog.terms.Structure;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Reference;
import blub.prolog.engine.QueryEngine;

/**
 * ?Term =.. ?List
 * List is a list which head is the functor of Term and the remaining arguments
 * are the arguments of the term. Each of the arguments may be a variable,
 * but not both.
 */
class Univ extends BuiltinPredicate {
    public function new() {
		super( "=..", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment; 
		var a = args[0].toValue(env);
		var b = args[1].toValue(env);
		
		var refA = a.asReference();
		var refB = b.asReference();
		
		if( refA != null && refB != null ) {
            engine.raiseException( RuntimeError.instantiationError( engine.context ));
            return;			
		}
		
		//LHS is a var
		if( refA != null ) {
			var struB = b.asStructure();
			
			if( struB == null || struB.getName() != Structure.CONS_LIST ) {
                engine.raiseException( 
                    RuntimeError.typeError( TypeError.VALID_TYPE_list, 
                                            b, 
                                            engine.context ) );
				return;				
			}
			
			//gather args
			var args = [];
			var s = struB;
            while( s != null ) {
				var tail = s.argAt(1);
				if( tail == Structure.EMPTY_LIST ) break;
				
				var tailStru = tail.asStructure();
				
                if( tailStru == null || tailStru.getName() != Structure.CONS_LIST ) {
                    engine.raiseException( RuntimeError.instantiationError( engine.context ));
                    return;             
                }
				
				args.push( tailStru.argAt(0) );				
				s = tailStru;
			}
			
			//new atom
			if( args.length == 0 ) {
				engine.unify( refA, cast struB.argAt(0) );
				return;			
			}

            //for new structure the name must be an atom
            var name = struB.argAt(0).asAtom();
            if( name == null ) {
                engine.raiseException( 
                    RuntimeError.typeError( TypeError.VALID_TYPE_atom, 
                                            struB.argAt(0), 
                                            engine.context ) );
                return;                             
            }
						
			var newStru = new Structure( name, args );
            engine.unify( refA, newStru );
            return;         			
		}
		
		//LHS is atom or struct
		var lhsList = null;
		
		var lhsAtom = a.asAtom();
		if( lhsAtom != null ) {
			//make [lhsAtom]
			lhsList = Structure.makeList(cast [ lhsAtom ]);						
		}
		else {
			var lhsStru = a.asStructure();
			
			if( lhsStru == null ) {
                engine.raiseException( 
                    RuntimeError.typeError( TypeError.VALID_TYPE_compound, 
                                            a, 
                                            engine.context ) );			
                return;	
			}
			
			var elems = new Array<Term>();
			elems.push( lhsStru.getName() );
			for( arg in lhsStru.getArgs() ) elems.push( arg );  
			
			lhsList = Structure.makeList(elems);
		}
		
		engine.unify( lhsList, b );		
	}
}
