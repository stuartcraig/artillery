/*-------------------------------------------------------------artillery.ado
This ado file defines the run programs for a Stata-based artillery game.
To date, this has been tested on the Mac GUI version of Stata 14.1 and
Stata 12.0.

Stuart Craig
Last updated 20180103
*/

version 12.0


/*
------------------------------------------------

Program to draw/animate the game board 

------------------------------------------------
*/

	cap prog drop artillery_drawgameboard
	prog define artillery_drawgameboard
		args target pos_x pos_y b1 b2 b3 b4
		
		if `pos_x'>0&`pos_y'>0 {
			* di _newline(20)
			di _newline(`=71 - `pos_y'')
			di as text _column(`pos_x') "*"
			di _newline(`=`pos_y'+1')
		}
		else di _newline(70)
		
		di as text "`b1'" _c
		di as result "`b2'" _c
		di in red "`b3'" _c
		di as result "`b4'" _c
	
	end

/*
------------------------------------------------

Program to draw the final hit (success or not)

------------------------------------------------
*/

	cap prog drop artillery_drawhit
	prog define artillery_drawhit
		args x_end target
		
		// Clear the game board
		di _newline(70)
		// Draw the cannon
		di as text " // " _c
		
		// Did you hit the target?
		cap assert inrange(`x_end',`target'-1,`target'+1)
		if _rc!=0 {
			forval i=3/99 {
				if inrange(`i',`x_end'-1,`x_end'+1) di in red " " _c
				else {
					if `i'==`target' di in red "X" _c
					else di as result "=" _c
				}
			}
		}
		else {
			forval i=3/99 {
				if inrange(`i',`x_end'-1,`x_end'+1) di in red "_" _c
				else di as result "=" _c
			}
		}
	end
	
/*
------------------------------------------------

Program to run the game loop with prompts
for 
- velocity
- angle
- continue y/n

------------------------------------------------
*/

	cap program drop artillery_gameloop
	prog define artillery_gameloop
	
		// Assign target location (need to randomize)
		* loc targ=60 // just a testing value
		loc targ = 30+ round(70*runiform())
		
		
		// "Draw" board up front (saves time in the animation)
		loc boardstring1 " // "
		loc boardstring2 ""
		forval x=3/`=`targ'-1' {
			loc boardstring2 "`boardstring2'="
		}
		loc boardstring3 "X"
		loc boardstring4 ""
		forval x=`=`targ'+1'/99 {
			loc boardstring4 "`boardstring4'="
		}
		
		loc on=1
		while `on'==1 {
		
		// Prompt for input
			artillery_drawgameboard `targ' 0 0 ///
				"`boardstring1'" "`boardstring2'" "`boardstring3'" "`boardstring4'"
			di ""
			loc theta=-9 
			while `theta'==-9 {
				di "Select angle (0-90 degrees)", _request(theta)
				if lower("${theta}")=="quit" exit
				cap assert inrange(${theta},0,90)
				if _rc==0 loc theta=${theta}
			}
			loc v=-9
			while `v'==-9 {
				di "Select velocity (0-100)", _request(v)
				if lower("${v}")=="quit" exit
				cap assert inrange(${v},0,100)
				if _rc==0 loc v=${v}
			}
		// Where does the flight path end?
			loc theta = `theta'*c(pi)/180
			loc v	  = `v'*(7/100)+8 // 8-15?
			loc g	  = 1.5
			
			loc T = 2*`v'*sin(`theta')/`g'
			loc x_end = round(`v'*`T'*cos(`theta'))
			loc T = round(`T')
			
			// Is it a hit?
			loc hit=0
			if inrange(`x_end',`targ'-1,`targ'+1) loc hit=1
			
		// Draw the flight path	
			loc x = 0 // we start at (0,0)
			loc y = 0
			// Calculate up front to smooth the animation
			forval t=1/`T' {
				loc x`t'=round(`v'*`t'*cos(`theta'))
				loc y`t'=round(`v'*`t'*sin(`theta') - 0.5*`g'*`t'^2)
			}	
			// Animate
			forval t=1/`T' {
				artillery_drawgameboard `targ' `x`t'' `y`t'' ///
					"`boardstring1'" "`boardstring2'" "`boardstring3'" "`boardstring4'"
				di ""
				di ""
				di ""
				sleep 500
			}
		
		// Draw final position and prompt for next step
			artillery_drawhit `x_end' `targ'
			if `hit'==0 {
				di ""
				di as result "Not quite..."
				loc try=""
				while "`try'"=="" {
					di as result "Try again, y/n?", _request(try)
					if lower("${try}")=="quit" exit
					if inlist(lower("${try}"),"y","n") loc try=lower("${try}")
				}
				if "`try'"=="n" loc on=0
				
			}
			if `hit'==1 {
				di ""
				di as result "Success!!!"
				loc again ""
				while "`again'"=="" {
					di as result "Play again, y/n?", _request(again)
					if lower("${again}")=="quit" exit
					if inlist(lower("${again}"),"y","n") loc again=lower("${again}")
				}	
				if "`again'"=="n" loc on=0
				// Re-draw the target var if we're continuing
				else loc targ = 30+ round(70*runiform())
			}
		}
	end
	
/*
------------------------------------------------

Main wrapper 

------------------------------------------------
*/

	cap prog drop artillery
	prog define artillery
	
		di _newline(70)
		di as result "======================================================"
		di as text " Welcome to ARTILLERY, enter anything to continue"
		di as text " Quit any time by typing 'quit'"
		di as result "======================================================", _request(begin)
		if lower("${begin}")=="quit" exit
		artillery_gameloop
	
	end
	


exit

