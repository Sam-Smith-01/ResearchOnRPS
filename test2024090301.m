% test 20240902 01

% 这篇代码原用于进行文章叙述算法的实际操作。
% 即下层为已经构建的模型，上层为之前写的模型公式，包括配额制的情况。

clc, clear, close all
Number_lhs = 5;
T = 24;
% 向区域外销售电价
lambda_C_p=[0.60*ones(1,7),0.75*ones(1,4),1.20*ones(1,3),0.75*ones(1,4),1.20*ones(1,4),0.40*ones(1,2)]*1e3;
P_C_s = sdpvar(1, T);
lambda_C_s=[0.2*ones(1,7),0.35*ones(1,4),0.5*ones(1,3),0.35*ones(1,4),0.5*ones(1,4),0*ones(1,2)]*1e3;
P_C_p = sdpvar(1, T);

% 先确定供电公司和交易中心以及市场的台区参与者之间的电价情况
rng(0)
lambda_G_p = zeros(Number_lhs, T);
lambda_G_s = zeros(Number_lhs, T);

for t = 1:T
    lhs_temp = lhsdesign(Number_lhs,1);
    lambda_G_s(:,t) = lhs_temp.*(lambda_C_p(t)-lambda_C_s(t))+lambda_C_s(t);
    lambda_G_p(:,t) = rand(size(lhs_temp)).*(lambda_C_p(t)-lambda_G_s(:,t))+lambda_G_s(:,t);
end

gamma_average = 0.9;
gamma = gamma_average*ones(3,2);

P_a_purchase =zeros(Number_lhs, 3*T);
P_a_sell = zeros(Number_lhs, 3*T);

for i = 1:Number_lhs
    output1 =LowerLayerForArea1(lambda_G_s(i,:),  lambda_G_p(i,:), gamma(1,:)');
    output2 = LowerLayerForArea2(lambda_G_s(i,:), lambda_G_p(i,:), gamma(2,:)');
    output3 = LowerLayerForArea3(lambda_G_s(i,:),  lambda_G_p(i,:), gamma(3,:)');
    P_a_purchase(i,:) = [output1(6,:), output2(6,:), output3(6,:)];
    P_a_sell(i,:) = [output1(7,:), output2(7,:), output3(7,:)];
    % P_GC_purchase(i,:) = [output1(8,:), output2(8,:), output3(8,:)];
end

% Output = [P_GT; wind_power_actual;ppv;pload;sum(Pcut); P_purchase ;P_sell ; GreenCertificarte_purchase ];
% hold on
% bar(P_a_purchase(1,:), 'DisplayName','第一组购电')
% bar( P_a_sell(1,:), 'DisplayName','第一组售电')
% bar(P_GC_purchase(1,:), 'DisplayName','第一组绿证购买量')
% legend

% 以上就是得到了初始的kriging模型：供电局购售电价与出清电量以及绿证购买量之间的关系
upper_opt = zeros(Number_lhs, 1);
for i = 1:Number_lhs
    upper_opt(i) = UpperLayerFunc(lambda_C_s, lambda_C_p, lambda_G_s(i,:),lambda_G_p(i,:),P_a_purchase(i,:),P_a_sell(i,:));
end

% disp('upper_opt')
% disp(upper_opt)

% 分组环节
Group_division = Group_divide(lambda_G_s, lambda_G_p, Number_lhs, upper_opt);  % 分组


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   粒子群算法求解
tic
The_Optimal_Profit = PSO_location_optimal(lambda_C_s, lambda_C_p, Group_division, gamma);
elapstime = toc;
disp(['elapstime=', num2str(elapstime)]);

% the overall trade energy is the energy that bought minus the energy that sold

output1 = LowerLayerForArea1(The_Optimal_Profit.opt_variable(1:24), The_Optimal_Profit.opt_variable(25:48), gamma(1,:));
output2 = LowerLayerForArea2(The_Optimal_Profit.opt_variable(1:24), The_Optimal_Profit.opt_variable(25:48), gamma(2,:));
output3 = LowerLayerForArea3(The_Optimal_Profit.opt_variable(1:24), The_Optimal_Profit.opt_variable(25:48), gamma(3,:));
P_a_purchase = [output1(6,:), output2(6,:), output3(6,:)];
P_a_sell = [output1(7,:), output2(7,:), output3(7,:)];
P_GC_purchase = [output1(8,:), output2(8,:), output3(8,:)];
upper_opt = UpperLayerFunc(lambda_C_s, lambda_C_p,The_Optimal_Profit.opt_variable(1:24),The_Optimal_Profit.opt_variable(25:48),P_a_purchase,P_a_sell);
disp(['在配额比例为', num2str(gamma_average),'的时候，对应的最大收入为',num2str(upper_opt),'元'])

figure(1)
hold on
plot(lambda_C_s,'-',  'LineWidth',1.7, 'Color',[254 199 199]/255, 'DisplayName','供电局向区域外销售电价');
plot(lambda_C_p,'--', 'LineWidth',1.7, 'Color',[254 47 47]/255, 'DisplayName','供电局从区域外购买电价');
plot(The_Optimal_Profit.opt_variable(25:48), ':', 'LineWidth',1.7, 'Color',[51 51 248]/255, 'DisplayName','供电局向台区售电电价')
plot(The_Optimal_Profit.opt_variable(1:24), '-.',  'LineWidth',1.7, 'Color',[42 42 252]/255, 'DisplayName','供电局向台区购电电价')
title('系统电价示意图')
legend('Location','northwest')
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}元\fontname{Times New Roman}/MW')
hold off

figure(2)
tiledlayout(1,3);
set(gcf,'unit','normalized','position',[0.2,0.2,0.96,0.32]);
nexttile
hold on
plot(1:T, output1(6,:),'LineWidth',1.7, "Color",[219, 049, 036]/255, 'DisplayName','购电出力');
plot(1:T, output1(1,:),'LineWidth',1.7, 'Color',[252, 140, 090]/255, 'DisplayName','传统发电出力');
plot(1:T, output1(2,:) ,'LineWidth',1.7,'Color',[144, 190, 223]/255, 'DisplayName','绿电（风电）出力');
plot(1:T, output1(3,:),'LineWidth',1.7,'Color',[15, 10, 223]/255, 'DisplayName','绿电（光伏）出力');
title('系统1可动用的全部电力供应')
legend('Location','northwest')
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
hold off
nexttile
hold on
plot(1:T, output2(6,:),'LineWidth',1.7, "Color",[219, 049, 036]/255, 'DisplayName','购电出力');
plot(1:T, output2(1,:),'LineWidth',1.7, 'Color',[252, 140, 090]/255, 'DisplayName','传统发电出力');
plot(1:T, output2(2,:) ,'LineWidth',1.7,'Color',[144, 190, 223]/255, 'DisplayName','绿电（风电）出力');
plot(1:T, output2(3,:),'LineWidth',1.7,'Color',[15, 10, 223]/255, 'DisplayName','绿电（光伏）出力');
title('系统2可动用的全部电力供应')
legend('Location','northwest')
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
hold off
nexttile
hold on
plot(1:T, output3(6,:),'LineWidth',1.7, "Color",[219, 049, 036]/255, 'DisplayName','购电出力');
plot(1:T, output3(1,:), 'LineWidth',1.7,'Color',[252, 140, 090]/255, 'DisplayName','传统发电出力');
plot(1:T, output3(2,:) ,'LineWidth',1.7,'Color',[144, 190, 223]/255, 'DisplayName','绿电（风电）出力');
plot(1:T, output3(3,:),'LineWidth',1.7,'Color',[15, 10, 223]/255, 'DisplayName','绿电（光伏）出力');
title('系统3可动用的全部电力供应')
legend('Location','northwest')
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
hold off

figure(3)
tiledlayout(1,3);
set(gcf,'unit','normalized','position',[0.2,0.2,0.96,0.32]);
nexttile
hold on
plot(1:T, output1(4,:), 'LineWidth',1.7, "Color",[219, 049, 036]/255, 'DisplayName','原始的负荷');
plot(1:T, output1(4,:)-output1(5,:),'LineWidth',1.7, 'Color',[252, 140, 090]/255, 'DisplayName','需求侧响应以后的负荷');
title('系统1中存在的电力负荷')
legend('Location','northwest')
legend boxoff
hold off
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
nexttile
hold on
plot(1:T, output2(4,:),  'LineWidth',1.7,"Color",[219, 049, 036]/255, 'DisplayName','原始的负荷');
plot(1:T, output2(4,:)-output2(5,:),'LineWidth',1.7, 'Color',[252, 140, 090]/255, 'DisplayName','需求侧响应以后的负荷');
title('系统2中存在的电力负荷')
legend('Location','northwest')
legend boxoff
hold off
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
nexttile
hold on
plot(1:T, output3(4,:),'LineWidth',1.7,  "Color",[219, 049, 036]/255, 'DisplayName','原始的负荷');
plot(1:T, output3(4,:)-output3(5,:),'LineWidth',1.7, 'Color',[252, 140, 090]/255, 'DisplayName','需求侧响应以后的负荷');
title('系统3中存在的电力负荷')
legend('Location','northwest')
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
hold off

figure(4)
tiledlayout(1,3);
set(gcf,'unit','normalized','position',[0.2,0.2,0.96,0.32]);
nexttile
bar(output1(8,:),'FaceColor',[89 168 91]/255, 'DisplayName','交易的绿证');
title('系统1中交易的绿证')
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}单位\fontname{宋体}/份数')
nexttile
bar(output2(8,:),'FaceColor',[89 168 91]/255, 'DisplayName','交易的绿证');
title('系统2中交易的绿证')
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}单位\fontname{宋体}/份数')
nexttile
bar(output3(8,:),'FaceColor',[89 168 91]/255, 'DisplayName','交易的绿证');
title('系统3中交易的绿证')
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}单位\fontname{宋体}/份数')

figure(5) % 画出3个台区各自的出可再生能源机组出力情况和负荷情况
tiledlayout(1,3);
set(gcf,'unit','normalized','position',[0.2,0.2,0.96,0.32]);
nexttile            % 可再生能源机组出力情况
hold on
plot(1:T, output1(2,:) ,'-','LineWidth',1.7,'Color', [0, 0, 139]/255, 'DisplayName','台区1绿电（风电）出力');
plot(1:T, output1(3,:),'--','LineWidth',1.7,'Color', [0, 0, 205]/255, 'DisplayName','台区1绿电（光伏）出力');
plot(1:T, output2(2,:) ,'-.','LineWidth',1.7,'Color',[0, 100, 0]/255, 'DisplayName','台区2绿电（风电）出力');
plot(1:T, output2(3,:),'--','LineWidth',1.7,'Color',[34, 139, 34]/255, 'DisplayName','台区2绿电（光伏）出力');
plot(1:T, output3(2,:),'-.' ,'LineWidth',1.7,'Color', [139, 0, 0]/255, 'DisplayName','台区3绿电（风电）出力');
plot(1:T, output3(3,:), '--','LineWidth',1.7,'Color',[205, 92, 92]/255, 'DisplayName','台区3绿电（光伏）出力');
hold off
legend('Location','northwest')
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
title('\fontname{宋体}系统台区可再生能源出力')
nexttile            % 负荷情况
hold on
yyaxis left
plot(1:T, output1(4,:),'-',  'LineWidth',1.7, "Color",[0, 0, 205]/255);
plot(1:T, output2(4,:),'--',   'LineWidth',1.7,"Color",[34, 139, 34]/255);
plot(1:T, output3(4,:),':', 'LineWidth',1.7,  "Color",[205, 92, 92]/255);
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
yyaxis right
figure5_bar_temp = [output1(5,:); output2(5,:); output3(5,:)];
bar(figure5_bar_temp', 'grouped'); 
set(gca, 'YColor', 'k');
b = gca;
b.Children(1).FaceColor = [255, 182, 193]/255; % 第1组颜色浅蓝色
b.Children(2).FaceColor =  [144, 238, 144]/255;   % 第2组颜色（绿色）
b.Children(3).FaceColor = [173, 216, 230]/255; % 第3组颜色浅红色
legend('台区1原始的负荷','台区2原始的负荷', '台区3原始的负荷', '台区1可削减负荷响应量',...
    '台区2可削减负荷响应量', '台区3可削减负荷响应量', 'Location', 'northwest');
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
title('\fontname{宋体}系统台区负荷')
hold off
clear figure5_bar_temp
nexttile   % 购售电情况
hold on
plot(1:T, output1(6,:) ,'-','LineWidth',1.7,'Color', [0, 0, 139]/255, 'DisplayName','台区1购电功率');
plot(1:T, output1(7,:),'--','LineWidth',1.7,'Color', [0, 0, 205]/255, 'DisplayName','台区1售电功率');
plot(1:T, output2(6,:) ,'-','LineWidth',1.7,'Color', [0, 100, 0]/255, 'DisplayName','台区2购电功率');
plot(1:T, output2(7,:),'--','LineWidth',1.7,'Color', [34, 139, 34]/255, 'DisplayName','台区2售电功率');
plot(1:T, output3(6,:) ,'-','LineWidth',1.7,'Color', [139, 0, 0]/255, 'DisplayName','台区3购电功率');
plot(1:T, output3(7,:),'--','LineWidth',1.7,'Color', [205, 92, 92]/255, 'DisplayName','台区3售电功率');
legend('Location', 'northwest');
legend boxoff
xlabel('\fontname{宋体}时间\fontname{Times New Roman}/h')
ylabel('\fontname{宋体}功率\fontname{Times New Roman}/MW')
title('\fontname{宋体}系统台区购售电功率')
hold off
