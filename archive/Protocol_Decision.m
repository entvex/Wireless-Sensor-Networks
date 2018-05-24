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

Samples = linspace(1,length(t)/2,length(t)/2); %Helpers
RoundsC = linspace(1,Rounds,Rounds);           %Helpers

figure(1)
hold on
surf(Samples, RoundsC, directFails(:,1:544))
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
hold off

figure(2)
hold on
surf(Samples(1:544), RoundsC, STATECHANGE(:,1:544))
title({'RECEIVED SIGNAL PER SAMPLE AT TRACK';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
hold off

startNorthStart = 211;
endNorthEnd     = 332;
midWayPoint     = 544;
startSouthStart = 816;
startSouthEnd   = 938;
x1  = distance(:,1:startNorthStart);
x11 = distance(:,endNorthEnd:midWayPoint);
%x111= distance(:,startSouthEnd:length(distance));
x1  = [x1 x11];
x1  = x1(:);

x2  = signalstrengh(:,1:startNorthStart);
x22 = signalstrengh(:,endNorthEnd:midWayPoint);
% x222= signalstrengh(:,startSouthEnd:length(signalstrengh));
x2  = [x2 x22];
x2  = x2(:);

x3  = directFails(:,1:startNorthStart);
x33 = directFails(:,endNorthEnd:midWayPoint);
% x333= directFails(:,startSouthEnd:length(directFails));
x3  = [x3 x33];

y1  = STATECHANGE(:,1:startNorthStart);
y11 = STATECHANGE(:,endNorthEnd:midWayPoint);
% y111= STATECHANGE(:,startSouthEnd:length(STATECHANGE));
y  = [y1 y11];

Samples = linspace(1,length(y),length(y)); %Helpers

figure(3)
hold on
surf(Samples, RoundsC, x3)
title({'Received IN RANGE Signal per package at half a track';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('Signal Strength in dBm')
ylabel('Roundnumber around the track')
hold off

y = y(:);
y = circshift(y',[0,1])';
x3 = x3(:);

X1 = [x1 x2];
b1  = regress(y,X1);

X2 = [x2 x3];
b2  = regress(y,X2);

X3 = [x1 x3];
b3  = regress(y,X2);

X4 = [x1 x2 x3];
b4 = regress(y,X4)

x = linspace(min(x1(:,1)),max(x1(:,1)),length(x1));
y = linspace(min(x2(:,1)),max(x2(:,1)),length(x2));
z = linspace(0,1,length(x3));
d = b4(1)*x + b4(2)*y + b4(3)*z;

figure(4)
hold on
scatter3(x1,x2,x3,'filled')
xlabel('Distance')
ylabel('Signal Strength')
zlabel('Direct Package Bool')
view(50,60)
plot3(x,y,d);grid on;
legend('Simulation points', 'y = 0+0x + 0y + 0.0102z','Location','northwest');
hold off
