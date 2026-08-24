function [xN]=multiyear_a(x,N);

T=length(x);

xN=x(N:end);

for i=1:N-1
    
    xN=xN.*x(N-i:end-i);
end

xN=xN.^(1/N)-1;