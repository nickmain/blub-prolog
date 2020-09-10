var session;

function testTauOKeefe() {
    testTauTheory("\
:- use_module(library(lists)).\
queens(Queens) :- \
    board(Queens, Board, 0, 8, _, _), queens(Board, 0, Queens).\
\
board([], [], N, N, _, _).\
board([_|Queens], [Col-Vars|Board], Col0, N, [_|VR], VC) :-\
    Col is Col0+1,\
    functor(Vars, f, N),\
    constraints(N, Vars, VR, VC),\
    board(Queens, Board, Col, N, VR, [_|VC]).\
\
constraints(0, _, _, _) :- !.\
constraints(N, Row, [R|Rs], [C|Cs]) :-\
    arg(N, Row, R-C),\
    M is N-1,\
    constraints(M, Row, Rs, Cs).\
\
queens([], _, []).\
queens([C|Cs], Row0, [Col|Solution]) :-\
    Row is Row0+1,\
    select(Col-Vars, [C|Cs], Board),\
    arg(Row, Vars, Row-Row),\
    queens(Board, Row, Solution).\
\
run_queens(B) :- B= [_,_,_,_,_,_,_,_], queens(B).\
");
}

function testTau() {
    testTauTheory("\
    :- use_module(library(lists)).\
    queens([]).\
    queens([ Row/Col | Rest]) :-\
                queens(Rest),\
                member(Col, [1,2,3,4,5,6,7,8]),\
                safe( Row/Col, Rest).\
    safe(_, []).\
    safe(Row/Col, [Row1/Col1 | Rest]) :-\
                Col =\\= Col1,\
                Col1 - Col =\\= Row1 - Row,\
                Col1 - Col =\\= Row - Row1,\
                safe(Row/Col, Rest).\
    board([1/_, 2/_, 3/_, 4/_, 5/_, 6/_, 7/_, 8/_]).\
    run_queens(B) :- board(B), queens(B).\
");
}

function testTauTheory(theory) {
    TimingTests.log("Starting Tau Prolog...");

    if(!session) {
        session = pl.create(20000);
    }
    
    session.consult(theory, {
    success: function() { 
        TimingTests.log("[Tau]: loaded theory");

        session.query("get_time(Start), findall(B, run_queens(B), X), length(X, Count), get_time(End), Time is End - Start.", {
            success: function(goal) { 
                getAnswers();
            },
            error: function(err) { TimingTests.log("[Tau]: " + err); }
        });
    },
    error: function(err) { 
        TimingTests.log("[Tau]: " + err);
    }
    });

    function getAnswers() {
        session.answer({
            success: function(answer) {
                TimingTests.log("[Tau]: answer: " + answer);
            },
            error: function(err) { TimingTests.log("[Tau]: " + err); },
            fail:  function() { TimingTests.log("[Tau]: fail"); },
            limit: function() { TimingTests.log("[Tau]: limit exceeded"); }
        });
    }
}