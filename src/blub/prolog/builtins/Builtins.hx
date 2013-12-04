package blub.prolog.builtins;

import blub.prolog.Database;

/**
 * Registration for the built-in predicates
 */
class Builtins {

    /**
     * Register the builtins
     */
    public static function register( database:Database ) {
		for( b in builtins ) b.register( database );
	}
	
	static var builtins:Array<BuiltinPredicate> = cast [ 
	    new True(),
		new Fail(),
		new Repeat(),
		new Is(),
		new Unify(),
		new Identical(),
        new NotIdentical(),
		new Cut(),
		new Call(),
		new Once(),
		new NotUnifiable(),
		new NotProvable(),
		new IfThen(),
		new IfThenElse(),
		new AssertA(),
		new AssertZ(),
		new Retract(),
		new Abolish(),
		new Timestamp(),
		new Gensym(),
		new Univ(),
		new Write(),
		new Clear(),
		new Stop(),
		new Functor(),
		new Arg(),
		new AtomCodes(),
		new ListSlice(),
		new Stack(),
		new Member(),
		new Breakpoint(),
		new Listing(),
		new ThrowUp()
	]
	.concat( BinaryArithmeticPred.get() )
	.concat( TermTypes.get() )
    .concat( Globals.get() )
	.concat( RebindVar.get() )
	.concat( blub.prolog.builtins.objects.ObjectBuiltins.get() )
	.concat( blub.prolog.builtins.async.AsyncBuiltins.get() )
	.concat( blub.prolog.builtins.meta.MetaBuiltins.get() );
	//.concat( blub.prolog.builtins.display.DisplayBuiltins.get() );	
}
