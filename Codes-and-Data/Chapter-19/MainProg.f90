program MainProgram

  include 'link_fnl_shared.h'
  USE numerical_libraries

  include 'Param.f90'

  real (8), parameter :: MaxErr=1e-15

  integer, parameter	:: MaxIter=300       
	integer, parameter	:: nPreSim=200       
	integer, parameter	:: nSim		=nPreSim+30       
	integer, parameter	:: nRepSim=1

  real (8), parameter :: update=1.0

!----------------PARAMETER FOR SHOCKS---------------!

	real (8), parameter :: dz			=0.01				!VARIATION IN PRODUCTIVITY SHOCK
	real (8), parameter :: zpers	=0.9				!PERSISTENT PROBABILITY FOR z   
	real (8), parameter :: qbar		=1.0				!AVERAGE xi         
	real (8), parameter :: dq			=0.1				!VARIATION xi
	real (8), parameter :: qpers	=0.9 				!PERSISTENCE xi   

!-------------------------------------------------------------!

	integer  :: jz,jq,i,ii,iii,iter,t,SolArray(Nz,Nq,nGrid,nGrid),shocks_seqa(nSim,2)
	real (8) :: zVec(Nz),qVec(Nq),ssGuess(6),ssReturn(6),Fnorm,PolArray(Nz,Nq,nGrid,nGrid,12)
	real (8) :: zbar,bbar,wbar,mubar,kmin,kmax,bkmin,bkmax,qmin,qmax,zmin,zmax
	real (8) :: vvkMx(Nz,Nq,nGrid,nGrid),vvbMx(Nz,Nq,nGrid,nGrid),uucMx(Nz,Nq,nGrid,nGrid)
	real (8) :: GuessMx(Nz,Nq,nGrid,nGrid,6),xGuess(6),xReturn(6),rv(13),ErrVal,uc
  real (8) :: SimData(nSim,12)
  character(len=200) :: item_format,print_format

	real (8) :: dbar,nu,z,q,k,b,pzMx(Nz,Nz),pqMx(Nq,Nq),kVec(nGrid),bkVec(nGrid) 
	real (8) :: vkMx(Nz,Nq,nGrid,nGrid),vbMx(Nz,Nq,nGrid,nGrid),ucMx(Nz,Nq,nGrid,nGrid)
	common dbar,nu,z,q,k,b,pzMx,pqMx,kVec,bkVec,vkMx,vbMx,ucMx,jz,jq
	external FindSSS,SolveBinding,SolveInterior

	CALL ERSET (0, 0, 0)

!----------FIND nu, ZBAR and STEADY STATE VARIABLES----------!

	mubar=((1+rbar)/(1+rbar*(1-tau))-1)
	zbar=((1+mubar)/(bbeta*(1+mubar))-1+delta)*kbar**(1-theta)/(theta*lbar**((1-theta)))
	wbar=(1-theta)*zbar*kbar**(theta)*lbar**((1-theta)-1)

	q=qbar

	ssGuess(1)=0.5
	ssGuess(2)=zbar
	ssGuess(3)=0.01
	ssGuess(4)=0.1
	ssGuess(5)=wbar
	ssGuess(6)=mubar

	call DNEQNF(FindSSS,MaxErr,6,MaxIter,ssGuess,ssReturn,Fnorm)

	nu=ssReturn(1)
	zbar=ssReturn(2)
	dbar=ssReturn(3)
	bbar=ssReturn(4)
	wbar=ssReturn(5)
	mubar=ssReturn(6)

!----CONSTRUCT SHOCKS and TRANSITION Mx (TO BE CHANGED IF N. OF SHOCKS CHANGES)----!

	zmin=zbar*(1-dz)
	zmax=zbar*(1+dz)
	qmin=qbar*(1-dq)			   
	qmax=qbar*(1+dq)			   

	zVec=(/zmin,zbar,zmax/)
	pzMx(1,:)=(/zpers,(1-zpers)*3.0/4.0,(1-zpers)*1.0/4.0/)
	pzMx(2,:)=(/(1-zpers)/2.0,zpers,(1-zpers)/2.0/)
	pzMx(3,:)=(/(1-zpers)*1.0/4.0,(1-zpers)*3.0/4.0,zpers/)

	qVec=(/qmin,qbar,qmax/)
	pqMx(1,:)=(/qpers,(1-qpers)*3.0/4.0,(1-qpers)*1.0/4.0/)
	pqMx(2,:)=(/(1-qpers)/2.0,qpers,(1-qpers)/2.0/)
	pqMx(3,:)=(/(1-qpers)*1.0/4.0,(1-qpers)*3.0/4.0,qpers/)


!----------PRINT PARAMETERS----------!

	print '(a,f8.3)', "zbar                          =", zbar
	print '(a,f8.3)', "Discount factor, beta         =", bbeta
	print '(a,f8.3)', "Risk aversion, sigma          =", sigma
	print '(a,f8.3)', "Share of consumption, nu      =", nu
	print '(a,f8.3)', "Production parameter, theta   =", theta
	print '(a,f8.3)', "Repudiation parameter, phi    =", phi
	print '(a,f8.3)', "New shares cost, kappa        =", kappa
	print '(a,f8.3)', "Tax rate, tau                 =", tau
	print '(a,f8.3)', "Interest rate                 =", rbar
	print '(a,f8.3)', "Net interest rate             =", rbar_net	
	print '(a,4f8.3)', "Productivity shock            =", zVec,zpers	
	print '(a,4f8.3)', "Financial shock               =", qVec*phi,qpers	
	print *, ""

!***********************************************************************				
!*													ITERATION SECTION     									   *
!***********************************************************************

!----SET CAPITAL AND DEBT GRID and INITIALIZE GUESSES----!

	kmin=kbar*0.8
	kmax=kbar*1.2

 	bkmin=qmin*phi*0.9
	bkmax=qmax*phi

	do i=1, nGrid
		kVec(i)=kmin+((kmax-kmin)/(nGrid-1))*(i-1)
		bkVec(i)=bkmin+((bkmax-bkmin)/(nGrid-1))*(i-1)
	end do

	do jz=1,Nz
		do jq=1,Nq
			do i=1,nGrid
				do ii=1,nGrid
					uc=Ucfun(lbar*wbar+bbar-bbar/(1+rbar)+varphi(dbar),lbar)
					vkMx(jz,jq,i,ii)=(Fk(zbar,kbar,lbar)/varphider(dbar))*uc
					vbMx(jz,jq,i,ii)=-uc/varphider(dbar)
					ucMx(jz,jq,i,ii)=uc
					GuessMx(jz,jq,i,ii,1)=rbar
					GuessMx(jz,jq,i,ii,2)=wbar
					GuessMx(jz,jq,i,ii,3)=lbar
					GuessMx(jz,jq,i,ii,4)=dbar
					GuessMx(jz,jq,i,ii,5)=kVec(i) 
					GuessMx(jz,jq,i,ii,6)=bkVec(ii)*kVec(i) 
				end do
			end do
		end do
	end do


!----ITERATE UNTIL CONVERGENCE----!

	iter=1
	ErrVal=1000
	do while ((ErrVal>1e-6) .and. (iter<2000))

  !----SOLVE AT EACH GRID POINT----@

	  do jz=1, Nz
		  z=zVec(jz)
			do jq=1, Nq
			  q=qVec(jq)
				do i=1, nGrid
					k=kVec(i)
					do ii=1, nGrid
						b=bkVec(ii)*k
						xGuess=GuessMx(jz,jq,i,ii,:)
						call DNEQNF(SolveBinding,MaxErr,6,MaxIter,xGuess,xReturn,Fnorm)		!--BOUNDING SOLUTION--!
						rv=FindVar(xReturn,6)
						SolArray(jz,jq,i,ii)=1
						if (rv(10)<0) then
							call DNEQNF(SolveInterior,MaxErr,6,MaxIter,xGuess,xReturn,Fnorm)		!--NON-BOUNDING SOLUTION--!							
							rv=FindVar(xReturn,6)
							SolArray(jz,jq,i,ii)=0
						endif
						vvkMx(jz,jq,i,ii)=rv(11)    
						vvbMx(jz,jq,i,ii)=rv(12)    
						uucMx(jz,jq,i,ii)=rv(13)   
						PolArray(jz,jq,i,ii,1:10)=rv(1:10) 
						PolArray(jz,jq,i,ii,11)=rv(7)/(1+rv(3)*(1-tau))
						PolArray(jz,jq,i,ii,12)=q*phi*rv(6)
					end do
				end do
			end do
		end do

  !----COMPUTE ITERATION ERROR and UPDATE----!

		ErrVal=sum(abs(vvkMx-vkMx)+abs(vvbMx-vbMx)+abs(uucMx-ucMx))

		vkMx=vkMx+(vvkMx-vkMx)*update
		vbMx=vbMx+(vvbMx-vbMx)*update
		ucMx=ucMx+(uucMx-ucMx)*update

  !----print ITERATION ERROR----!

		if (mod(iter,20)==0) then
			print *, iter, ErrVal, Fnorm
		endif

		iter=iter+1

	end do


!***********************************************************************				
!*															PRINT RESULTS     									   *
!***********************************************************************

print *, ""
print '(a,4f8.3)', "kmin and kmax   ", kmin, minval(PolArray(:,:,:,:,6)), maxval(PolArray(:,:,:,:,6)), kmax
print '(a,4f8.3)', "bkmin and bkmax ", bkmin, minval(PolArray(:,:,:,:,7)), maxval(PolArray(:,:,:,:,7)), bkmax
print *, ""

!***********************************************************************				 
!*													SAVE GUESS FUNCTIONS   									   *
!***********************************************************************

	open(1,FILE='Simulation\Parameters.agl')
		write (1, '(i5)') Nz
		write (1, '(i5)') Nq
		write (1, '(i5)') nGrid
		write (1, '(i5)') nPreSim
		write (1, '(i5)') nSim
	close(1)

	open(1,FILE='Simulation\kVec.agl')
	open(2,FILE='Simulation\bkVec.agl')
		do i=1, nGrid
			write (1, '(f25.18)') kVec(i)
			write (2, '(f25.18)') bkVec(i)
		end do
	close(1)
	close(2)

	open(1,FILE='Simulation\Borrowing.agl')
	open(2,FILE='Simulation\Borrowing_Limit.agl')
		do jz=1, Nz
			do jq=1, Nq
				do i=1, nGrid
					do ii=1, nGrid
						write (1, '(\f25.18)') PolArray(jz,jq,i,ii,11)
						write (2, '(\f25.18)') PolArray(jz,jq,i,ii,12)
					end do
					write (1, '(\a/)'), ""
					write (2, '(\a/)'), ""
				end do
			end do
		end do
	close(1)
	close(2)

!***********************************************************************				 
!*											 STOCHASTIC SIMULATION    									   *
!***********************************************************************

shocks_seqa(:,1)=2
shocks_seqa(:,2)=2

shocks_seqa(nPreSim+1:nSim,2)=3
call Simula(shocks_seqa,SimData)
open(1,FILE='Simulation\CreditExpansion.agl')
  do t=1, nSim
    write (1,'(i3,4f9.4)'), t, SimData(t,11), SimData(t,10), SimData(t,7), SimData(t,12)
  end do
close(1)

shocks_seqa(nPreSim+1:nSim,2)=1
call Simula(shocks_seqa,SimData)
open(1,FILE='Simulation\CreditContraction.agl')
  do t=1, nSim
    write (1,'(i3,4f9.4)'), t, SimData(t,11), SimData(t,10), SimData(t,7), SimData(t,12)
  end do
close(1)


shocks_seqa(:,1)=2
shocks_seqa(:,2)=2

shocks_seqa(nPreSim+1:nSim,1)=3
call Simula(shocks_seqa,SimData)
open(1,FILE='Simulation\ProductExpansion.agl')
  do t=1, nSim
    write (1,'(i3,4f9.4)'), t, SimData(t,11), SimData(t,10), SimData(t,7), SimData(t,12)
  end do
close(1)

shocks_seqa(nPreSim+1:nSim,1)=1
call Simula(shocks_seqa,SimData)
open(1,FILE='Simulation\ProductContraction.agl')
  do t=1, nSim
    write (1,'(i3,4f9.4)'), t, SimData(t,11), SimData(t,10), SimData(t,7), SimData(t,12)
  end do
close(1)



!***********************************************************************				
!***********************************************************************				
!*										  FUNCTIONS AND PROCEDURES   									   *
!***********************************************************************				
!***********************************************************************

	contains
	include 'Routines.f90'
	include 'Simulation_Procedures.f90'

!*********************************************************************************

	function FindVar(XX,NN) result (rv)
	include 'Param.f90'
	integer :: NN,jjz,jjq
	real (8) :: XX(NN),r,w,d,l,c,kpr,bpr,costder,mu,Uc,Rnet
	real (8) :: Vkpr,Vbpr,Ucpr,EVk,EVb,rv(13),taxes
	real (8) :: vkMx(Nz,Nq,nGrid,nGrid),vbMx(Nz,Nq,nGrid,nGrid),ucMx(Nz,Nq,nGrid,nGrid)	
		r=XX(1)
		w=XX(2)
		l=XX(3)
		d=XX(4)
		kpr=XX(5)
		bpr=XX(6)
		EVk=0.0
		EVb=0.0
		do jjz=1,Nz
			do jjq=1,Nq
				Vkpr=AppFun2D(kVec,nGrid,bkVec,nGrid,vkMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
				Vbpr=AppFun2D(kVec,nGrid,bkVec,nGrid,vbMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
				EVk=EVk+pzMx(jz,jjz)*pqMx(jq,jjq)*Vkpr
				EVb=EVb+pzMx(jz,jjz)*pqMx(jq,jjq)*Vbpr
			end do
		end do
		Rnet=1+r*(1-tau)		
		costder=varphider(d)
		taxes=(1/Rnet-1/(1+r))*bpr
		c=w*l+b-bpr/(1+r)+d-taxes
		Uc=Ucfun(c,l)
		mu=Fl(z,k,l)/w-1.0

		rv(1)=k
		rv(2)=b
		rv(3)=r
		rv(4)=w
		rv(5)=l
		rv(6)=kpr
		rv(7)=bpr
		rv(8)=d
		rv(9)=c
		rv(10)=mu
		rv(11)=Fk(z,k,l)*Uc/costder
		rv(12)=-Uc/costder
		rv(13)=Uc

	end function FindVar


!*********************************************************************************


END PROGRAM MainProgram


!*********************************************************************************				
!*										  EXTERNAL FUNCTIONS AND PROCEDURES	   									   *
!*********************************************************************************


subroutine FindSSS(XX,FF,NN)
include 'Param.f90'
integer :: NN,jz,jq
real (8) :: XX(NN),FF(NN),dd,bb,kk,ll,cc,ww,mmu,UUc,VVk,VVb,taxes,Rnet,costder
real (8) :: dbar,nu,z,q,k,b,pzMx(Nz,Nz),pqMx(Nq,Nq),kVec(nGrid),bkVec(nGrid) 
real (8) :: vkMx(Nz,Nq,nGrid,nGrid),vbMx(Nz,Nq,nGrid,nGrid),ucMx(Nz,Nq,nGrid,nGrid)	
common dbar,nu,z,q,k,b,pzMx,pqMx,kVec,bkVec,vkMx,vbMx,ucMx,jz,jq

	nu=xx(1)
	z=xx(2)
	dd=xx(3)
	bb=xx(4)
	ww=xx(5)
	mmu=xx(6)
	kk=kbar
	ll=lbar
	Rnet=1+rbar*(1-tau)
	taxes=(1/Rnet-1/(1+rbar))*bb
	cc=ww*ll+bb-bb/(1+rbar)+dd-taxes
	UUc=Ucfun(cc,ll)
	costder=varphider(dd)
	VVk=(Fk(z,kk,ll)/costder)*UUc
	VVb=-(1.0/costder)*UUc
	FF(1)=Fl(z,kk,ll)-(1+mmu)*ww
	FF(2)=F(z,kk,ll)-ww*ll-bb+bb/Rnet-kk-varphi(dd)
	FF(3)=q*phi*kk-bb/Rnet
	FF(4)=bbeta*VVk-((1-mmu*q*phi)/costder)*UUc
	FF(5)=bbeta*VVb+((1-mmu)/(costder*Rnet))*UUc
	FF(6)=UUc*ww-Ulfun(cc,ll)

	contains
	include 'Routines.f90'

end subroutine FindSSS


!*********************************************************************************

subroutine SolveBinding(XX,FF,NN)
include 'Param.f90'
integer :: NN,jjz,jjq,zindex,jz,jq
real (8) :: XX(NN),FF(NN),r,w,d,l,c,kpr,bpr,costder,mu,Uc,Rnet
real (8) :: Vkpr,Vbpr,Ucpr,EVk,EVb,EUc,taxes
real (8) :: dbar,nu,z,q,k,b,pzMx(Nz,Nz),pqMx(Nq,Nq),kVec(nGrid),bkVec(nGrid) 
real (8) :: vkMx(Nz,Nq,nGrid,nGrid),vbMx(Nz,Nq,nGrid,nGrid),ucMx(Nz,Nq,nGrid,nGrid)	
common dbar,nu,z,q,k,b,pzMx,pqMx,kVec,bkVec,vkMx,vbMx,ucMx,jz,jq

  r=XX(1)
  w=XX(2)
  l=XX(3)
  d=XX(4)
  kpr=XX(5)
  bpr=XX(6)
  EVk=0.0
  EVb=0.0
  EUc=0.0
  do jjz=1,Nz
	  do jjq=1,Nq
	    Vkpr=AppFun2D(kVec,nGrid,bkVec,nGrid,vkMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
	    Vbpr=AppFun2D(kVec,nGrid,bkVec,nGrid,vbMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
	    Ucpr=AppFun2D(kVec,nGrid,bkVec,nGrid,ucMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
	    EVk=EVk+pzMx(jz,jjz)*pqMx(jq,jjq)*Vkpr
	    EVb=EVb+pzMx(jz,jjz)*pqMx(jq,jjq)*Vbpr
	    EUc=EUc+pzMx(jz,jjz)*pqMx(jq,jjq)*Ucpr
		end do
  end do
	Rnet=1+r*(1-tau)
	costder=varphider(d)
	taxes=(1/Rnet-1/(1+r))*bpr
  c=l*w+b-bpr/(1+r)+d-taxes
  Uc=Ucfun(c,l)
	mu=Fl(z,k,l)/w-1.0
  FF(1)=Uc-(1+r)*bbeta*EUc
  FF(2)=Uc*w-Ulfun(c,l)
  FF(3)=q*phi*kpr-bpr/Rnet
	FF(4)=F(z,k,l)-w*l-b+bpr/Rnet-kpr-varphi(d)
	FF(5)=bbeta*EVk-((1-q*phi*mu)/costder)*Uc
  FF(6)=bbeta*EVb+((1-mu)/(costder*Rnet))*Uc

	contains
	include 'Routines.f90'

end subroutine SolveBinding

!*********************************************************************************

subroutine SolveInterior(XX,FF,NN)
include 'Param.f90'
integer :: NN,jjz,jjq,zindex,jz,jq
real (8) :: XX(NN),FF(NN),r,w,d,l,c,kpr,bpr,costder,mu,Uc,Rnet
real (8) :: Vkpr,Vbpr,Ucpr,EVk,EVb,EUc,taxes
real (8) :: dbar,nu,z,q,k,b,pzMx(Nz,Nz),pqMx(Nq,Nq),kVec(nGrid),bkVec(nGrid) 
real (8) :: vkMx(Nz,Nq,nGrid,nGrid),vbMx(Nz,Nq,nGrid,nGrid),ucMx(Nz,Nq,nGrid,nGrid)	
common dbar,nu,z,q,k,b,pzMx,pqMx,kVec,bkVec,vkMx,vbMx,ucMx,jz,jq
  r=XX(1)
  w=XX(2)
  l=XX(3)
  d=XX(4)
  kpr=XX(5)
  bpr=XX(6)
  EVk=0.0
  EVb=0.0
  EUc=0.0
  do jjz=1,Nz
		do jjq=1,Nq
	    Vkpr=AppFun2D(kVec,nGrid,bkVec,nGrid,vkMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
	    Vbpr=AppFun2D(kVec,nGrid,bkVec,nGrid,vbMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
	    Ucpr=AppFun2D(kVec,nGrid,bkVec,nGrid,ucMx(jjz,jjq,1:nGrid,1:nGrid),kpr,bpr)
	    EVk=EVk+pzMx(jz,jjz)*pqMx(jq,jjq)*Vkpr
	    EVb=EVb+pzMx(jz,jjz)*pqMx(jq,jjq)*Vbpr
	    EUc=EUc+pzMx(jz,jjz)*pqMx(jq,jjq)*Ucpr
		end do
  end do
	Rnet=1+r*(1-tau)	
	costder=varphider(d)
	taxes=(1/Rnet-1/(1+r))*bpr
  c=l*w+b-bpr/(1+r)+d-taxes
  Uc=Ucfun(c,l)
	mu=Fl(z,k,l)/w-1.0
  FF(1)=Uc-(1+r)*bbeta*EUc
  FF(2)=Uc*w-Ulfun(c,l)
  FF(3)=mu
	FF(4)=F(z,k,l)-w*l-b+bpr/Rnet-kpr-varphi(d)
	FF(5)=bbeta*EVk-((1-q*phi*mu)/costder)*Uc
  FF(6)=bbeta*EVb+((1-mu)/(costder*Rnet))*Uc
	contains
	include 'Routines.f90'

end subroutine SolveInterior

