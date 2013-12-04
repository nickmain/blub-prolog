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
 * functor(?Term, ?Name, ?Arity)
 * 
 * True when Term is a term with functor Name/Arity. If Term is a variable it 
 * is unified with a new term whose arguments are all different variables (such
 * a term is called a skeleton). If Term is atomic, Arity will be unified with
 * the integer 0, and Name will be unified with Term. 
 * 
 * Raises instantiation_error() if term is unbound and Name/Arity is 
 * insufficiently instantiated.
 */
class Functor extends BuiltinPredicate {
	
    public function new() {
		super( "functor", 3 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var term  = args[0].toValue(env);
        var name  = args[1].toValue(env);
        var arity = args[2].toValue(env);
		 
		var termVar = term.asReference();
		if( termVar != null ) {
			var nameAtom = name.asAtom();
			var arityNum = arity.asNumber();

			if( nameAtom == null || arityNum == null || arityNum.value < 0 ) {        
                engine.raiseException( RuntimeError.instantiationError( engine.context ));
				return;
			}
			
			var newTerm:ValueTerm = null;
			var arityVal = Std.int( arityNum.value );
			
			if( arityVal == 0 ) newTerm = nameAtom;
			else {
				var newStru = new Structure( nameAtom );
				for( i in 0...arityVal ) newStru.addArg( new Reference() );
				newTerm = newStru;
			}
			
            engine.unify( term, newTerm );
            return;			
		}
		
		var termAtom = term.asAtom();
		if( termAtom != null ) {
		    if( ! engine.unify( name, termAtom ) ) return;
			engine.unify( arity, new NumberTerm(0) );
			return;
		}
		
		var termStru = term.asStructure();
		if( termStru != null ) {
			if( ! engine.unify( name, termStru.getName() ) ) return;
            engine.unify( arity, new NumberTerm( termStru.getArity() ) );
            return;
		}
		
        engine.raiseException( 
            RuntimeError.typeError( TypeError.VALID_TYPE_compound, 
                                    term, 
                                    engine.context ) );
	}
}
