function [loc]=Ex4_location(kval,Kgrid,Ngrids)

          l=1;
                for j=1:Ngrids-1
                    if kval>Kgrid(j) && kval<=Kgrid(j+1)
                        l=j; 
                        break
                    end
                end
          loc=l;