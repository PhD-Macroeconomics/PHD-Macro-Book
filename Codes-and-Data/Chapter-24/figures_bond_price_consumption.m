%clear all
%Plot Figures 24.6 and 24.7
%Need to run the Fortran code code_sovereign_default.f90 before running
%this file. 
load b_grid.txt
load y_grid.txt
load v.txt
load q.txt
load default.txt
load b_next.txt
load dev.txt
load q_paid.txt
load delta.txt

b_num = length(b_grid);
y_num = length(y_grid);
lambda_num = 2;%length(lam_grid);

r = 0.01;

v0_matrix = zeros(b_num, y_num);
v1_matrix = zeros(b_num, y_num);
v_matrix = zeros(b_num, y_num);
default_matrix = zeros(b_num, y_num);
q_matrix = zeros(b_num, y_num);
b_next_matrix = zeros(b_num, y_num);
dev_matrix = zeros(b_num, y_num);
q_paid_matrix = zeros(b_num, y_num);
q_paid_matrix_nodef = zeros(b_num, y_num);
q_paid_matrix_nodef_rn = zeros(b_num, y_num);
c_matrix = zeros(b_num, y_num);
coupon = (r+delta)/(1d+0 + r);
   for i_b = 1:b_num
        for i_y = 1:y_num
                 v0_matrix(i_b, i_y) = v((i_b-1)*y_num + i_y,2);
                 v1_matrix(i_b, i_y) = v((i_b-1)*y_num + i_y,3);
                  v_matrix(i_b, i_y) = v((i_b-1)*y_num + i_y,1);
            default_matrix(i_b, i_y) = default((i_b-1)*y_num + i_y);
                  q_matrix(i_b, i_y) = q((i_b-1)*y_num + i_y);
             q_paid_matrix(i_b, i_y) = q_paid((i_b-1)*y_num + i_y,1);
       q_paid_matrix_nodef(i_b, i_y) = q_paid((i_b-1)*y_num + i_y,2);
       q_paid_matrix_rn(i_b, i_y) = q_paid((i_b-1)*y_num + i_y,3);
             b_next_matrix(i_b, i_y) = b_next((i_b-1)*y_num + i_y);
                dev_matrix(i_b, i_y) = dev((i_b-1)*y_num + i_y);
                 c_matrix(i_b, i_y) = (1-default_matrix(i_b, i_y))*(exp(y_grid(i_y)) + coupon*b_grid(i_b) - (b_next_matrix(i_b, i_y)-(1-delta)*b_grid(i_b))*q_paid_matrix(i_b, i_y));
                
            end
        end




% 
matriz_def = zeros(b_num, y_num);
index_vector = zeros(b_num,1);

     for i=1:b_num
        index_vector(i) = max(sum(default_matrix(i,:)),1);
        for j=1:y_num
          matriz_def(i,j) = default_matrix(i,j);
        end
     end
     

    figure
    i_lo = 11;
    i_hi = 15;
    i_b = 15;
    H = plot(-25*b_grid, [q_matrix(:,i_lo) q_matrix(:,i_hi)]);
    set(gca,'FontSize',18,'FontName', 'Times New Roman')
    set(H(1), 'LineStyle','--','LineWidth',2,'MarkerSize',.1,'Color','k')
    set(H(2), 'LineStyle','-','LineWidth',2,'MarkerSize',.1,'Color','k')
    axis([20 80 0 1])
    xlabel('Debt / mean income','FontName', 'Times New Roman','FontSize',18)
    ylabel('Bond price','FontName', 'Times New Roman','FontSize',18)
    hold on
    H1 = plot(-25*b_next_matrix(i_b, i_lo), q_paid_matrix(i_b, i_lo));
    set(H1(1), 'LineStyle','none','Marker','.','LineWidth',2,'MarkerSize',25,'Color','b')
    H1 = plot(-25*b_next_matrix(i_b, i_hi), q_paid_matrix(i_b, i_hi));
    set(H1(1), 'LineStyle','none','Marker','.','LineWidth',2,'MarkerSize',25,'Color','b')
    text(45, 0.2,'$q(B'',Y_{lo})$','Interpreter','Latex','FontSize',18)
    text(57, 0.93,'$q(B'', Y_{hi})$','Interpreter','Latex','FontSize',18)
    hold off
    print q_book.eps -depsc2


    figure
    ind = find(c_matrix(i_b, :)>0);
    H = plot(y_grid, [y_grid log(c_matrix(i_b, :))'-mean(log(c_matrix(i_b, ind)))]);
    set(H(1), 'LineStyle','--','LineWidth',2,'MarkerSize',.1,'Color',[0.6 0.6 0.6])
    set(H(2), 'LineStyle','-','LineWidth',2,'MarkerSize',.1,'Color','b')
    set(gca,'FontSize',18,'FontName', 'Times New Roman')
    axis([-0.15 0.15 -0.15 0.15])
    xlabel('log(y) - E(log(y))','FontName', 'Times New Roman','FontSize',18)
    ylabel('log(c) - E(log(c))','FontName', 'Times New Roman','FontSize',18)
    text(0.05, 0.12,'45o line','FontSize',18,'FontName', 'Times New Roman')
    print c_book.eps -depsc2

    figure
    H = plot(-25*b_grid, exp(y_grid(index_vector))); 
    set(gca,'FontSize',18,'FontName', 'Times New Roman')
    axis([0 100 0.9 1.1])
    set(H(1), 'LineStyle','-','LineWidth',3,'MarkerSize',.1,'Color',[0.7 0.7 0.7]')
    xlabel('Debt / mean income','FontName', 'Times New Roman','FontSize',18)
    ylabel('Income','FontName', 'Times New Roman','FontSize',18)
    hold on
    grid on
     h=area([-25*b_grid -25*b_grid], [zeros(b_num,1) exp(y_grid(index_vector))]);
     set(h(2),'FaceColor',[0.6 0.6 0.6],'EdgeColor','none')
hold off
text(70, 0.96, 'Default', 'FontSize',24,'FontName', 'Times New Roman')
text(20, 1.05, 'Repay', 'FontSize',24,'FontName', 'Times New Roman')
print default_region_book.eps -depsc2



