function varargout = imageEditor(varargin)
% IMAGEEDITOR
% Aplikasi GUI MATLAB untuk pengolahan citra digital
% Fitur: open, save, reset, crop, efek citra, slider, dan histogram

gui_Singleton = 1;
gui_State = struct( ...
    'gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @imageEditor_OpeningFcn, ...
    'gui_OutputFcn',  @imageEditor_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);

if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

[varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
end

%%  OPENING 
function imageEditor_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.img = [];
handles.imgEdit = [];
handles.imgOriginal = [];
handles.isInvers = false;
handles.imgBeforeInvers = [];
handles.activeSlider = '';
handles.imgOriginalSlider = [];

% Kumpulan tombol efek 
handles.effectButtons = [
    handles.btnBlur
    handles.btnBrightness
    handles.btnContrast
    handles.btnGray
    handles.btn_sepia
    handles.btn_saturation
    handles.btn_hue
    handles.btnInvers
    handles.btnBiner
    handles.btnNoise
    handles.btnRotate
    handles.btnFlip
];

handles.defaultButtonColor = get(handles.btnBlur,'BackgroundColor');

% Slider nonaktif di awal
set(handles.sliderEffect,'Enable','off','Value',0);
guidata(hObject, handles);
end

% Output GUI
function varargout = imageEditor_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end

% UTIL 
% Reset warna 
function resetEffectButtonColors(handles)
for i = 1:length(handles.effectButtons)
    set(handles.effectButtons(i),'BackgroundColor',handles.defaultButtonColor);
end
end

% Menampilkan ulang gambar hasil edit + histogram
function applyAndRefresh(handles,hObject,effectName)
axes(handles.axesEdited);
imshow(handles.imgEdit);
axis image off
title(['Edited - ' effectName]);
updateHistogram(handles,effectName);
guidata(hObject,handles);
end

% Menampilkan histogram 
function updateHistogram(handles,effectName)
axes(handles.axesHistogram);
cla reset;

if isempty(handles.imgEdit)
    title('Histogram'); return;
end

img = handles.imgEdit;
if isa(img,'logical'), img = uint8(img)*255; end
if isa(img,'double'), img = im2uint8(img); end

if size(img,3)==3
    hold on;
    histogram(img(:,:,1),256,'EdgeColor','r');
    histogram(img(:,:,2),256,'EdgeColor','g');
    histogram(img(:,:,3),256,'EdgeColor','b');
    hold off;
    title(['Histogram RGB - ' effectName]);
else
    histogram(img(:),256);
    title(['Histogram Gray - ' effectName]);
end
end

% FILE 
% TOMBOL OPEN IMAGE
function btnOpenImage_Callback(hObject, eventdata, handles)
[file,path] = uigetfile({'*.jpg;*.png;*.jpeg'});
if isequal(file,0), return; end

img = imread(fullfile(path,file));
handles.img = img;
handles.imgEdit = img;
handles.imgOriginal = img;
handles.isInvers = false;

axes(handles.axesOriginal); imshow(img); axis image off; title('Original');
axes(handles.axesEdited); imshow(img); axis image off; title('Edited');

resetEffectButtonColors(handles);
set(handles.sliderEffect,'Enable','off','Value',0);
handles.activeSlider = '';
handles.imgOriginalSlider = [];

updateHistogram(handles,'Original');
guidata(hObject,handles);
end

% TOMBOL RESET
function btnReset_Callback(hObject, eventdata, handles)
if isempty(handles.imgOriginal), return; end
handles.imgEdit = handles.imgOriginal;
handles.isInvers = false;
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
resetEffectButtonColors(handles);
applyAndRefresh(handles,hObject,'Reset');
end

% TOMBOL KELUAR
function btnKeluar_Callback(hObject, eventdata, handles)
handles.img = [];
handles.imgEdit = [];
handles.imgOriginal = [];

axes(handles.axesOriginal); cla reset; title('Original');
axes(handles.axesEdited); cla reset; title('Edited');
axes(handles.axesHistogram); cla reset; title('Histogram');

handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
resetEffectButtonColors(handles);
guidata(hObject,handles);
end

% TOMBOL SAVE
function btnSave_Callback(hObject, eventdata, handles)
if isempty(handles.imgEdit), return; end
[file,path] = uiputfile({'*.jpg';'*.png'});
if isequal(file,0), return; end
imwrite(im2uint8(handles.imgEdit),fullfile(path,file));
msgbox('Gambar berhasil disimpan');
end

% TOMBOL INFO CITRA
function btnInfo_Callback(hObject, eventdata, handles)
if isempty(handles.imgEdit), return; end
img = handles.imgEdit;
info = sprintf('Resolusi: %dx%d\nChannel: %d\nClass: %s', ...
    size(img,2),size(img,1),size(img,3),class(img));
msgbox(info,'Info Citra');
end

% CROP 
function btnCropBebas_Callback(hObject, eventdata, handles)
if isempty(handles.imgEdit), return; end

hFig = figure('Name','Crop Image','NumberTitle','off',...
    'MenuBar','none','ToolBar','none','Resize','off');
imshow(handles.imgEdit);
axis image off
title('Drag untuk crop, double click untuk konfirmasi');

rect = getrect;
close(hFig);

if isempty(rect) || rect(3) < 5 || rect(4) < 5, return; end

handles.imgEdit = imcrop(handles.imgEdit, rect);

handles.imgOriginal = handles.imgEdit;
handles.imgOriginalSlider = handles.imgEdit;
handles.isInvers = false;
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);

applyAndRefresh(handles, hObject, 'Crop');
guidata(hObject, handles);
end

% EFFECT 
% Efek BLUR (Gaussian Filter)
function btnBlur_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.imgEdit = imgaussfilt(handles.imgEdit,2);
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Blur');
end

% Efek GRAYSCALE
function btnGray_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
if size(handles.imgEdit,3)==3
    handles.imgEdit = rgb2gray(handles.imgEdit);
end
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Gray');
end

% Efek INVERS
function btnInvers_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);

if ~handles.isInvers
    handles.imgBeforeInvers = handles.imgEdit;
    handles.imgEdit = imcomplement(handles.imgEdit);
    handles.isInvers = true;
else
    handles.imgEdit = handles.imgBeforeInvers;
    handles.isInvers = false;
end

handles.imgOriginalSlider = handles.imgEdit;
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Invers');
end

% Efek BRIGHTNESS (Slider)
function btnBrightness_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.activeSlider = 'brightness';
handles.imgOriginalSlider = handles.imgEdit;
set(handles.sliderEffect,'Enable','on','Min',0,'Max',0.5,'Value',0);
guidata(hObject,handles);
end

% Efek CONTRAST (Slider)
function btnContrast_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.activeSlider = 'contrast';
handles.imgOriginalSlider = handles.imgEdit;
set(handles.sliderEffect,'Enable','on','Min',0,'Max',1,'Value',0);
guidata(hObject,handles);
end

% Efek SATURATION (Slider)
function btn_saturation_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.activeSlider = 'saturation';
handles.imgOriginalSlider = handles.imgEdit;
set(handles.sliderEffect,'Enable','on','Min',0,'Max',1,'Value',0);
guidata(hObject,handles);
end

% Efek HUE (Slider)
function btn_hue_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.activeSlider = 'hue';
handles.imgOriginalSlider = handles.imgEdit;
set(handles.sliderEffect,'Enable','on','Min',0,'Max',1,'Value',0);
guidata(hObject,handles);
end

% Efek BINER
function btnBiner_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
img = handles.imgEdit;
if size(img,3)==3, img = rgb2gray(img); end
handles.imgEdit = imbinarize(img);
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Biner');
end

% Efek NOISE (Salt & Pepper)
function btnNoise_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.imgEdit = imnoise(handles.imgEdit,'salt & pepper',0.03);
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Noise');
end

% Efek SEPIA
function btn_sepia_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
img = im2double(handles.imgEdit);
R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
handles.imgEdit = cat(3,...
    min(0.393*R+0.769*G+0.189*B,1),...
    min(0.349*R+0.686*G+0.168*B,1),...
    min(0.272*R+0.534*G+0.131*B,1));
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Sepia');
end

% Efek ROTATE 90 DERAJAT
function btnRotate_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.imgEdit = imrotate(handles.imgEdit,90,'bilinear','loose');
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Rotate');
end

% Efek FLIP HORIZONTAL
function btnFlip_Callback(hObject, eventdata, handles)
resetEffectButtonColors(handles);
set(hObject,'BackgroundColor',[0.6 0.8 1]);
handles.imgEdit = fliplr(handles.imgEdit);
handles.activeSlider = '';
set(handles.sliderEffect,'Enable','off','Value',0);
applyAndRefresh(handles,hObject,'Flip');
end

% SLIDER
% SLIDER EFEK
function sliderEffect_Callback(hObject, eventdata, handles)
if isempty(handles.activeSlider) || isempty(handles.imgOriginalSlider)
    return;
end

v = get(hObject,'Value');

switch handles.activeSlider
    case 'brightness'
        handles.imgEdit = min(im2double(handles.imgOriginalSlider)+v,1);
    case 'contrast'
        handles.imgEdit = imadjust(handles.imgOriginalSlider,[],[],1+v);
    case 'saturation'
        if size(handles.imgOriginalSlider,3)~=3, return; end
        hsv = rgb2hsv(handles.imgOriginalSlider);
        hsv(:,:,2) = min(hsv(:,:,2)+v,1);
        handles.imgEdit = hsv2rgb(hsv);
    case 'hue'
        if size(handles.imgOriginalSlider,3)~=3, return; end
        hsv = rgb2hsv(handles.imgOriginalSlider);
        hsv(:,:,1) = mod(hsv(:,:,1)+v,1);
        handles.imgEdit = hsv2rgb(hsv);
end

axes(handles.axesEdited);
imshow(handles.imgEdit);
axis image off
title(['Edited - ' handles.activeSlider]);
updateHistogram(handles,handles.activeSlider);

guidata(hObject,handles);
end

% Warna background slider
function sliderEffect_CreateFcn(hObject, eventdata, handles)
set(hObject,'BackgroundColor',[.9 .9 .9]);
end
