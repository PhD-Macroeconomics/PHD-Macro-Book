function Prod(zz,kk,ll) result (rf) 
real (8) :: zz,kk,ll,rf
	rf=zz*(abs(kk)**theta*abs(ll)**(1-theta))
end function Prod

function Prodk(zz,kk,ll) result (rf) 
real (8) :: zz,kk,ll,rf
	rf=theta*Prod(zz,kk,ll)/kk
end function Prodk

function Prodl(zz,kk,ll) result (rf) 
real (8) :: zz,kk,ll,rf
	rf=(1-theta)*Prod(zz,kk,ll)/ll
end function Prodl

function F(zz,kk,ll) result (rf) 
real (8) :: zz,kk,ll,rf
	rf=(1-delta)*kk+Prod(zz,kk,ll)
end function F

function Fk(zz,kk,ll) result (rf) 
real (8) :: zz,kk,ll,rf
	rf=1-delta+Prodk(zz,kk,ll) 
end function Fk

function Fl(zz,kk,ll) result (rf) 
real (8) :: zz,kk,ll,rf
	rf=Prodl(zz,kk,ll) 
end function Fl

!===========================================================================!

function varphi(dd) result (rf) 
real (8) :: dd,rf
    rf=dd+kappa*(dd-dbar)**2.0
end function varphi

function varphider(dd) result (rf) 
real (8) :: dd,rf
    rf=1.0+2.0*kappa*(dd-dbar)
end function varphider
  
!===========================================================================!

function Ucfun(cc,ll) result (rf) 
real (8) :: cc,ll,rf
	rf=nu*(abs(cc)**nu*abs(1-ll)**(1-nu))**(1-sigma)/cc
end function Ucfun

function Ulfun(cc,ll) result (rf) 
real (8) :: cc,ll,rf
	rf=(1-nu)*(abs(cc)**nu*abs(1-ll)**(1-nu))**(1-sigma)/(1-ll)
end function Ulfun

!*********************************************************************************

function AppFun2D(xVec,nxR,yVec,nyR,zMx,x,y) result(retval)
integer :: nxR,nyR,nx,ny
real (8) :: xVec(nxR),yVec(nyR),zMx(nxR,nyR),x,y
real (8) :: xstep,ystep,px,py,slope,dz1,dz2,dzx,dzy,z1,z2,zx,zy,z,retval

!------FIND LOCATION OF POINT x------!

  xstep=(xVec(nxR)-xVec(1))/(nxR-1)
  if (x<=xVec(1)) then
    nx=1
    px=1.0
  elseif (x>=xVec(nxR)) then
    nx=nxR-1
    px=0.0
  else
    nx=1+floor((x-xVec(1))/xstep)
    px=1-(x-xVec(nx))/xstep
  endif

!------FIND LOCATION OF POINT y------!

  ystep=(yVec(nyR)-yVec(1))/(nyR-1)
  if (y<=yVec(1)) then 
    ny=1
    py=1.0
  elseif (y>=yVec(nyR)) then
    ny=nyR-1
    py=0.0
  else
    ny=1+floor((y-yVec(1))/ystep)
    py=1-(y-yVec(ny))/ystep
  endif

!------CHECK for LOCATION OUTSIDE x GRID------!

  if (x<=xVec(1)) then
    slope=(zMx(2,ny)-zMx(1,ny))/xstep
    dz1=(x-xVec(1))*slope
    slope=(zMx(2,ny+1)-zMx(1,ny+1))/xstep
    dz2=(x-xVec(1))*slope
    dzx=dz1*py+dz2*(1-py)
  elseif (x>=xVec(nxR)) then
    slope=(zMx(nxR,ny)-zMx(nxR-1,ny))/xstep
    dz1=(x-xVec(nxR))*slope
    slope=(zMx(nxR,ny+1)-zMx(nxR-1,ny+1))/xstep
    dz2=(x-xVec(nxR))*slope
    dzx=dz1*py+dz2*(1-py)
  else
    dzx=0.0
  endif

!------CHECK for LOCATION OUTSIDE y GRID------!

  if (y<=yVec(1)) then
    slope=(zMx(nx,2)-zMx(nx,1))/ystep
    dz1=(y-yVec(1))*slope
    slope=(zMx(nx+1,2)-zMx(nx+1,1))/ystep
    dz2=(y-yVec(1))*slope
    dzy=dz1*px+dz2*(1-px)
  elseif (y>=yVec(nyR)) then
    slope=(zMx(nx,nyR)-zMx(nx,nyR-1))/ystep
    dz1=(y-yVec(nyR))*slope
    slope=(zMx(nx+1,nyR)-zMx(nx+1,nyR-1))/ystep
    dz2=(y-yVec(nyR))*slope
    dzy=dz1*px+dz2*(1-px)
  else
    dzy=0.0
  endif

!------COMPUTE INTERNAL z------!

  z1=zMx(nx,ny)*px+zMx(nx+1,ny)*(1-px)
  z2=zMx(nx,ny+1)*px+zMx(nx+1,ny+1)*(1-px)
  zx=z1*py+z2*(1-py)

  z1=zMx(nx,ny)*py+zMx(nx,ny+1)*(1-py)
  z2=zMx(nx+1,ny)*py+zMx(nx+1,ny+1)*(1-py)
  zy=z1*px+z2*(1-px)

  z=(zx+zy)/2

!------ADD OUTSIDE GRID CORRECTIONS------!

  retval=z+dzx+dzy

end function AppFun2D


!*********************************************************************************

