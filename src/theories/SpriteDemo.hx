package theories;

class SpriteDemo {
    public static inline var theory = "
test :-
    spawn { receive(more_sprites,at(N)), test2(N) },
    spawn test(0).

test(N) :- sleep( 200 ),
    sprite(N,N), 
    N2 is N + 20,
    N2 =< 160 ->
        test(N2) ;
        send(more_sprites,at(20)).

test2(N) :- sleep( 300 ),
    X is 300 - N,
    sprite(X,N), 
    N2 is N + 20,
    N2 =< 160 ->
        test2(N2) ;
        write('Done !!').

sprite( X, Y ) :-
   sprite(S), 
   S.x <- X, S.y <- Y,
   spawn { receive(sprites,die), kill_sprite( S ) },
   spawn flash_sprite(S,0xffff00,0x00ff00).

flash_sprite(Sprite,C1,C2) :-
    paint(Sprite,C1),    
    sleep(1000),
    P <- Sprite.parent,
    P \\= null ->        
        flash_sprite(Sprite,C2,C1).

paint(Sprite,Color) :- 
    G <- Sprite.graphics,
    G.clear(void),
    G.beginFill( Color, 1 ),
    G.lineStyle( 0, 0 ),
    G.drawEllipse( 0, 0, 100, 60 ),
    G.endFill(void).

";
}
