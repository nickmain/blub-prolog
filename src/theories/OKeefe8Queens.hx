package theories;

class OKeefe8Queens {
    public static inline var theory = 
"queens(Queens) :-
    board(Queens, Board, 0, 8, _, _),
    queens(Board, 0, Queens).

board([], [], N, N, _, _).
board([_|Queens], [Col-Vars|Board], Col0, N, [_|VR], VC) :-
    Col is Col0+1,
    functor(Vars, f, N),
    constraints(N, Vars, VR, VC),
    board(Queens, Board, Col, N, VR, [_|VC]).

constraints(0, _, _, _) :- !.
constraints(N, Row, [R|Rs], [C|Cs]) :-
    arg(N, Row, R-C),
    M is N-1,
    constraints(M, Row, Rs, Cs).

queens([], _, []).
queens([C|Cs], Row0, [Col|Solution]) :-
    Row is Row0+1,
    select(Col-Vars, [C|Cs], Board),
    arg(Row, Vars, Row-Row),
    queens(Board, Row, Solution).

run_queens(B) :- B= [_,_,_,_,_,_,_,_], queens(B).

select(X, [Head|Tail], Rest) :-
    select3_(Tail, Head, X, Rest).

select3_(Tail, Head, Head, Tail).
select3_([Head2|Tail], Head, X, [Head|Rest]) :-
    select3_(Tail, Head2, X, Rest).
";
	
}
