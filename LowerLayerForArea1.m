function Output = LowerLayerForArea1(lambda_G_s, lambda_G_p, gamma)

T = 24;
P_GTmin = 1.3;
P_GTmax = 3.3;
Ramp = 2;
maxium_cut_ratio = [0.15, 0.10, 0.08]';
cut_joint_ratio = 0.2;
NumberofCut = length(maxium_cut_ratio);
cost_for_Pcut = [650, 700, 800]';
working_state_unit_cost  = 800;
generation_marginal_price = 400;
onoff_unitcost = 600;
% 风电出力
wind_power_actual=[1.697876366	2.273363803	1.857549571	1.525714791	1.810828238...
    1.610723546	1.746815293	1.69610502	1.438561844	1.609426497...
    2.352956398	2.168474917	2.09336864	2.105515102	1.461599794...
    1.67475033	1.97349122	1.754573485	2.157909756	1.604184103...
    1.179713855	1.163685285	1.991123884	1.343680112];
wmax = max(wind_power_actual);
wmin = min(wind_power_actual);
wts1 = (wmax-wmin)*rand(size(wind_power_actual))+wmin; % 风电随机性强，完全可以用一个随机函数来近似
wind_power_actual=wts1/1.1; 

% 光伏出力
ppv=[0	0	0	0	0	0	3.845725349	3.376473577	4.174076931...
    3.711447641	5.657996603	6.680004226	5.542670378	5.150861201...
    5.17559222	4.8958352	5.58949	4.537808137	0	0	0	0	0	0];
indexforppv = 1:length(ppv);
ppv= [zeros(1,6), max(ppv)*cos(indexforppv(7:18)/9-14/9)+...
    0.15*max(ppv)*(rand(size(indexforppv(7:18)))-1), zeros(1,6)];   

% 总负荷
pload=[0.5	1.8	2.3	2.8	3.2	2.1	3.3	4.2	5.9	6.8	7.5	7.2	7.1	6.5	5.9	4.8	5.6	6.8	6.8	6.2	3.3	3.6	5.4	2.4];
indexforpload = 1:length(pload);
pload = max(pload)*cos(indexforpload/9-14/9)+...
    0.25*max(pload)*(rand(size(indexforpload))-0.5);


Green_Generation = wind_power_actual+ppv;
GreenCertificarte_unitprice = 120;
P_trade_limit = 20;


Constraints = [];
working_state = binvar(1, T);
on_switch = binvar(1, T);
off_switch = binvar(1, T);
P_GT = sdpvar(1, T);
Pcut = sdpvar(NumberofCut, T);
GreenCertificarte_purchase = sdpvar(1,T); % 购买绿证量  一单位绿证对应一单位出力
Total_Load = pload-sum(Pcut,1);
P_purchase = sdpvar(1, T); % 市场购电量
P_sell = sdpvar(1, T);% 市场售电量
Track_purchase = binvar(1, T);% 市场购电标记
Track_sell = binvar(1, T);% 市场售电标记
P_gain = P_purchase+P_GT+wind_power_actual+ ppv;
P_loss = P_sell+pload-sum(Pcut, 1);

% t=1
Constraints = [Constraints, on_switch(1)==working_state(1)-working_state(T)...
    off_switch(1)==working_state(1)-working_state(T)];
% t=2~T
for t=2:T
    Constraints = [Constraints, working_state(t)-working_state(t-1);
        off_switch(t) == working_state(t-1)-working_state(t)];
end

for t=1:T
    Constraints = [Constraints, P_GTmin<=P_GT(t), P_GT(t)<=P_GTmax];
end

% t=1
Constraints = [Constraints, P_GT(1)<=Ramp];
% t=2~T
for t = 2:T
    Constraints = [Constraints, -Ramp<=P_GT(t)-P_GT(t-1), P_GT(t)-P_GT(t-1)<=Ramp];
end

% 可削减负荷
for i=1:NumberofCut
    Constraints = [Constraints, 0<=Pcut(i,1), Pcut(i,1)<=maxium_cut_ratio(i).*pload(1)];
end

for i = 1:NumberofCut
    for t = 2:T
        Constraints =[Constraints, 0<=Pcut(i,t), Pcut(i,t)<=maxium_cut_ratio(i).*pload(t), ...
            Pcut(i, t) - Pcut(i, t-1)<=cut_joint_ratio*pload(t)];
    end
end
% 市场购电价格

for t = 1:T
    Constraints = [Constraints, ...
        Track_purchase(t)+Track_sell(t)<=1, ...
        P_purchase(t)>=0, ...
        P_purchase(t) <= P_trade_limit*Track_purchase(t), ...
        P_sell(t)>=0, ...
        P_sell(t)<=P_trade_limit*Track_sell(t),...
        P_gain(t)==P_loss(t)];
end

% gamma = [0.6, 0.2]'; % 配额比例约束
for t = 1:T
    Constraints = [Constraints,...
        GreenCertificarte_purchase(t)+Green_Generation(t)>=gamma.*Total_Load(t)];
end

% 燃气轮机的运行成本
working_state_cost = sum(working_state.*working_state_unit_cost);% 工作状态固定成本
ge_marginal_cost = sum(generation_marginal_price*P_GT);% 发电时刻边际成本
onoff_cost = sum(onoff_unitcost*(on_switch+off_switch));% 启停成本
GT_cost = working_state_cost+ge_marginal_cost+onoff_cost;
cost_Load_cut = sum(sum(repmat(cost_for_Pcut,1 ,size(Pcut,2)).*Pcut, 1));
cost_market = sum(lambda_G_s.*P_purchase-lambda_G_p.*P_sell);
cost_GreenCertificate = GreenCertificarte_unitprice*sum(GreenCertificarte_purchase);

Cost_total = GT_cost+cost_Load_cut+cost_GreenCertificate+cost_market;

ops = sdpsettings('solver', 'gurobi', 'verbose', 0, 'usex0', 0);
ops.cplex.mip.tolerances.mipgap = 1e-6;
result = optimize(Constraints, Cost_total, ops);

% if result.problem==0
%     disp('Problem1 lower level solve success')
% else
%     disp('Problem1 error')
% end

P_GT = value(P_GT);
Pcut = value(Pcut);
P_purchase  =value(P_purchase);
P_sell = value(P_sell);
GreenCertificarte_purchase = value(GreenCertificarte_purchase);

Output = [P_GT; wind_power_actual;ppv;pload;sum(Pcut); P_purchase ;P_sell ; GreenCertificarte_purchase ];
end