clear all, close all;


%%%%%%%%%%%%%%
	options=optimset;
	options=optimset(options,'MaxFunEvals',1000000,'MaxIter',5000);

% given the empirical consumption growth moments, 
% the function mpmoment calculcates mu,delta,phi
% could be done analytically, MATLAB is the lazy route

   
	 phi = 0.55;

    % transition matrix
	q=[phi         1-phi;... 
           1-phi        phi ];

    % unconditional probabilities
    qbar=[1/2;1/2];
    
    
    mu = 0.0168;
    delta = 0.0233;
   

    gL = 1+mu-delta;
    gH = 1+mu+delta;

    mu_c= qbar(1)*gH +qbar(2)*gL
    mu_c2 = qbar(1)*(gH^2)+qbar(2)*(gL^2);
    mu_ccminus = qbar(1)*q(1,1)*gH*gH+ 2*qbar(1)*q(1,2)*gH*gL +qbar(2)*q(2,2)*gL*gL;

    var_c = mu_c2 - (mu_c^2);
    std_c = sqrt(var_c)
    
    auto_c =(mu_ccminus-(mu_c^2))/var_c
       


    lambda=[gH;gL];  % possible values for lambdas

    

    m = 1;
    % for gamma = 0.01:0.1:100;
        % for beta = 0.01: 0.01: 0.99; %0.7:0.01:0.99
    for gamma = 0.05:0.05:10;
        for beta = 0.9: 0.005: 0.99; %0.7:0.01:0.99

	S=beta*q*(lambda.^(-gamma)); % prices of riskfree asset in state i
	rf=1./S-1;		      % rf is return in state i
	Rf=qbar'*rf;         % Rf is expected return

	%First solve for w's
	A=zeros(2,2);
	for i=1:2
	  for j=1:2
		A(i,j)=beta*q(i,j)*(lambda(j)^(1-gamma));
	  end
	end
	w=inv(eye(2)-A)*(A*ones(2,1));


	% rij return in state j given that today is state i
	r=zeros(2,2);

	for i=1:2 
	  for j=1:2

		r(i,j)=lambda(j)*(1+w(j))/w(i)-1;
	  end
	end


	% Ri expected return given that today is state i
	R=diag(q*r');
	Re=qbar'*R;  % Re expected return on equity

    riskfree(m) = Rf;
    equitypremium(m) = Re - Rf;
    m=m+1;
    
    end
    end

    figure;
    plot(100*riskfree,100*equitypremium,'color',[0.5 0.5 0.5]);
    axis([0 4 0 1])
    ylabel('Equity Premium (in Percent)')
    xlabel('Riskfree Rate (in Percent)')
    print -dpdf mehraprescott;


    % find the upper envelope
    I = logical((riskfree<0.041)   .* (equitypremium <0.01));

M = 100*[riskfree(I)' equitypremium(I)'];

ue = [];
for x=0:0.1:4
    k = logical( (M(:,1)>= x ) .* (M(:,1)<x+0.1));
    if any(k)
        ue=[ ue;[x,max(M(k,2))]];
    end
end

    colNames = {'riskfree','equitypremium'};
T = array2table(ue, 'VariableNames', colNames);
writetable(T, 'Fig_4_data.csv');


