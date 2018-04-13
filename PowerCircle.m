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

N = 200; %meter from the base station "half of a racetrack width"
x = linspace(-N,N,N*2+1);  
y = linspace(-N,N,N*2+1);  
[X,Y] = meshgrid(x,y);
%% 0dBm = max power, -24dBm = min power
%  AIR = 2
gammaAIR = 2;
% Office = 5.5 (2% of the distance) for every 5m one wall of thickness 30cm exist! 
gammaOffice = (2*94+5.5*6)/100; %2.21


%BaseStation
d = sqrt(X.^(2)+Y.^(2));    %euclidean distance
d((N*2)/2+1,(N*2)/2+1) = 1; %to avoid inf number in the center!

PAir_W     = Ptx_max.*((d0./d).^gammaAIR); %Watt
PAir       = 10*log10(PAir_W/0.001);       %dBm
PAir_W_min = Ptx_min.*((d0./d).^gammaAIR); %Watt
PAir_min   = 10*log10(PAir_W_min/0.001);   %dBm

POffice_W     = Ptx_max.*((d0./d).^gammaOffice); %Watt
POffice       = 10*log10(POffice_W/0.001);       %dBm
POffice_W_min = Ptx_min.*((d0./d).^gammaOffice); %Watt
POffice_min   = 10*log10(POffice_W_min/0.001);   %dBm

%NorthStation
%NorthStation placed half a track height away from basestation
dNorth = sqrt((X-40).^(2)+Y.^(2));      %euclidean distance     
dNorth((N*2)/2+1,(N*2)/2+41) = 1;       %to avoid inf number in the center!       
dNorthOffice = sqrt((X-20).^(2)+Y.^(2)); 
dNorthOffice((N*2)/2+1,(N*2)/2+21) = 1; 
dNorthmin = sqrt((X-5).^(2)+Y.^(2));     
dNorthmin((N*2)/2+1,(N*2)/2+6) = 1;              
dNorthOfficemin = sqrt((X-3).^(2)+Y.^(2));
dNorthOfficemin((N*2)/2+1,(N*2)/2+4) = 1;

PAirNorth       = 10*log10((Ptx_max.*((d0./dNorth).^gammaAIR)./0.001)); %dBm
PAirNorth_W     = Ptx_max.*((d0./dNorth).^gammaAIR);                    %Watt
PAirNorth_W_min = Ptx_min.*((d0./dNorthmin).^gammaAIR);                 %Watt
POfficeNorth_W  = Ptx_max.*((d0./dNorthOffice).^gammaOffice);           %Watt
POfficeNorth_W_min  = Ptx_min.*((d0./dNorthOfficemin).^gammaOffice);    %Watt

%SouthStation
%SouthStation placed half a track height away from basestation
dSouth = sqrt((X+40).^(2)+Y.^(2));        %euclidean distance
dSouth((N*2)/2+1,(N*2)/2-39) = 1;         %to avoid inf number in the center!
dSouthOffice = sqrt((X+20).^(2)+Y.^(2)); 
dSouthOffice((N*2)/2+1,(N*2)/2-19) = 1;  
dSouthmin = sqrt((X+5).^(2)+Y.^(2));     
dSouthmin((N*2)/2+1,(N*2)/2-4) = 1;      
dSouthminOffice = sqrt((X+3).^(2)+Y.^(2));
dSouthminOffice((N*2)/2+1,(N*2)/2-2) = 1;

PAirSouth          = 10*log10((Ptx_max.*((d0./dSouth).^gammaAIR)./0.001)); %dBm
PAirSouth_W        = Ptx_max.*((d0./dSouth).^gammaAIR);                    %Watt
PAirSouth_W_min    = Ptx_min.*((d0./dSouthmin).^gammaAIR);                 %Watt
POfficeSouth_W     = Ptx_max.*((d0./dSouthOffice).^gammaOffice);           %Watt
POfficeSouth_W_min = Ptx_min.*((d0./dSouthminOffice).^gammaOffice);        %Watt
 
%Combination of stations in dBm
PAIRCombined         = 10*log10((PAir_W + PAirNorth_W + PAirSouth_W)./0.001);                          
PAIRCombined_min     = 10*log10((PAir_W_min + PAirNorth_W_min + PAirSouth_W_min)./0.001);              
POfficeCombined      = 10*log10((POffice_W + POfficeNorth_W + POfficeSouth_W)./0.001);                 
POfficeCombined_min  = 10*log10((POffice_W_min + POfficeNorth_W_min + POfficeSouth_W_min)./0.001); 

%% Plotting Signal Range in AIR for 0dBm
figure(1)
hold on
pcolor(x,y,PAir)
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [acc_dBm 0]); 
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a=198; % horizontal radius
b=40;  % vertical radius
x0=0;  % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

figure(2)
subplot(3,1,1)
hold on
pcolor(x,y,PAirSouth)
title({'LOGPATH RECEIVED SIGNAL PLOT';'SOUTH-Station, AIR, Trx = 0dBm'})
xlabel('-200m < BaseStation < 200m') % x-axis label
ylabel('-200m < BaseStation < 200m') % y-axis label
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
plot(x_ellipse,y_ellipse,'r')
hold off

subplot(3,1,2)
hold on
pcolor(x,y,PAir)
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, AIR, Trx = 0dBm'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
plot(x_ellipse,y_ellipse,'r')
hold off

subplot(3,1,3)
hold on
pcolor(x,y,PAirNorth)
title({'LOGPATH RECEIVED SIGNAL PLOT';'NORTH-Station, AIR, Trx = 0dBm'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
plot(x_ellipse,y_ellipse,'r')
hold off

figure(3)
hold on
pcolor(x,y,PAIRCombined)
title({'LOGPATH RECEIVED SIGNAL PLOT';'COMBINED-Stations, AIR, Trx = 0dBm'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off


%% Plotting Signal Range in AIR for -24dBm
scale = 25;
figure(4)
hold on
pcolor(x(N+1-scale:N+1+scale),y(N+1-scale:N+1+scale),PAir_min(N+1-scale:N+1+scale,N+1-scale:N+1+scale))
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, AIR, Trx = -24dBm'})
xlabel('-25m < BaseStation < 25m')
ylabel('-25m < BaseStation < 25m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a=15; % horizontal radius
b=3;  % vertical radius 
x0=0; % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=6m, L=30m"');
hold off

figure(5)
hold on
pcolor(x(N+1-scale:N+1+scale),y(N+1-scale:N+1+scale),PAIRCombined_min(N+1-scale:N+1+scale,N+1-scale:N+1+scale))
title({'LOGPATH RECEIVED SIGNAL PLOT';'COMBINED-Stations, AIR, Trx = -24dBm'})
xlabel('-25m < BaseStation < 25m')
ylabel('-25m < BaseStation < 25m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=6m, L=30m"');
hold off

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
scale = 15;
figure(8)
hold on
pcolor(x(N+1-scale:N+1+scale),y(N+1-scale:N+1+scale),POffice_min(N+1-scale:N+1+scale,N+1-scale:N+1+scale))
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, OFFICE, Trx = -24dBm'})
xlabel('-15m < BaseStation < 15m')
ylabel('-15m < BaseStation < 15m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a=10; % horizontal radius
b=2;  % vertical radius 
x0=0; % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=4m, L=20m"');
hold off

figure(9)
hold on
pcolor(x(N+1-scale:N+1+scale),y(N+1-scale:N+1+scale),POfficeCombined_min(N+1-scale:N+1+scale,N+1-scale:N+1+scale))
title({'LOGPATH RECEIVED SIGNAL PLOT';'COMBINED-Stations, OFFICE, Trx = -24dBm'})
xlabel('-15m < BaseStation < 15m')
ylabel('-15m < BaseStation < 15m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=4m, L=20m"');
hold off


