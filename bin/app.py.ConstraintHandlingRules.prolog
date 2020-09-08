preprocessor( preprocessCHR ).

%==========================================
% Constraint Handling Rules (Extended)
%==========================================

preprocessCHR(DB,A,[]) :-  
    constraint_decl(DB,A) ;
	simplification_rule(DB,A) ; 
	propagation_rule(DB,A).  

%----------------------------------------------------------------------------
% 
%----------------------------------------------------------------------------

propagation_rule(DB,(Head ==> Tail)) :- !, 
    Rule <- DB.getConstraintContext(void).newRuleBuilder( term(Head ==> Tail) ),
    Rule.processRuleHead( term( Head ) ),
	Rule.processRuleBody( term( Tail ) ),
    write(propagation_rule(DB,(Head ==> Tail))) .





simplification_rule(DB,(Head <=> Tail)) :- !, write(simplification_rule(DB,(Head <=> Tail))) .




%----------------------------------------------------------------------------
% Constraint declaration directive
%----------------------------------------------------------------------------

constraint_decl(DB,(:- chr_constraint(CC))) :- !, findall(_,declare_constraints( DB, CC ), _).

declare_constraints( DB, (Cons,More) ) :- !,  
    declare_constraint( DB, Cons ),
	declare_constraints( DB, More ).
	
declare_constraints( DB, Cons ) :- declare_constraint( DB, Cons ).
	
declare_constraint( DB, Name/Arity ) :- !,
    DB.declareConstraintPredicate( 'blub.prolog.PredicateIndicator'(term(Name),Arity) ).
	
declare_constraint( DB, Other ) :- throw_up( invalid_constraint_declaration(Other) ).