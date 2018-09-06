function varargout = operantBoxExitDialog2(varargin)
% OPERANTBOXEXITDIALOG2 MATLAB code for operantBoxExitDialog2.fig
%      OPERANTBOXEXITDIALOG2, by itself, creates a new OPERANTBOXEXITDIALOG2 or raises the existing
%      singleton*.
%
%      H = OPERANTBOXEXITDIALOG2 returns the handle to a new OPERANTBOXEXITDIALOG2 or the handle to
%      the existing singleton*.
%
%      OPERANTBOXEXITDIALOG2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPERANTBOXEXITDIALOG2.M with the given input arguments.
%
%      OPERANTBOXEXITDIALOG2('Property','Value',...) creates a new OPERANTBOXEXITDIALOG2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before operantBoxExitDialog2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to operantBoxExitDialog2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help operantBoxExitDialog2

% Last Modified by GUIDE v2.5 26-Jul-2017 12:12:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @operantBoxExitDialog2_OpeningFcn, ...
                   'gui_OutputFcn',  @operantBoxExitDialog2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before operantBoxExitDialog2 is made visible.
function operantBoxExitDialog2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to operantBoxExitDialog2 (see VARARGIN)

% Choose default command line output for operantBoxExitDialog2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes operantBoxExitDialog2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = operantBoxExitDialog2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global exitAfterTrialYN;
exitAfterTrialYN = 1;


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global exitNowYN;
exitNowYN = 1;


