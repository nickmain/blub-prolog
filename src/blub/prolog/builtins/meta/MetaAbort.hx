package blub.prolog.builtins.meta;

import blub.prolog.PrologException;
import blub.prolog.terms.Term;
import blub.prolog.terms.Atom;
import blub.prolog.Query;
import blub.prolog.engine.QueryEngine;

import blub.prolog.builtins.meta.MetaQuery;

/**
 * Abort a query created by query/3.
 * 
 * abort(Query)
 *     Query is the reference returned by query/3
 *     
 * If the query has already been aborted then this does nothing.
 * Aborting the query will halt the QueryEngine and null the reference to the
 * Query. Any subsequent calls to solution/2 will fail.
 */
class MetaAbort extends BuiltinPredicate {

    public function new() {
		super( "abort", 1 );
	}
	
	override function execute( engine:QueryEngine, args:Array<Term> ) {
		var env = engine.environment;
		var atom = args[0].toValue(env).dereference().asAtom();
		
		if( atom == null || atom.object == null ) return;
		if( ! Std.is( atom.object, TemplateQuery ) ) return;
		
		var query:TemplateQuery = cast atom.object;
		
		query.halt();
		atom.object = null;
	}
}
