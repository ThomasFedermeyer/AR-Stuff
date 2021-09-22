# AR-Stuff

project from senior year in highschool using arkit to play a 3d billiards game.

todo--

improving the data format 

1) make the data that gets passed over all at once ex: when passing balls add them all to an 
   array and transfer he array into text format and itnerate though on the other end
2) when creating the balls add them all to a central object array where you can easly look at each 
   one and actualy destoy them
3) for the ending check when the 8-ball get hit in and then check to see if all the players balls 
   have been destoryed if not they lose 
4) create create function because the way i have it set up right now is ass and i all the walls 
   and balls are being created septeratly
   

arena improvemt 

1) use proper euler angels to match the rotation of the field to the surface hte player deteced 
2) set a loer and uper bound for the arena size 
3) scale the goals based on the size of the arena 
4) proper scaler for Y val based on the X and Z vales 
5) ask someone to help with the arena to make it look good insed of using transparent colors 

UI

1) add a tital screne 
2) add a game select where you can chose local or online play 
3) move to the camer scenre when you match with an oppenet 
4) add a nice game over/ winning overlay (i might destory the arena and add the 3d model of 
   the match result over the plane and i can even add like confety or some shit 
5) add a screen for remathc 
6) retun the user to the tital screne when they end the match and select no rematch

improving the gameplay

1) add nice pysics what i have right now sucks ass
2) add a vertical vector when a ball touches the bottom/floor so the ball doesnt get stuck there 
3) add alow the player to angle the phone veriacaly and get data from that to implamet into the 
   create ball function for a vertial aspect of the vecotr 
4) scale the balls based on the size of the arena 
5) add a good starting paturn for the balls and tell the player which are theirs

https://developer.apple.com/documentation/gamekit

https://developer.apple.com/documentation/gamekit/finding_multiple_players_for_a_game

https://developer.apple.com/documentation/gamekit/exchanging_your_game_data_between_players

https://developer.apple.com/documentation/gamekit/gkmatch
