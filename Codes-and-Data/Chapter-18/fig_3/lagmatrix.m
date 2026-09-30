function Y = lagmatrix(y,p)

Y = NaN(size(y));
if p >=0
    Y(1+p:end,:) = y(1:end-p);
else
    Y(1:end+p,:) = y(1-p:end);
end
