clc; clear; close all;

%-94dBm is antenna receiver sensitivity
%-84dBm is chosen to give room for unexpected noise sources!
acc_dBm = -84;            %Accepted received power

R = 1;                    %Measurement Shunt-Resistance

I_tx_max = 1*10.^(-3);    %Transmit current
I_tx_min = 4*10.^(-6);    %I_tx_max - 24dBm

Ptx_max = I_tx_max*R^(2); %Transmit Power
Ptx_min = I_tx_min*R^(2); %Transmit Power

% Antennasize = 2.7cm and freq = 2.4GHz
% https://www.everythingrf.com/rf-calculators/antenna-near-field-distance-calculator  
d0     = 0.01167;    %(meter) estimation of the Far Field distance for the TelosB antenna

% f      = 2.4*10^(9); %2.4GHz
% c      = 3*10^(8);   %Speed of light
% lambda = c/f;        %Wavelength of 2.4GHz
% area   = (4*pi)^(2); %Isotropic lossless antenna
% L      = 1;          %Lossless electronics assumption
% Gt     = 1;          %Gt and Gr are based on the antenna structure and
                       %how directional the antenna is. Throughout
                       %the rest of the calculations the antenna will be
                       %treaded as a omnidirectional antenna!
%                      %Calculated based on the 100m free space range from the Telos_B datasheet!
% Gr     = Gt;         %Same antenna
% Prcvd_max = (Ptx_Antenna*Gt*Gr*lambda^(2))/(area*d0^(2)*L); %Recieved signal power at   0dBm Ptx
% Prcvd_min = (Ptx_Antenna_min*Gt*Gr*lambda^(2))/(area*d0^(2)*L); %Recieved signal power at -24dBm Ptx

N = 100; %meter from the base station "half of a racetrack width"
Meter = 100;
x = linspace(-Meter, Meter, N*2+1);  
y = linspace(-Meter, Meter, N*2+1);  
[X,Y] = meshgrid(x,y);

N_min = 25; %meter from the base station "half of a racetrack width"
Meter = 0.25;
x_min = linspace(-Meter, Meter, N_min*2+1);  
y_min = linspace(-Meter, Meter, N_min*2+1);  
[X_min,Y_min] = meshgrid(x_min,y_min);

%% 0dBm = max power, -24dBm = min power
% Office = 5.5 (2% of the distance) for every 5m one wall of thickness 30cm exist! 
gammaOffice     = (2*94+5.5*6)/100; %2.21
gammaOffice_min = 5.5;

%BaseStation
d = sqrt(X.^(2)+Y.^(2));    %euclidean distance
d((N*2)/2+1,(N*2)/2+1) = 0.5; %to avoid inf number in the center!
d_min = sqrt(X_min.^(2)+Y_min.^(2));    %euclidean distance
d_min((N_min*2)/2+1,(N_min*2)/2+1) = 0.01; %to avoid inf number in the center!

POffice_W     = Ptx_max.*((d0./d).^gammaOffice); %Watt
POffice       = 10*log10(POffice_W/0.001);       %dBm
POffice_W_min = Ptx_min.*((d0./d_min).^gammaOffice_min); %Watt
POffice_min   = 10*log10(POffice_W_min/0.001);   %dBm

%NorthStation
%NorthStation placed half a track height away from basestation  
dNorthOffice = sqrt((X-20).^(2)+Y.^(2)); 
dNorthOffice((N*2)/2+1,(N*2)/2+21) = 0.5;   
dNorthOfficemin = sqrt((X_min-0.1).^(2)+Y_min.^(2));
dNorthOfficemin((N_min*2)/2+1,(N_min*2)/2+11) = 0.01;

POfficeNorth_W  = Ptx_max.*((d0./dNorthOffice).^gammaOffice);           %Watt
POfficeNorth_W_min  = Ptx_min.*((d0./dNorthOfficemin).^gammaOffice_min);    %Watt

%SouthStation
%SouthStation placed half a track height away from basestation
dSouthOffice = sqrt((X+20).^(2)+Y.^(2)); 
dSouthOffice((N*2)/2+1,(N*2)/2-19) = 0.5;    
dSouthminOffice = sqrt((X_min+0.1).^(2)+Y_min.^(2));
dSouthminOffice((N_min*2)/2+1,(N_min*2)/2-9) = 0.01;

POfficeSouth_W     = Ptx_max.*((d0./dSouthOffice).^gammaOffice);           %Watt
POfficeSouth_W_min = Ptx_min.*((d0./dSouthminOffice).^gammaOffice_min);        %Watt
 
%Combination of stations in dBm
POfficeCombined      = 10*log10((POffice_W + POfficeNorth_W + POfficeSouth_W)./0.001);                 
POfficeCombined_min  = 10*log10((POffice_W_min + POfficeNorth_W_min + POfficeSouth_W_min)./0.001); 

%% Plotting Signal Range in Shannon Engineering Building for 0dBm
figure(6)
hold on
pcolor(x,y,POffice)
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, OFFICE, Trx = 0dBm'})
xlabel('-100m < BaseStation < 100m')
ylabel('-100m < BaseStation < 100m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a =100; % horizontal radius
b = 20; % vertical radius
x0=  0; % x0,y0 ellipse centre coordinates
y0=  0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=40m, L=100m"');
hold off

figure(7)
hold on
pcolor(x,y,POfficeCombined)
title({'LOGPATH RECEIVED SIGNAL PLOT';'COMBINED-Stations, OFFICE, Trx = 0dBm'})
xlabel('-100m < BaseStation < 100m')
ylabel('-100m < BaseStation < 100m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=40m, L=100m"');
hold off

%% Plotting Signal Range in Shannon Engineering Building for -24dBm
scale = N_min;
figure(8)
hold on
pcolor(x_min(N_min+1-scale:N_min+1+scale),y_min(N_min+1-scale:N_min+1+scale),POffice_min(N_min+1-scale:N_min+1+scale,N_min+1-scale:N_min+1+scale))
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, OFFICE, Trx = -24dBm'})
xlabel('-0.25m < BaseStation < 0.25m')
ylabel('-0.25m < BaseStation < 0.25m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a =0.2; % horizontal radius
b = 0.05; % vertical radius
x0=0; % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=5cm, L=20cm"');
hold off

figure(9)
hold on
pcolor(x_min(N_min+1-scale:N_min+1+scale),y_min(N_min+1-scale:N_min+1+scale),POfficeCombined_min(N_min+1-scale:N_min+1+scale,N_min+1-scale:N_min+1+scale))
title({'LOGPATH RECEIVED SIGNAL PLOT';'COMBINED-Stations, OFFICE, Trx = -24dBm'})
xlabel('-0.25m < BaseStation < 0.25m')
ylabel('-0.25m < BaseStation < 0.25m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=5cm, L=50cm"');
hold off


