clc; clear; close all;
load('ToHopOrNotToHop.mat');

% It has to predict if the next package is a fail or a direct hit "STATECHANGE"!
dist_one_round  = sqrt(abs(x_ellipse).^(2) + abs(y_ellipse).^(2));
distance        = repmat(dist_one_round, Rounds, 1);   %Predictor 1
signalstrengh   = P_TrackSignal_All_Rounds_Base';      %Predictor 2
directFails     = ones(size(distance));                %Predictor 3
directFailsCoor = signalstrengh<=acc_dBm;
directFails(directFailsCoor) = 0;
dDirectFails    = diff(directFails,1,2);
zeros_temp      = zeros(Rounds,1);
STATECHANGE     = [zeros_temp, diff(directFails,1,2)]; %Estimator 

Samples = linspace(1,length(t),length(t)); %Helpers
RoundsC = linspace(1,Rounds,Rounds);       %Helpers

figure(1)
hold on
surf(Samples, RoundsC, STATECHANGE)
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'COMBINED-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

x1 = distance(:,1);
x2 = signalstrengh(:,1);
x3 = directFails(:,1);
y  = STATECHANGE(:,1);

X  = [x1 x2 x3];
b  = regress(y,X)
 
scatter3(x1,x2,y,'filled')
xlabel('Signal Strength')
ylabel('Distance')
zlabel('State Change')
view(50,10)
