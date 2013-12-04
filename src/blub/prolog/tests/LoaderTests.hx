package blub.prolog.tests;

import blub.prolog.Database;
import blub.prolog.Predicate;

class LoaderTests extends haxe.unit.TestCase {

    public function testSanity() {
        var src = 
            "mother_child('miss emelia trude', sally).         
            father_child(tom, sally).
            father_child(tom, erica). 
            father_child(mike, tom).              
            sibling(X, Y)      :- parent_child(Z, X), parent_child(Z, Y).                 
            parent_child(X, Y) :- father_child(X, Y).
            parent_child(X, Y) :- mother_child(X, Y).";
            
        var db:Database = new Database();
        db.loadString( src );
        
        assertEquals( 3, db.lookup( PredicateIndicator.fromString("father_child/2") ).clauseCount() );
        assertEquals( 1, db.lookup( PredicateIndicator.fromString("mother_child/2") ).clauseCount() ); 
        assertEquals( 1, db.lookup( PredicateIndicator.fromString("sibling/2"     ) ).clauseCount() ); 
        assertEquals( 2, db.lookup( PredicateIndicator.fromString("parent_child/2") ).clauseCount() ); 
    }
    
    //this was a bug
    public function testCommentProblem() {
        var src = " 
			queens([]).                                  % when place queen in empty list, solution found
			 
			queens([ Row/Col | Rest]) :-                 % otherwise, for each row
			            queens(Rest),                    % place a queen in each higher numbered row
			            member(Col, [1,2,3,4,5,6,7,8]),  % pick one of the possible column positions
			            safe( Row/Col, Rest).            % and see if that is a safe position
			                                             % if not, fail back and try another column, until
			                                             % the columns are all tried, when fail back to
			                                             % previous row
			 
			safe(Anything, []).                          % the empty board is always safe
			 
			safe(Row/Col, [Row1/Col1 | Rest]) :-         % see if attack the queen in next row down
			            Col =\\= Col1,                    % same column?
			            Col1 - Col =\\= Row1 - Row,       % check diagonal
			            Col1 - Col =\\= Row - Row1,
			            safe(Row/Col, Rest).             % no attack on next row, try the rest of board
			 
			board([1/C1, 2/C2, 3/C3, 4/C4, 5/C5, 6/C6, 7/C7, 8/C8]).  % prototype board
			run_queens(B) :- board(B),queens(B).
        ";
            
        var db:Database = new Database();
        db.loadString( src );
        
        assertEquals( 1, db.lookup( PredicateIndicator.fromString("run_queens/1")).clauseCount() );
    }    
}