  implicit none
	
	integer, parameter	:: Nz				=3            !GRID POINTS for z SHOCK    
	integer, parameter	:: Nq				=3         		!GRID POINTS for xi SHOCK    
	integer, parameter	:: nGrid		=11           !GRID POINTS for CAPITAL & DEBT (k,b) 

	real (8), parameter :: cost_equity	=0.07			!ANNUAL RETURN ON EQUITY             
	real (8), parameter :: cost_borrow	=0.05 		!ANNUAL INTEREST PAID BY FIRMS             


	real (8), parameter :: bbeta		=(1/(1+cost_equity))**(1.0/4.0)		!DISCOUNT FACTOR for HOUSEHOLDS    
	real (8), parameter :: rbar			=1/bbeta-1    										!DISCOUNT FACTOR for FIRMS            
	real (8), parameter :: rbar_net	=(1+cost_borrow)**(1.0/4.0)-1.0 	!DISCOUNT FACTOR for FIRMS            
	real (8), parameter :: tau			=1.0-rbar_net/rbar								!TAX RATE             

	real (8), parameter :: sigma	=1.0					!RISK AVERSION                        

	real (8), parameter :: phi		=0.5					!ENFORCEMENT PARAMETER               
	real (8), parameter :: kappa	=0.5					!EQUITY FINANCE COST                  

	real (8), parameter :: theta	=0.36					!CAPITAL SHARE                        
	real (8), parameter :: delta	=0.02 				!DEPRECIATION RATE                    
	
	real (8), parameter :: kbar		= 1.0					!SET STEADY STATE CAPITAL
	real (8), parameter :: lbar		= 0.36				!SET STEADY STATE LABOR