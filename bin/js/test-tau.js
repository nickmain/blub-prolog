var session;

function testTau() {
    TimingTests.log("Starting Tau Prolog...");

    if(!session) {
        session = pl.create(20000);
    }
    
    session.consult("\
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
", {
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