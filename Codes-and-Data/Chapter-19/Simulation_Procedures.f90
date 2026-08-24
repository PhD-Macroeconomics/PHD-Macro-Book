subroutine Simula(shocks_seqa,SimData)
integer :: jz_lag,jq_lag,t,tt,shocks_seqa(nSim,2)  
real (8) :: Rep_SimData(nRepSim,nSim,12),SimData(nSim,12),SolType

  xGuess=(/rbar,wbar,lbar,dbar,kbar,bbar/)

  do tt=1, nRepSim  

    jz_lag=1
    jq_lag=1
    k=kbar*0.95
    b=bbar

    !-----------SOLVE FOR EQUILIBRIUM AT EACH SIMULATION PERIOD t------------!  

    do t=1, nSim

    !----DRAW SHOCKS----!

      call DrawShocks(jz_lag,jq_lag,jz,jq)

      jz=shocks_seqa(t,1)
      jq=shocks_seqa(t,2)

      z=zVec(jz)
      q=qVec(jq)
      xGuess=(/rbar,wbar,lbar,dbar,kbar,bbar/)*(q/qbar)
      call DNEQNF(SolveBinding,MaxErr,6,MaxIter,xGuess,xReturn,Fnorm)		!--BOUNDING SOLUTION--!
      rv=FindVar(xReturn,6)
      SolType=1
      if (rv(10)<0) then
        xGuess=(/rbar,wbar,lbar,dbar,kbar,bbar/)*(q/qbar)
        call DNEQNF(SolveInterior,MaxErr,6,MaxIter,xGuess,xReturn,Fnorm)		!--NON-BOUNDING SOLUTION--!							
        rv=FindVar(xReturn,6)
        SolType=0
      endif

    !----STORE DATA----!

      SimData(t,1:10)=rv(1:10)
      SimData(t,11)=SolType
      SimData(t,12)=Prod(z,rv(1),rv(5))
      
    !----UPDATE STATES----!

      jz_lag=jz
      jq_lag=jq
      k=rv(6)
      b=rv(7)
  
    end do

    Rep_SimData(tt,:,:)=SimData

    !----print NUMBER OF ITERATIONS----!

    if (mod(tt,50)==0) then
      print *, " NUMBER OF REPEATIONS", tt
    endif

  end do

end subroutine Simula

!===================================================================================
!===================================================================================
  
subroutine DrawShocks(jjz_lag,jjq_lag,jjz,jjq) 
integer :: jjz_lag,jjq_lag,jjz,jjq
real (8) :: xxiDraw(2)

  CALL DRNUN(2,xxiDraw)
  if (xxiDraw(1)<pzMx(jjz_lag,1)) then 
    jjz=1
  else
    jjz=2
  endif
  if (xxiDraw(2)<pqMx(jjq_lag,1)) then 
    jjq=1
  else
    jjq=2
  endif	      	        

end subroutine DrawShocks
