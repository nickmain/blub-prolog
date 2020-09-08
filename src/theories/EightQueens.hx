package theories;

class EightQueens {
    public static inline var theory = 
"queens([]).                                  % when place queen in empty list, solution found
 
queens([ Row/Col | Rest]) :-                 % otherwise, for each row
            queens(Rest),                    % place a queen in each higher numbered row
            member(Col, [1,2,3,4,5,6,7,8]),  % pick one of the possible column positions
            safe( Row/Col, Rest).            % and see if that is a safe position
                                             % if not, fail back and try another column, until
                                             % the columns are all tried, when fail back to
                                             % previous row
 
safe(_, []).                                 % the empty board is always safe
 
safe(Row/Col, [Row1/Col1 | Rest]) :-         % see if attack the queen in next row down
            Col =\\= Col1,                   % same column?
            Col1 - Col =\\= Row1 - Row,      % check diagonal
            Col1 - Col =\\= Row - Row1,
            safe(Row/Col, Rest).             % no attack on next row, try the rest of board
  
board([1/_, 2/_, 3/_, 4/_, 5/_, 6/_, 7/_, 8/_]).  % prototype board

run_queens(B) :- board(B),queens(B).
";
	
}
