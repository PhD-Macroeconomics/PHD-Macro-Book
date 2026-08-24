function [tr]=hpfilt(y,lam)

%  lam: smoothing parameter. lam=1600 for quarterly data
%  y: the original series 
%  tr: the HP trend
if size(y,1)==1 
    y=y';
end
x=size(y,1);
a=lam;
b=-4*lam;
c=6*lam+1;
d=[a,b,c];
aa=ones(x-2,1)*a;
bb=ones(x-1,1)*b;
cc=ones(x,1)*c;

m=diag(cc)+diag(bb,1)+diag(bb,-1)+diag(aa,2)+diag(aa,-2);

m(1,1)=1+lam;       
m(1,2)=-2*lam;
m(2,1)=-2*lam;      
m(2,2)=5*lam+1;
m(x-1,x-1)=5*lam+1; 
m(x-1,x)=-2*lam;
m(x,x-1)=-2*lam;    
m(x,x)=1+lam;

tr=m\y;

