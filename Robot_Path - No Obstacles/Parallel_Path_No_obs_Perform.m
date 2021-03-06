%------------ Optimal Robot Path Planning ----------------------------------------------
% Code:        Coverage Path Planning Algorithm - No Obstacles
% Authors:     Ankit Manerikar, Debasmit Das, Pranay Banerjee
% Date:        04/11/2016
% Course:      AAE568
% Description  The following code consists of a coverage path planning algorithm 
%              implemented using pseudospectral optimal control and through boustro-
%              phedon cellular decomposition for a rectangular field with no obstacles 
%              and assuming a point robot with a fixed coverage radius.
%---------------------------------------------------------------------------------------
clc
close all
clear all

% Generate Independent Variables for tomlab environement--------------------------------
toms t
toms tf
% Select the method for interpolation
p = tomPhase('p', t, 0, tf, 1000, [], 'fem1s'); % Use splines with FEM constraints
%   p = tomPhase('p', t, 0, tf, 100);           % Use linear finite elements
%  p = tomPhase('p', t, 0, 2, 100);             % Use Gauss point collocation
setPhase(p);

% Generate States and Control Variables ------------------------------------------------
tomStates   x1 x2 x3 x4                         % represents 2D physical coordinates as states
tomControls u1 u2                               % Control inputs (accelerations)

%Robot/Area Dimensions-----------------------------------------------------------
w = 0.5;                                        % weighing constant
radr = 0.1;                                     % radius of coverage

%Field Dimensions
Dx = 10;
Dy = 10;

%Obstacle Parameters ------------------------------------------------------ 
% Performance Parameter Initialization ------------------------------------
% area_iter(1) = 0;
time_tot = 0;
energy_tot = 0;
y_area_prev = 0;

x1_var = [];
x2_var = [];
x3_var = [];
x4_var = [];
u1_var = [];
u2_var = [];
pass_time = [];
energy = [];
% Generate Obstacles ------------------------------------------------------
figure(1)

rectangle('Position',[0,0,Dx,Dy],'Curvature', [0 0],'LineWidth',1.5,'Linestyle',':');
box on;
xlim([-1 11]);
ylim([-1 11]);
title('Robot Coverage Path - No Obstacles');
xlabel('X co-ordinate: State Variable, x_1');
ylabel('Y co-ordinate: State Variable, x_2');
hold on;
pause(0.001);

for i = radr:2*radr:Dx-radr

iter = round((i-radr)/(2*radr));

x0 = { tf == 10 
     icollocate({x1 == t; x2 == i; x3 == 1; x4 == 1})
     collocate({u1 == 1; u2==1})};

cbox = { 0  <= collocate(x1) <= 10
         i-2*radr+0.01 <= collocate(x2) <= i+2*radr};

cbnd = {initial({x1 == 0; x2 == i
                 x3 == 1; x4 == 0})
        final({  x1 == 10; x2 == i
                 x3 == 1; x4 == 0})};
%--------------------------------------------------------------------------

% ODEs and path constraints------------------------------------------------

ceq = collocate({                                      % state equations
    dot(x1) == x3
    dot(x2) == x4
    dot(x3) == u1
    dot(x4) == u2});

tot_cost = integrate(w + (1 - w)*(u1^2 + u2^2));                   

% Objective----------------------------------------------------------------
objective = tot_cost;

% Solution of Differential Equation Set------------------------------------
options = struct;
options.name = 'Optimal Robot Path Planning ';
solution = ezsolve(objective, {cbox, cbnd, ceq}, x0 , options);
t_p  = subs(icollocate(t),solution);
x1_p = subs(icollocate(x1),solution);
x2_p = subs(icollocate(x2),solution);
x3_p = subs(icollocate(x3),solution);
x4_p = subs(icollocate(x4),solution);
u1_p = subs(icollocate(u1),solution);
u2_p = subs(icollocate(u2),solution);

x1_var = cat(1,x1_var,x1_p);
x2_var = cat(1,x2_var,x2_p);
x3_var = cat(1,x3_var,x3_p);
x4_var = cat(1,x4_var,x4_p);
u1_var = cat(1,u1_var,u1_p);
u2_var = cat(1,u2_var,u2_p);

area_iter(iter+1) = trapz(x2_p(2:length(x2_p)) +radr) - trapz(x2_p(2:length(x2_p)) -radr);
time_iter(iter+1) = max(t_p);
energy_iter(iter+1) = 0.1*trapz(sqrt(u1_p.^2+u2_p.^2));

plot(x1_p,x2_p,'b')

if i == 10-radr
    break;
elseif ((mod(round((i-radr)/(2*radr)),2)) == 0)  
    plot([10 10]',[i i+2*radr]','r','LineWidth',1.5);
elseif ((mod(round((i-radr)/(2*radr)),2)) == 1)
    plot([0 0]',[i i+2*radr]','r','LineWidth',1.5);
end

hold on;
pause(0.001);

if i == radr
    text(x1_p(1),x2_p(1), ' Initial Point \rightarrow', 'HorizontalAlignment', 'right');
end

end

figure(2)
subplot(3,1,1)
box on;
area_covered = cumsum(area_iter);
plot(0:(iter+1),[0 area_covered])
title('Iteration-wise Area coverage')
xlabel('Iterations')
ylabel('Area')
grid on


subplot(3,1,2)
box on;
pass_time = cumsum(time_iter);
plot(0:(iter+1), [0 pass_time]);
title('Time Taken for Each Iteration')
xlabel('Iterations')
ylabel('Time Taken')
grid on

% xlim([0 iter+2])

subplot(3,1,3)
box on;
energy = cumsum(energy_iter);
plot(0:(iter+1),[0 energy])
title('Control Energy per Iteration')
xlabel('Iterations')
ylabel('Energy')
grid on
% xlim([0 iter+2])

figure(3)
subplot(3,1,1)
box on;
plot(x1_var);
hold on;
plot(x2_var);
title('State Trajectories (Robot position) - x_1, x_2')
xlabel('Time')
ylabel('State Value')
grid on
legend('State Variable - x1','State Variable - x2','Location','SouthEast');

subplot(3,1,2)
box on;
plot(x3_var);
hold on;
plot(x4_var);
title('State Trajectories (Robot Velocities) - x_3, x_4')
xlabel('Time')
ylabel('State Value')
grid on
legend('State Variable - x3','State Variable - x4', ...
       'Location','SouthEast');

subplot(3,1,3)
box on;
plot(u1_var);
hold on;
plot(u2_var);
title('Control Trajectories (Robot Acceleration Inputs) - u_1, u_2')
xlabel('Time')
ylabel('Control Value')
grid on
legend('State Variable - u1','State Variable - u2', ...
       'Location','SouthEast');
