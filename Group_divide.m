function Group_division = Group_divide(lambda_G_s, lambda_G_p, Number_lhs, upper_opt)

l = 1; 
T = 24;
upper_temp = upper_opt;										% S: upper_temp, upper_opt:C_DSO
lambda_G = zeros(Number_lhs, 2*T);
for i = 1:Number_lhs
	lambda_G(i, :) = [lambda_G_s(i,:), lambda_G_p(i,:)];
end

dot_temp = lambda_G;										% SL:dot_temp,  lambda_G:lambda_DA
k_max = 5;  % The maximum iterate times for the equilbrium algorium

[~, index] = max(upper_temp); % the first one to know
dot_opt = lambda_G(index, :);		% the centre dot of the clustering			% dot_opt:lambda_DA0

while 1
	if isempty(upper_temp)
		break;
	end
	% initialize the structure code
	eval(['y', num2str(l), '.value=[];']); 
	eval(['y', num2str(l), '.variable=[];']);	
	
	k = 1;
	while k<=k_max					% inner iteration
		if isempty(upper_temp)
			break;
		end
		
		lambda_G_max = max(sqrt(sum(dot_temp.^2,2)));
		lambda_G_min = min(sqrt(sum(dot_temp.^2,2)));		% the radius is calculated with the code.
		
		radius = norm(lambda_G_max-lambda_G_min)/3;
		
        % fprintf('repmat(dot_opt,Number_lhs,1) %d %d\n', size(repmat(dot_opt,Number_lhs,1)));
        % fprintf('dot_temp %d %d\n', size(dot_temp));
  

		distance =sqrt(sum(repmat(dot_opt,size(dot_temp,1),1)-dot_temp,2).^2);
		output_index = find(distance<=radius);			% to find the dots that has a radius smaller than 'radius'
		if isempty(output_index)
			break;
		end

		eval(['y', num2str(l), '.value = [y', num2str(l), '.value;  upper_temp(', 'output_index)];']);
		eval(['y', num2str(l), '.variable = [y', num2str(l), '.variable;   dot_temp(', 'output_index,:)];']);
		
		upper_temp(output_index)=[];
		dot_temp(output_index,:) =[];
		
		k = k+1;
	end 
	[~, output_index] =max(upper_temp);
	dot_opt = dot_temp(output_index, :);
	l = l+1;	
end
disp('----The result of domian division-------');
for i =1:l
	if ~exist(['y', num2str(i)], 'var')
		break
	end
	eval(['Group_division.y', num2str(i), '=y', num2str(i),';']);
end
end


