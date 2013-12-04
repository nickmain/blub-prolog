package blub.prolog.builtins;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.terms.NumberTerm;
import blub.prolog.terms.Structure;
import blub.prolog.terms.ValueTerm;
import blub.prolog.terms.Reference;
import blub.prolog.engine.QueryEngine;
import blub.prolog.engine.parts.ChoicePoint;

/**
 * atom_codes(?Atom, ?String)
 * 
 * Convert between an atom and a list of character codes. If Atom is 
 * instantiated, if will be translated into a list of character codes and the 
 * result is unified with String. If Atom is unbound and String is a list of 
 * character codes, Atom will be unified with an atom constructed 
 * from this list.
 */
class AtomCodes extends BuiltinPredicate {
	
    public function new() {
		super( "atom_codes", 2 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var atomArg   = args[0].toValue(env);
        var stringArg = args[1].toValue(env);
		 
		var atom = atomArg.asAtom();
		if( atom != null ) {
            var text = atom.text;
			var len = text.length;
            
			var codes = new Array<Term>();
			for( i in 0...len ) codes.push( new NumberTerm(text.charCodeAt( i )));
            engine.unify( Structure.makeList(codes), stringArg );
			return;
		}
		 
		var atomRef = atomArg.asReference();
		if( atomRef == null ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_atom, 
                                        atomArg, 
                                        engine.context ) );
            return;                                                 
        } 
	
	    var codeList = stringArg.asStructure();
		if( codeList == null ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_list, 
                                        stringArg, 
                                        engine.context ) );
            return;                                                 
        } 
		 
		var codes = codeList.toArray();
        if( codes == null ) {
            engine.raiseException( 
                RuntimeError.typeError( TypeError.VALID_TYPE_list, 
                                        codeList, 
                                        engine.context ) );
            return;                                                 
        } 
		
		var buf = new StringBuf();
		
		for( t in codes ) {
			var code = t.asNumber();
			
			if( code == null ) {
                engine.raiseException( RuntimeError.typeError( TypeError.VALID_TYPE_number, t, engine.context ) );
                return;                                                 
            } 
			
			buf.addChar( Std.int( code.value ));
		}
		
		engine.unify( Atom.unregisteredAtom( buf.toString() ), atomRef );        		 
	}

}
