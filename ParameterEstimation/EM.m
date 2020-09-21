function [Pr1, Pr2, Pr1T, Pr2T, Theta_f, p, Q, iter_f] = EM(Set, Theta, p, maxIter, printToggle)

% Iteration settings
iter_f = 0;
delta_Theta = 1;
eps = 1e-6;

% Initial assignment
Set_f = Set;
Theta_f = Theta;

model = 1;
% Model 1 Theta: kappa, sigma_1, p_1, mu_2, sigma_2, p_2
% Model 2 Theta: beta, mu_1, sigma_1, p_1, mu_2, sigma_2, p_2

Q = [];

while (delta_Theta > eps)
    iter_f = iter_f + 1;
    
    % Expectation step
    if (model == 1)
        [Pr1, Pr2, Pr1T, Pr2T] = EM_Expectation( ...
            Set_f.Deseasoned.Degrees, ...
            p, ...
            [Theta_f(iter_f, 1), Theta_f(iter_f, 2)], ...
            [Theta_f(iter_f, 4), Theta_f(iter_f, 5)], ...
            model);
    elseif (model == 2)
        [Pr1, Pr2, Pr1T, Pr2T] = EM_Expectation( ...
            Set_f.Deseasoned.Degrees, ...
            p, ...
            [Theta_f(iter_f, 1), Theta_f(iter_f, 2), Theta_f(iter_f, 3)], ...
            [Theta_f(iter_f, 5), Theta_f(iter_f, 6)], ...
            model);
    end
    
    % Maximization step
    if (model == 1)
        [Theta_f(end+1, :), p, Q(end+1, 1)] = EM_Maximization( ...
            Set_f.Deseasoned.Degrees, ...
            Pr1, ...
            Pr2, ...
            Pr1T, ...
            Pr2T, ...
            p, ...
            Theta_f(iter_f, 1:3), ...
            Theta_f(iter_f, 4:6), ...
            model);
    elseif (model == 2)
        %[Theta_f, p, Q] = 
    end
    %Q = [Q; Q_nplus1];
    
    deltaTheta = norm(Theta_f(end,:) - Theta, 2);
    Theta = Theta_f(end,:); % Remember old optima
    
    if printToggle
        fprintf("Iteration: %d, deltaTheta: %d\n\n",...
            iter_f, deltaTheta);
    end
    
    if (iter_f >= maxIter)
        break
    end
end

end