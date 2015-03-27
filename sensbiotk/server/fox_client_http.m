function fox_client_http

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% FOX NODE HTTP CLIENT %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script for sending a GET request
% to the FOX PYTHON HTTP SERVER.
% The request reads real time data
% from one IMU connected to the
% FOX sink node.
% Either the HTTP server type chosen,
% it will enable the user to plot angles,
% initialize the frame, and stop the stream.
% Or just plot the raw accelerometer data.


% Author : Beno�t SIJOBERT
% Copyright : INRIA 2015 (sensbiotk.v2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matlabpool
%% Initializes variables
global HOST_IP;
HOST_IP = 'localhost';
global PORT;
PORT = '8000' ;
global Period;
Period = 0.010 ;
global data;
data = [];
global time_init;
global t1;
global figure_handle;
global plot_handle;
global measure_type;

%% Initializes initial time
time_init = clock; % the computer initial time

%% Choose server type (angle or raw values)
measure_type = 'angle'; % type angle or raw regarding the python server used

%% Creates a timer object and starts it
% Create a timer called every (Period+TimerFcn time), and
% associated to the read_data function.
t1 = timer('Period', Period, 'ExecutionMode', 'fixedRate','BusyMode','queue', 'TimerFcn', {@read_data});
start(t1);

%% Initializes and creates the figure for live plotting
init_plot();

%% Here the script for processing the stream data
while strcmp(get(t1,'Running'),'on')
     update_plot();
end
end

function read_data(obj, event, string_arg)
%% Read the datastream through a HTTP server get request
global HOST_IP
global PORT
global data
global time_init
global measure_type
switch measure_type
    case 'raw'
        [data_url, status] = urlread(...
            ['http://' HOST_IP ':' PORT]);
        if status
            time_read = clock;
            elapsed_time = etime(time_read, time_init)*1000; % elapsed time in ms
            data = [data; [elapsed_time sscanf(data_url,'%f',[1,9])]];
        end
        
        
    case 'angle'
        [data_url, status] = urlread(...
            ['http://' HOST_IP ':' PORT]);
        if status
            time_read = clock;
            elapsed_time = etime(time_read, time_init)*1000; % elapsed time in ms
            data = [data; [elapsed_time sscanf(data_url,'%f',[1,7])]];
        end
end
end

function init_frame(obj, event, string_arg)
global HOST_IP;
global PORT;
%% Send a http request for initializing the frame
urlread(['http://' HOST_IP ':' PORT],'Get',{'request','init'});
disp('--- FRAME INITIALIZED ---');
end

function stop_stream(obj, event, string_arg)
%% Stops the data stream and closes everything
global t1;
global data;
stop(t1);
real_fs = size(data,1)/(data(end,1)/1000);
disp(['Rate :' num2str(real_fs) 'Hz'])
close all
matlabpool close
end

function init_plot
%% Inits the plot figure
global figure_handle;
global plot_handle;
global measure_type;

% GUI
controls = figure('Visible','on','Position',[0,0,225,225],'MenuBar', 'none');
% Construct the components.
stop_stream_b = uicontrol('Style','pushbutton',...
    'String','STOP STREAM','Position',[50,50,140,25],'Callback',{@stop_stream});
if measure_type == 'angle'
    init_frame_b = uicontrol('Style','pushbutton',...
        'String','INIT FRAME','Position',[50,100,140,25],'Callback',{@init_frame});
end
movegui(controls, 'east')

figure_handle = figure('NumberTitle','off',...
    'Name','IMU DATA',...
    'Color',[0 0 0],'Visible','on','DeleteFcn',{@stop_stream},'MenuBar', 'none');
% Set axes
axes_handle = axes('Parent',figure_handle,...
    'YGrid','on',...
    'YColor',[0.9725 0.9725 0.9725],...
    'XGrid','on',...
    'XColor',[0.9725 0.9725 0.9725],...
    'Color',[0 0 0]);
hold on;
plot_handle = plot(axes_handle,0,0,'Marker','.','LineWidth',1,'Color',[0 1 0]);
% Create xlabel
xlabel('Time (ms)','FontWeight','bold','FontSize',14,'Color',[1 1 0]);
% Create ylabel
switch measure_type
    case 'raw'
        ylabel('ACC DATA','FontWeight','bold','FontSize',14,'Color',[0.5 0.5 1]);
    case 'angle'
        ylabel('EULER ANGLES','FontWeight','bold','FontSize',14,'Color',[0.5 0.5 1]);
end
% Create title
title('IMU DATA','FontSize',15,'Color',[0 1 1]);
end

function update_plot(obj, event, string_arg)
%% Update the plot for real time visualization
global data;
global plot_handle;
global figure_handle;
if size(data,1)>300
    set(gca,'xlim',[data(end-300,1) data(end,1)]);
    set(plot_handle,'YData', data(end-300:end,2),'XData',data(end-300:end,1),'Color',[1 0 0]);
    set(copyobj(plot_handle,gca) ,'YData', data(end-300:end,3),'XData',data(end-300:end,1),'Color',[0 1 0]);
    set(copyobj(plot_handle,gca) ,'YData', data(end-300:end,4),'XData',data(end-300:end,1),'Color',[0 0 1]);
else
    set(gca,'xlim',[0 data(end,1)]);
    set(plot_handle,'YData', data(:,2),'XData',data(:,1),'Color',[1 0 0]);
    set(copyobj(plot_handle,gca) ,'YData', data(:,3),'XData',data(:,1),'Color',[0 1 0]);
    set(copyobj(plot_handle,gca) ,'YData', data(:,4),'XData',data(:,1),'Color',[0 0 1]);
end
set(figure_handle, 'Visible', 'on');
end
