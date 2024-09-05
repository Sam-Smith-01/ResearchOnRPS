function Profit= UpperLayerFunc(lambda_C_s, lambda_C_p, lambda_G_s,lambda_G_p,P_a_purchase,P_a_sell)
T=24;
% The first is the first area output, the second is the second one, the third is the third one
P_a_purchase = [P_a_purchase(  1:24);P_a_purchase(  25:48); P_a_purchase(  49:72)];
P_a_purchase_sum = sum(P_a_purchase, 1);  % the electricity that bought from utility
P_a_sell = [P_a_sell(  1:24);P_a_sell(  25:48);P_a_sell(49:72)];
P_a_sell_sum = sum(P_a_sell, 1);		

% the overall trade energy is the energy that bought minus the energy that sold

P_c=sum(-P_a_sell_sum+P_a_purchase_sum, 1);
P_c_purchase_i = zeros(size(P_c));		% if the one area able to purchase
P_c_sell_i = zeros(size(P_c));			% the one area able to sell

for t = 1:T					% to see the total power and know if the buy from other areas
	if P_c(t)>=0
		P_c_purchase_i(t)=P_c(t);
		P_c_sell_i(t) = 0;
	else
		P_c_purchase_i(t)=0;
		P_c_sell_i(t) = -P_c(t);
	end
end
% disp('++++++++++++++++++++++++++++++++')
% fprintf('lambda_C_s %d %d\n', size(lambda_C_s));
% fprintf('P_c_sell_i %d %d\n', size(P_c_sell_i));
% fprintf('lambda_C_p %d %d\n', size(lambda_C_p));
% fprintf('P_c_purchase_i %d %d\n', size(P_c_purchase_i));
% fprintf('lambda_G_s %d %d\n', size(lambda_G_s));
% fprintf('P_a_purchase_sum %d %d\n', size(P_a_purchase_sum));
% fprintf('lambda_G_p %d %d\n', size(lambda_G_p));
% fprintf('P_a_sell_sum %d %d\n', size(P_a_sell_sum));


Profit = sum(lambda_C_s.*P_c_sell_i - lambda_C_p.*P_c_purchase_i)+sum( lambda_G_s .*P_a_purchase_sum-  lambda_G_p .*P_a_sell_sum);



end

% 领导者以下有若干个虚拟电厂，这些虚拟电厂从领导者配电市场运营商处买电。为配电市场运营商贡献收入。
%  此后，领导者还可以从外层处买电，卖电，进而为配电市场运营商贡献收入。