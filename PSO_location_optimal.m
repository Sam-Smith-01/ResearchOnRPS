function The_Optimal_Profit = PSO_location_optimal(lambda_C_s, lambda_C_p, Group_division, gamma_0)

field_GroupDivision = fieldnames(Group_division);
l = length(field_GroupDivision);

for i1 = 1:l
    fprintf('y%d:\n', i1)
    disp(Group_division.(field_GroupDivision{i1}).value);
end
disp('==================The result of Group division==================')

%    PSO preparation
T = 24;
opt_value_per_field = zeros(l,1);
opt_corresponding_dots = zeros(l, 2*T);
iter_max = 5;
vlimit = [-1, 1];
w = 0.8;
c1 = 0.5;
c2 = 0.5;
for i = 1:l
    if numel(Group_division.(field_GroupDivision{i}).value)==1   % choose the best one for each field type
        opt_value_per_field(i) = Group_division.(field_GroupDivision{i}).value;
        opt_corresponding_dots(i,:) = Group_division.(field_GroupDivision{i}).variable;
    else
        % partical swarm optimization
        part_temp = Group_division.(field_GroupDivision{i}).variable;
        part_best = part_temp; 						% optimal location initialization
        
        v = zeros(size(part_temp));				% initialize velocity
        gamma = gamma_0;

        num_temp = length(Group_division.(field_GroupDivision{i}).value);

        partbest_value = Group_division.(field_GroupDivision{i}).value;

        [groupbest_value, p_best_index] = max(partbest_value);

        group_best = part_best(p_best_index, :);

        iter = 1;

        while iter<iter_max
            P_a_purchase = zeros(num_temp, 3*T);
            P_a_sell = zeros(num_temp, 3*T);
            P_GC_purchase = zeros(num_temp, 3*T);
                                  
            for s = 1:num_temp
                % the former 24 is the sold price to the participants, and the latter 24 is the bought price from the paticipants
                output1 = LowerLayerForArea1(part_temp(s,1:24), part_temp(s,25:48), gamma(1,:));
                output2 = LowerLayerForArea2(part_temp(s,1:24), part_temp(s,25:48), gamma(2,:));
                output3 = LowerLayerForArea3(part_temp(s,1:24), part_temp(s,25:48), gamma(3,:));
                P_a_purchase(s,:) = [output1(6,:), output2(6,:), output3(6,:)];
                P_a_sell(s,:) = [output1(7,:), output2(7,:), output3(7,:)];
                P_GC_purchase(s,:) = [output1(8,:), output2(8,:), output3(8,:)];
                upper_opt = UpperLayerFunc(lambda_C_s, lambda_C_p, part_temp(s,1:24),part_temp(s,25:48),P_a_purchase(s,:),P_a_sell(s,:));

                if partbest_value(s)<upper_opt
                    partbest_value(s) = upper_opt;
                    part_best(s, :) = part_temp(s,:);
                    
                    
                end
            end
            if groupbest_value<max(partbest_value)
                [~, groupmax_index] = max(partbest_value);
                group_best = part_best(groupmax_index,:);
            end
            v = v*w+c1*rand*(part_best-part_temp)+c2*rand*(repmat(group_best,size(part_temp, 1),1)-part_temp);
            v(v>vlimit(2))=vlimit(2);
            v(v<vlimit(1))=vlimit(1);
            part_temp = part_temp +v;
           
            for s = 1:num_temp
                x_margin = find(part_temp(s, 1:24)>lambda_C_s);
                part_temp(s, x_margin) = lambda_C_s(x_margin);
                x_margin = find(part_temp(s,25:48)<lambda_C_p);
                part_temp(s, x_margin) = lambda_C_p(x_margin);
            end
            Optimum_Record(iter) = groupbest_value;
            iter = iter+1;
        end
        opt_value_per_field(i) = Optimum_Record(end);
        opt_corresponding_dots(i,:) =group_best;
    end

end

[The_Optimal_Profit.opt_value, opt_index] = max(opt_value_per_field);
The_Optimal_Profit.opt_variable = opt_corresponding_dots(opt_index, :);


end







