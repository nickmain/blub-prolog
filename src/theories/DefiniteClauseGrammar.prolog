preprocessor( preprocessDCG ).

%==========================================
% Definite Clause Grammars
%==========================================
preprocessDCG(_ ,[],[]) :- !.
preprocessDCG(DB,(Head-->Tail),Out) :- dcg(Head,Tail,Out).

dcg(H,T,Out) :- dcg(T,A,B,T2), H=..H2, append(H2,[A,B],H3), H4=..H3, Out=(H4:-T2).

%----------------------------------------------------------------------------
% Rewrite a term in the body
% T - term in, A - incoming list, B - outgoing list, Out - rewritten term 
%----------------------------------------------------------------------------

dcg((X,Y) ,A,B,Out) :- dcg(X,A,A2,X2), dcg(Y,A2,B,Y2), Out=(X2,Y2), !.
dcg((X;Y) ,A,B,Out) :- dcg(X,A,B,X2),  dcg(Y,A,B,Y2),  Out=(X2;Y2), !.
dcg((!)   ,A,A,(!)) :- !.
dcg((\+T) ,A,B,Out) :- dcg(T,A,B,T2), Out=(\+T2), !.
dcg({Out} ,A,A,Out) :- !.
dcg(T     ,A,B,Out) :- is_list(T), append(T,B,T2), Out=(A=T2), !.

dcg((T>>C),A,B,Out) :- dcg(T,A,B,T2), Out=(T2,list_slice(A,B,C)), !.

dcg((I->T),A,B,Out) :- dcg(I,A,A2,I2),  dcg(T,A2,B,T2),  Out=(I2->T2), !.

dcg('#if_then_else'(I,T,E),A,B,Out) :- 
    dcg(I,A ,A2,I2),
    dcg(T,A2,B ,T2),
    dcg(E,A ,B ,E2),
    Out='#if_then_else'(I2,T2,E2), !.

dcg(T,A,B,Out) :- T=..T2, append(T2,[A,B],T3), Out=..T3.
