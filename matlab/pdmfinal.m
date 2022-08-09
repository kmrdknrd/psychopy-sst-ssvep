function pdmfinal(demotest)
%% Record of revisions:
%   Date           Programmers               Description of change
%   ====        =================            =====================
%  01/10/18      Kitty Lui                  Converted from pdmexp5.m
%  01/16/18      Michael Nunez            Menu changes from pdmexp8.m
%  01/19/18      Kitty Lui                 Took out high/low spf -
%                                           calculate accuracy based on
%                                           rotation/shape
%  01/25/18      Kitty Lui                 Added the noise condition task 
%  02/12/18      Kitty Lui                 Added direction images 
%  02/28/18      Kitty Lui                 Changed back to gabor patches
%                                           and added perception task
%  03/13/18      Kitty Lui                Added gabor direction images
%                                          Changed genexp5 function on how
%                                          spf vector is generated 
%  04/19/18      Kitty Lui                 Changed snr levels
%  01/03/21    Michael Nunez          Corrected a comment about experiment timing 

%% Initial PTB3 Code

PsychJavaTrouble;   %make GetChar work (hack fix; needed?)

AssertOpenGL; %Issue warning if PTB3 with non-openGL used

% if strcmp(whichcmp,'k')
%     Screen('Preference', 'SkipSyncTests', 1);
% end

if ~IsLinux
    error('This program was written to run on Ubuntu Linux.');
end

%Find port for reponse box
devs = dir('/dev/ttyUSB*');
if isempty(devs)
    error('The Cedrus Response Box could not be found!');
end
    
if length(devs) > 1
    !dmesg | grep tty
    warning('There are multiple devices that could be the Cedrus Response Box!\n Find "ttyUSB*" in the above output on the same line as "FTDI USB Serial Device"');
end

if nargin > 1
    error('Too many function inputs.');
end
%% Experimenter Prompt

output = struct();
% task = randi(3);

%Inputs Prompt and Output Setup
%Experimenter Prompt
Screenres = get(0,'Screensize');

prompt1={'Subject Number (must begin with letter):','Session Number:','Task(1: S/R Mapping; 2:Noise 3: Perception)','Training session?','Cedrus Port [ttyUSB0 ...]:'};

def1={'SZZ_test','0','1','1',sprintf('/dev/%s',devs(1).name)};
studytitle='PDM Experiment 8';


lineNo=1;
answer=inputdlg(prompt1,studytitle,lineNo,def1);
%Subject Number
subnum = answer{1};
%ExpSession Number
sesnum = str2num(answer{2});
if isempty(sesnum)
    error('Please enter an appropriate session number (1 or greater)!');
end
output.sesnum = sesnum;
%Task number - 1: s/r mapping 2: noise 3: perception
task = str2num(answer{3});
output.task = task;
%Training session 'Real session - 0, Training - 1, 
training = str2num(answer{4});

%Window Pointer / 'Home Screen'.  0 - the primary monitor; 1 - the secondary monitor.
whichScreen = 0;
%Screen resolution on the x-axis
xres = Screenres(3);
output.xres = xres;
%Screen resolution on the y-axis
yres = Screenres(4);
output.yres = yres;
%This should be the same as the Refresh Rate shown in the Display
%Properties on the computer.  Always check before running the experiment to
%match flicker frequency.
%This code is currently set up to only handle multiples of 60 fps.
refrate = 120;
realrefrate = Screen(0,'FrameRate');
if refrate ~= Screen(0,'FrameRate')
    error(['The real screen refresh rate is set to ',num2str(realrefrate),...
       'Hz while the proposed screen refresh rate is ',num2str(refrate),'Hz.']);
end
output.refrate = refrate;
%Noise frequency (Hz)
noisehz = 40;
output.noisehz = noisehz;
if round(refrate/noisehz) ~= refrate/noisehz
    error('The noise frequency should be divisor of the refresh rate.');
end

%Gabor flicker frequency (Hz)
flickerhz = 30;
output.flickerhz = flickerhz;
% if round(refrate/flickerhz) ~= refrate/flickerhz
if round(refrate/2/flickerhz) ~= refrate/2/flickerhz
    error('The gabor flicker frequency should be divisor of half the refresh rate.');
end

%Trials per block
if training
    output.tperb = 16;
else
    output.tperb = 60;
end
if round(output.tperb/2) ~= output.tperb/2
    error('There should be an even number of trials per block.');
end

%Initialize block
block = 1;

%SNR
possnrs = [.5 .41 .35];
if task == 1 || task == 3
    snrs = possnrs(2);
else
    snrs = possnrs;
end
output.snrs = snrs;

%signal luminance
lowboundsnr = min(possnrs);
slum = lowboundsnr/(1 + lowboundsnr);

%Gabor spatial frequencies (cycles per degree at 57 cm)
gaborspf = [2.35 2.65 2.4 2.6 2.45 2.55];

%Noise spatial frequency (cycles per degree at 57 cm)
noisespf = 10;

%Radius of fixation spot (degrees visual angle at 57 cm)
fixrad = .10;

%Cedrus Handle
cport = answer{5};
try
    chandle = CedrusResponseBox('Open',cport);
catch me1
    rethrow(me1);
    fprintf('Cedrus port may need a ''chmod 777'' if you''re getting permission issues.\n');
end

%% Load macro experiment information


%Define block types
temptype{1} = [1 2 3 4 5 6];
temptype{2} = [1 3 2 4 6 5];
temptype{3} = [3 2 1 6 5 4];
temptype{4} = [3 1 2 6 4 5];
temptype{5} = [2 1 3 5 4 6];
temptype{6} = [2 3 1 5 6 4];

randtype = randperm(numel(temptype));

if training
    blocktype = [1 2 3 4 5 6];
else
    blocktype = temptype{randtype(1)};
end


if ~exist([pwd,'/pdmfinalbehav'],'dir')
   mkdir('pdmfinalbehav');
end

if exist('pdmfinalbehav/macroinfo.mat','file') && sesnum ~= 1
    fprintf('Loading macro experiment information to obtain blocktype...\n');
    macroinfo = load('pdmfinalbehav/macroinfo.mat');
    subsesfield = sprintf('%s_ses%d',subnum,sesnum-1);
    if isfield(macroinfo,subsesfield)
        lastses = macroinfo.(subsesfield).blocktype;
       if strcmp(num2str(lastses),num2str(temptype{1}))
               blocktype = temptype{8};
       elseif strcmp(num2str(lastses),num2str(temptype{2}))
               blocktype = temptype{7};
       elseif strcmp(num2str(lastses),num2str(temptype{3}))
               blocktype = temptype{6};
       elseif strcmp(num2str(lastses),num2str(temptype{4}))
               blocktype = temptype{5};
       elseif strcmp(num2str(lastses),num2str(temptype{5}))
               blocktype = temptype{4};
       elseif strcmp(num2str(lastses),num2str(temptype{6}))
               blocktype = temptype{3};
       elseif strcmp(num2str(lastses),num2str(temptype{7}))
               blocktype = temptype{2};
       elseif strcmp(num2str(lastses),num2str(temptype{8}))
               blocktype = temptype{1};
       else
       end
    end
end

%% Subject Prompt
if task == 1
    prompt2={'Block Order 1. EO 2.SPF 3. OxSPF 4. EO 5.SPF 6. OxSPF',...
    'What is your gender?',...
    'Age:',...
    'Do you consider yourself right handed, left handed, or both?  (''r'',''l'', or''b'')',...
    'Visual acuity result? (''20/30'' or ''20/35'' or ''20/20'')',...
    'What is your EEG cap size? (''Large'', ''Medium'', or ''Small'')',...
    'Approximate time since last caffeinated beverage in hours:',...
    'Do you have any personal or family history of epilepsy? (''y'' or ''n'')'
    };
elseif task == 2
     prompt2={'Block Order 1. LOW 2.MED 3. HIGH 4. LOW 5. MED 6. HIGH',...
    'What is your gender?',...
    'Age:',...
    'Do you consider yourself right handed, left handed, or both?  (''r'',''l'', or''b'')',...
    'Visual acuity result? (''20/30'' or ''20/35'' or ''20/20'')',...
    'What is your EEG cap size? (''Large'', ''Medium'', or ''Small'')',...
    'Approximate time since last caffeinated beverage in hours:',...
    'Do you have any personal or family history of epilepsy? (''y'' or ''n'')'
    };
else 
     prompt2={'Block Order 1. EASY 2.MED 3. HARD 4. EASY 5. MED 6. HARD',...
    'What is your gender?',...
    'Age:',...
    'Do you consider yourself right handed, left handed, or both?  (''r'',''l'', or''b'')',...
    'Visual acuity result? (''20/30'' or ''20/35'' or ''20/20'')',...
    'What is your EEG cap size? (''Large'', ''Medium'', or ''Small'')',...
    'Approximate time since last caffeinated beverage in hours:',...
    'Do you have any personal or family history of epilepsy? (''y'' or ''n'')'
    };
end

def2={sprintf('[%s]',num2str(blocktype)),'','','','','','',''};
demographtitle='Subject Demographics';
lineNo=1;
subdemo=inputdlg(prompt2,demographtitle,lineNo,def2);
switch subdemo{8}
    case 'n'
    otherwise
        CedrusResponseBox('Close',chandle);
        error('You have indicated that you have a personal or family history of epilepsy. This experiment involves a fast flickering image. It is recommended that you NOT participate in this study due to a possible risk of seizure.  Please discuss your options with the experimenters.');
end
output.gender = subdemo{2};
output.age = str2num(subdemo{3});
output.hand = subdemo{4};
output.vision = subdemo{5};
output.capsize = subdemo{6};
output.caffeine = subdemo{7};

blocktype=str2num(subdemo{1});
output.blocktype = blocktype;

%Number of blocks
blocknum = length(blocktype);
if blocknum < 6
    skipeyes = 1;
else
    skipeyes = 0;
end

%Number of Trials
trialnum = blocknum*output.tperb;

%% Code

%Get date and time that the session begins
output.date = date;
output.start_time = clock;
    
%number of rows and columns of image
nCols = 1000;
nRows = 1000;

%Initialize estimated accuracy and speed_cutoff vectors
estcorrect = nan(1,trialnum);
% speed_cutoff = nan(1,trialnum);
% given_feedback = nan(1,trialnum);
condition = nan(1,trialnum);

%Keyboard keypress variables
advancechar = ' ';
escapechar = 27;

%Colors
% black = round([0 0 .5]*255); %Blue
% black2 = round([.5 .5 0]*255); %Yellow
black = [0 0 0];
white = [255 255 255];
gray = 255*[.5 .5 .5];
%darkgray = 255*[.25 .25 .25];
blackwhite{1} = black;
blackwhite{2} = white;

% Load fonts
myfont = '-bitstream-courier 14 pitch-bold-i-normal--0-0-0-0-m-0-ascii-0';
fontsize = 26;

%Define photocell placement
 photorect = [0 0 100 100];
% pRect(1,:) = CenterRectOnPoint(photorect, 50, 50);
% pRect(2,:) = CenterRectOnPoint(photorect,xres - 50, 50);
% pRect(3,:) = CenterRectOnPoint(photorect,xres - 50, yres - 50);
% pRect(4,:) = CenterRectOnPoint(photorect, 50, yres - 50);
pRect(1,:) = CenterRectOnPoint(photorect,xres - 50, yres - 50);
pRect(2,:) = CenterRectOnPoint(photorect, 50, yres - 50);

fullscreen = CenterRectOnPoint([0 0 xres yres],round(xres/2),round(yres/2));

%Define button instruction placement
% instRow = 374;
% instCol = 504;
instRow = 493;
instCol = 443;
instCol2 = instCol*2;
leftinstruct = CenterRectOnPoint(SetRect(0,0, instCol, instRow), 600, 900);
% middleinstruct = CenterRectOnPoint(SetRect(0,0, instCol, instRow), 1000, 900);
rightinstruct = CenterRectOnPoint(SetRect(0,0, instCol, instRow), 1300, 900);
leftinstruct2 = CenterRectOnPoint(SetRect(0,0, instCol2, instRow), 500, 935);
rightinstruct2 = CenterRectOnPoint(SetRect(0,0, instCol2, instRow), 1400, 935);


%Flush Cedrus Events
CedrusResponseBox('FlushEvents',chandle);


%The following TRY, CATCH, END statement ends psychtoolbox if an error
%occurs
try
    %Open a fullscreen window on the first screen with black background
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseVirtualFramebuffer');
%     PsychImaging('AddTask','FinalFormatting''DisplayColorCorrection','SimpleGamma'); %apply power-law based gamma correction: http://docs.psychtoolbox.org/PsychColorCorrection
    [wptr,windowRect] = PsychImaging('OpenWindow', whichScreen,gray);
    PsychGPUControl('FullScreenWindowDisablesCompositor', 1);

    %sets size of gabor field that will be pasted onto Screen
    imageRect=SetRect(0,0,nCols,nRows);
    destRect=CenterRect(imageRect,windowRect);

    %Creates a window of a black screen with gray circle and fixation spot
    fiximage = makefixation([],fixrad);
    fiximage(fiximage == 1) = gray(1); %Gamma correction, gray
    fiximage(isnan(fiximage)) = gray(1);
    fiximage(fiximage == 0) = black(1);
    fixglind = Screen('MakeTexture',wptr,fiximage);
    blackfix = (makefixation([],fixrad) == 0);
    
    %This vector defines the noise frequency for our image
    noiseflic = [];
    for i=1:ceil(4*noisehz)
        noiseflic = [noiseflic 1 zeros(1,(round(refrate/noisehz)- 1))];
    end
    noiseonfind = find(noiseflic);
    
    %This vector defines the Gabor flicker frequency for our image
    gaborflic = [];
    for i=1:ceil(4*flickerhz)
        gaborflic = [gaborflic 2*ones(1,round(refrate/2/flickerhz)) ones(1,round(refrate/2/flickerhz))];
    end
    
    %Set seed based on the time.
    output.seed = round(sum(100*clock));
    % rng('default');  Backwards compatible with older MATLAB versions
    rng(output.seed);

    %Gabor will not be shown for the first 500ms to 1000ms of the trial
    numframes = round(refrate/noisehz);
    minframe = round(.5*refrate/numframes)*numframes;
    maxframe = round(refrate/numframes)*numframes;
    posframes = minframe:numframes:maxframe;
    trialnframes = posframes(randi(length(posframes),1,trialnum));
    output.noisetimes = trialnframes/refrate;
    
    %Inter-trial interval, 1500ms to 2000ms
    output.intertrial = 1.5 + rand(1,trialnum)*.5;
    
    %Create block instructions
   
    
    if task == 1 || task == 3
        %Define SNR vector, ensure even cell counts
        snrvec = [];
        for b=1:blocknum
            blkvec = [];
            for n=1:length(snrs)
                blkvec = [blkvec snrs(n)*ones(1,output.tperb/length(snrs))];
            end
            snrvec = [snrvec blkvec(randperm(numel(blkvec)))];
        end
        output.snrvec = snrvec;
    else
        %Define SNR vector for 3 different noise conditions
        snrvec = [];
        for b=1:blocknum
            if blocktype(b) == 1 || blocktype(b) ==  4
                blkvec = ones(1,output.tperb)*snrs(1);
            elseif blocktype(b) == 2 || blocktype(b) == 5 
                blkvec = ones(1,output.tperb)*snrs(2);
            else
                blkvec = ones(1,output.tperb)*snrs(3);
            end
            snrvec = [snrvec blkvec];
        end
        output.snrvec = snrvec;

        %%Define 6 block prompts for noise conditions 
        
    end
 
    %block prompts
    if task == 1 
        %%Define 6 block prompts 
        blockprompt{1} = ['Press the YELLOW button when you see any gabor.'];
        blockprompt{2} = ['Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{3} = ['When you see GREATER number parallel bars pointed at the top right' newline 'or LESS number of parallel bars pointed at the top left' newline 'press the YELLOW button' ...
            newline newline 'When you see LESS number of parallel bars pointed at the top right' newline 'or GREATER number of parallel bars pointed at the top left' newline 'press the BLUE button'];
        blockprompt{4} = ['Press the BLUE button when you see any gabor.'];
        blockprompt{5} = ['Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{6} = ['When you see GREATER number parallel bars pointed at the top right' newline 'or LESS number of parallel bars pointed at the top left' newline 'press the YELLOW button' ...
            newline newline 'When you see LESS number of parallel bars pointed at the top right' newline 'or GREATER number of parallel bars pointed at the top left' newline 'press the BLUE button'];
    elseif task == 2
        blockprompt{1} = ['This is a LOW noise block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{2} = ['This is a MEDIUM noise block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{3} = ['This is a HIGH noise block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{4} = ['This is a LOW noise block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{5} = ['This is a MEDIUM noise block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{6} = ['This is a HIGH noise block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see a LESS number of parallel bars.']; 
    else
        blockprompt{1} = ['This is an EASY block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{2} = ['This is a MEDIUM block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{3} = ['This is a HARD block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{4} = ['This is an EASY block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{5} = ['This is a MEDIUM block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
        blockprompt{6} = ['This is a HARD block.' newline 'Press the YELLOW button when you see GREATER number of parallel bars.' newline 'Press the BLUE button when you see LESS number of parallel bars.'];
    end
    
        
        
    cut = 0; %Counter for ESC
    
    %Calculate the number of frames in a cycle of an image flicker
    numCycleFrames = trialnframes + ceil(refrate*1.5) + ceil(refrate*rand(1,trialnum)*.5);

%     %Find the indices of 600, 900, and 1500 ms after the beginning of the noise onset dependent upon the blocktype
%     speednframes{1} = trialnframes + ceil(refrate*.6);
%     speednframes{2} = trialnframes + ceil(refrate*.9);
%     speednframes{3} = trialnframes + ceil(refrate*1.5);
%     speednframes{4} = trialnframes + ceil(refrate*.6);
%     speednframes{5} = trialnframes + ceil(refrate*.9);
%     speednframes{6} = trialnframes + ceil(refrate*1.5);

    %Output stimulus display time in seconds
    output.stimtime = (numCycleFrames/refrate);
    
    %Initialize recording of trialflic
    output.trialflic = cell(1,trialnum);
    output.noiseflic = cell(1,trialnum);
    
    output.nlum = slum./snrvec; %noise luminance
    
    Screen('TextFont',wptr,'Arial');
    Screen('TextSize',wptr,18);
    ShowCursor(0);	% arrow cursor
    sessiontext = 'Loading images...';
    sessiontext2 = sprintf('The experiment will begin soon!');
    sessiontext4 = blockprompt{blocktype(block)};
    if ~training
        sessiontext3 = sprintf('Please keep your eyes fixated on the dot. Session %d has started! Good luck!',sesnum);
    else
        sessiontext3 = sprintf('Please keep your eyes fixated on the dot. A practice session has started! Good luck!',sesnum);
    end
    sessiontext5 = 'Let''s record your brain rhythms with your eyes closed for two minutes!';
    sessiontext6 = 'Let''s record your brain rhythms with your eyes fixated on the center dot for two minutes!';
    trialtext3 = 'Please wait for the experimenter';
    trialtext4 = 'Press the middle button to continue';
    
    HideCursor;

    if training | skipeyes
        Screen('DrawTexture',wptr,fixglind,[],destRect);
        Screen('TextSize', wptr, fontsize);
        Screen('TextFont', wptr, myfont);
        DrawFormattedText(wptr, [sessiontext,'\n\n'], 'center', 'center', black);
        Screen(wptr,'Fillrect',black,pRect'); 
        Screen('Flip',wptr);
    else

        %Display the eyes closed text screen
        Screen('DrawTexture',wptr,fixglind,[],destRect);
        Screen('TextSize', wptr, fontsize);
        Screen('TextFont', wptr, myfont);
        DrawFormattedText(wptr, [sessiontext2,'\n\n',sessiontext5], 'center', 'center', black);
        Screen(wptr,'Fillrect',black,pRect'); 
        Screen('Flip',wptr);

        %Wait for spacebar
        FlushEvents('keyDown');
        [char,when] = GetChar; %Wait for keypress to continue
        notspace=1;
        while notspace
            switch char
                case ' '
                    notspace =0;
                case escapechar %Escape from experiment
                    notspace =0;
                    %RestoreScreen(whichScreen);
                    ShowCursor;
                    Screen('CloseAll');
                    warning on all;
                    CedrusResponseBox('Close',chandle);
                    return
                otherwise
                    [char,when] = GetChar; %Wait for keypress to continue
                    notspace =1;
            end
        end

        %Display the eyes closed text screen, wait for subject to press the middle button
        Screen('DrawTexture',wptr,fixglind,[],destRect);
        Screen('TextSize', wptr, fontsize);
        Screen('TextFont', wptr, myfont);
        DrawFormattedText(wptr, [trialtext4,'\n\n',sessiontext5], 'center', 'center', black);
        Screen(wptr,'FillRect',black,pRect'); 
        Screen('Flip',wptr);

        CedrusResponseBox('FlushEvents',chandle);
        notmiddle = 1;
        while notmiddle
            evt = CedrusResponseBox('WaitButtonPress',chandle);
            if evt.button == 5
                notmiddle = 0;
            end
        end
        CedrusResponseBox('FlushEvents',chandle);
        
        %Pause while recording eye closed data
        Screen(wptr,'FillRect',black,fullscreen); %black out the screen
        Screen(wptr,'FillRect',black,pRect'); 
        Screen('Flip',wptr);
    end

    %Track generation time
    tic;

    %Load hand position images and resize
    hard_high = imread('example_images/pdmfinal/hard_high.jpg');
    hard_high = imresize(hard_high, [instRow instCol]);
    hard_hightext = Screen('MakeTexture',wptr,hard_high);
    hard_low = imread('example_images/pdmfinal/hard_low.jpg');
    hard_low = imresize(hard_low, [instRow instCol]);
    hard_lowtext = Screen('MakeTexture',wptr,hard_low);
    med_high = imread('example_images/pdmfinal/med_high.jpg');
    med_high = imresize(med_high, [instRow instCol]);
    med_hightext = Screen('MakeTexture',wptr,med_high);
    med_low = imread('example_images/pdmfinal/med_low.jpg');
    med_low = imresize(med_low, [instRow instCol]);
    med_lowtext = Screen('MakeTexture',wptr,med_low);
    easy_high = imread('example_images/pdmfinal/easy_high.jpg');
    easy_high = imresize(easy_high, [instRow instCol]);
    easy_hightext = Screen('MakeTexture',wptr,easy_high);
    easy_low = imread('example_images/pdmfinal/easy_low.jpg');
    easy_low = imresize(easy_low, [instRow instCol]);
    easy_lowtext = Screen('MakeTexture',wptr,easy_low);
    dim_blue = imread('example_images/pdmfinal/2dim_blue.jpg');
    dim_blue = imresize(dim_blue, [instRow instCol2]);
    dim_bluetext = Screen('MakeTexture',wptr,dim_blue);
    dim_yellow = imread('example_images/pdmfinal/2dim_yellow.jpg');
    dim_yellow = imresize(dim_yellow, [instRow instCol2]);
    dim_yellowtext = Screen('MakeTexture',wptr,dim_yellow);

%     %Load Feedback Images and resize
%     posImage=imread('Happyface.jpeg');
%     posImage = posImage(:,:,1);
%     unsImage=imread('unsureface.jpg');
%     unsImage = unsImage(:,:,1);
%     negImage=imread('sadface.jpg');
%     negImage = negImage(:,:,1);
% 
%     %fix Feedback Images to make adjustable Black and Gray Image
%     posImage(posImage<10)=black(1);
%     posImage(posImage>10)=gray(1);
%     unsImage(unsImage<10)=black(1);
%     unsImage(unsImage>10)=gray(1);
%     negImage(negImage<10)=black(1);
%     negImage(negImage>10)=gray(1);
%     
%    
%     % Resize Feedback Images
%     posImage=imresize(posImage,[nRows nCols]);
%     unsImage=imresize(unsImage,[nRows nCols]);
%     negImage=imresize(negImage,[nRows nCols]); 
%     
%     %Add fixation cross to Images
%     posImage(blackfix)=black(1);
%     unsImage(blackfix)=black(1);
%     negImage(blackfix)=black(1);
%     
%     %Write Images as textures
%     posTex=Screen('MakeTexture',wptr,posImage);
%     unsTex=Screen('MakeTexture',wptr,unsImage);
%     negTex=Screen('MakeTexture',wptr,negImage);
%     
    %Generate Gabor and noise images for all blocks
    noisecount = noisehz*4;
    %pregenexp5(noisecount,noisespf,trialnum,gaborspf,fixrad);
    [noises, allgabors, allspfs, allrandrot] = genexp5(noisecount,noisespf,trialnum,gaborspf,fixrad,task,blocknum,blocktype,output);
    
    %Concatenate Gabor patches from high and low distributions    gabors = cat(3,allgabors{2},allgabors{1});
%     spfs = [allspfs{2} allspfs{1}];

    gabors = allgabors;
    randrots = allrandrot';
    spfs = allspfs;
    
    %Index of LESS number of parallel barss and GREATER number of parallel barss
%     temp = [ones(1,(trialnum/2))*2 ones(1,(trialnum/2))*1]; %%UNCOMMENT
%     if sesnum <= 1
%         repthisperm = randperm(trialnum,output.tperb); %Create first random permulation of length: trials per block
%         spfperm = [];
%         for b=1:blocknum
%             spfperm = [spfperm repthisperm(randperm(output.tperb))]; %If it is the training session, repeat exact distribution draws
%         end
%     else
%         shapeperm = randperm(trialnum); %%UNCOMMENT
%     end
%     output.GREATER number of parallel barsrec = randsizes; %Index if it was LESS number of parallel bars and GREATER number of parallel bars
%     clear temp;
%     gabors = gabors(:,:,shapeperm);
%     output.shapes = randsizes(shapeperm); %%Might not need this? %%1 - GREATER number of parallel bars; 2 - LESS number of parallel bars
    output.randrots = randrots;
    output.spfs = spfs;
%     output.gabor = gabors;
%     altperm = randperm(trialnum);
%     output.randrots = randrots(altperm);
    
    %Locate fixation spot
   
    %Locate fixation spot
    blackfix = (makefixation([],fixrad) == 0);
    
    %Locate border spot
    %darkfix = (makefixborder([],fixrad) == 0);
    
    %Change NaN to gray
    noises(isnan(noises)) = 0;
    gabors(isnan(gabors)) = 0;
    
    %Random order of noise images
    whichnoises = nan(trialnum,noisehz*4);
    for t=1:trialnum
        whichnoises(t,:) = randperm(noisehz*4);
    end
    
    %Index for unique SNRs
    [thesesnrs,~,usnrs] = unique(snrvec); 
    
    %Multiply each noise matrix by its luminance
    trialnoises = nan(size(noises,1),size(noises,2),numel(snrs),noisehz*4);
    for b=1:numel(thesesnrs)
        splum = slum./thesesnrs(b); %noise luminance
        trialnoises(:,:,b,:) = splum.*noises;
    end
    thesenoises = 255*(trialnoises/2 + .5);
    %thesenoises(repmat(repmat(darkfix,1,1,b),1,1,1,noisehz*4)) = darkgray(1); %Recreate border
    thesenoises(repmat(repmat(blackfix,1,1,b),1,1,1,noisehz*4)) = black(1); %Recreate fixation spot
    noisescreen = nan(1,size(noises,3));
    
    %Create noise images as OpenGL textures
    for n=1:(noisehz*4)
        for b=1:numel(snrs)
            noisescreen(b,n) = Screen('MakeTexture',wptr,thesenoises(:,:,b,n)); %The square root is in order to account for monitor gamma. That is, the monitor approximately squares the input stimulus color value
        end
    end
    clear thesenoises noises
    
    %Save generation time
    output.gentime = toc;

    if ~training & ~skipeyes
        %Pause while recording eye closed data
        pause(120-output.gentime);

        %Display the eyes open text screen
        Screen(wptr,'FillRect',gray,fullscreen); %black out the screen
        Screen('DrawTexture',wptr,fixglind,[],destRect);
        Screen('TextSize', wptr, fontsize);
        Screen('TextFont', wptr, myfont);
        DrawFormattedText(wptr, [sessiontext2,'\n\n',sessiontext6], 'center', 'center', black);
        Screen(wptr,'FillRect',black,pRect'); 
        Screen('Flip',wptr);

        %Wait for spacebar
        FlushEvents('keyDown');
        [char,when] = GetChar; %Wait for keypress to continue
        notspace=1;
        while notspace
            switch char
                case ' '
                    notspace =0;
                case escapechar %Escape from experiment
                    notspace =0;
                    %RestoreScreen(whichScreen);
                    ShowCursor;
                    Screen('CloseAll');
                    warning on all;
                    CedrusResponseBox('Close',chandle);
                    return
                otherwise
                    [char,when] = GetChar; %Wait for keypress to continue
                    notspace =1;
            end
        end

        %Display the eyes closed text screen, wait for subject to press the middle button
        Screen('DrawTexture',wptr,fixglind,[],destRect);
        Screen('TextSize', wptr, fontsize);
        Screen('TextFont', wptr, myfont);
        DrawFormattedText(wptr, [trialtext4,'\n\n',sessiontext6], 'center', 'center', black);
        Screen(wptr,'FillRect',black,pRect'); 
        Screen('Flip',wptr);

        CedrusResponseBox('FlushEvents',chandle);
        notmiddle = 1;
        while notmiddle
            evt = CedrusResponseBox('WaitButtonPress',chandle);
            if evt.button == 5
                notmiddle = 0;
            end
        end
        CedrusResponseBox('FlushEvents',chandle);
        
        %Pause while recording eye closed data
        Screen('DrawTexture',wptr,fixglind,[],destRect);
        Screen(wptr,'FillRect',black,pRect'); 
        Screen('Flip',wptr);
        pause(120);
    end


    %Display second text screen
    Screen('DrawTexture',wptr,fixglind,[],destRect);
    Screen('TextSize', wptr, fontsize);
    Screen('TextFont', wptr, myfont);
    % Screen('DrawText',wptr, sessiontext2,(xres - length(sessiontext2))/2,yres*(5/12),black);
    % Screen('DrawText',wptr, sessiontext4,(xres - length(sessiontext4))/2,yres*(5/12) + 32,black);
    DrawFormattedText(wptr, [sessiontext2 '\n\n',sessiontext4], 'center', 'center', black);
    if task == 3
        if blocktype(block) == 3 || blocktype(block) == 6
            Screen('DrawTexture',wptr,hard_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,hard_hightext,[],rightinstruct);
        elseif blocktype(block) == 2 || blocktype(block) == 5
            Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
        else 
            Screen('DrawTexture',wptr,easy_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,easy_hightext,[],rightinstruct);
        end
    elseif task == 1
        if blocktype(block) == 2 || blocktype(block) == 5
            Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
        elseif blocktype(block) == 3 || blocktype(block) == 6
            Screen('DrawTexture',wptr,dim_bluetext,[],leftinstruct2);
            Screen('DrawTexture',wptr,dim_yellowtext,[],rightinstruct2);
        else
        end
    else
        Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
        Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
    end

    Screen(wptr,'FillRect',black,pRect'); 
    Screen('Flip',wptr);
    
    %Wait for spacebar
    FlushEvents('keyDown');
    [char,when] = GetChar; %Wait for keypress to continue
    notspace=1;
    while notspace
        switch char
            case ' '
                notspace =0;
            case escapechar %Escape from experiment
                notspace =0;
                %RestoreScreen(whichScreen);
                ShowCursor;
                Screen('CloseAll');
                warning on all;
                CedrusResponseBox('Close',chandle);
                return
            otherwise
                [char,when] = GetChar; %Wait for keypress to continue
                notspace =1;
        end
    end
    
    %Wait for subject to press the middle button
    Screen('DrawTexture',wptr,fixglind,[],destRect);
    Screen('TextSize', wptr, fontsize);
    Screen('TextFont', wptr, myfont);
    DrawFormattedText(wptr, [trialtext4,'\n\n',sessiontext4], 'center', 'center', black);
    if task == 3
        if blocktype(block) == 3 || blocktype(block) == 6
            Screen('DrawTexture',wptr,hard_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,hard_hightext,[],rightinstruct);
        elseif blocktype(block) == 2 || blocktype(block) == 5
            Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
        else 
            Screen('DrawTexture',wptr,easy_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,easy_hightext,[],rightinstruct);
        end
    elseif task == 1
        if blocktype(block) == 2 || blocktype(block) == 5
            Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
            Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
        elseif blocktype(block) == 3 || blocktype(block) == 6
            Screen('DrawTexture',wptr,dim_bluetext,[],leftinstruct2);
            Screen('DrawTexture',wptr,dim_yellowtext,[],rightinstruct2);
        else
        end
    else
        Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
        Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
    end

    Screen(wptr,'FillRect',black,pRect'); 
    Screen('Flip',wptr);
    
    CedrusResponseBox('FlushEvents',chandle);
    notmiddle = 1;
    while notmiddle
        evt = CedrusResponseBox('WaitButtonPress',chandle);
        if evt.button == 5
            notmiddle = 0;
        end
    end
    CedrusResponseBox('FlushEvents',chandle);
    
    %Display third text screen
    Screen('DrawTexture',wptr,fixglind,[],destRect);
    Screen('TextSize', wptr, fontsize);
    Screen('TextFont', wptr, myfont);
    % Screen('DrawText',wptr, sessiontext3,(xres - length(sessiontext3))/2,yres*(5/12),black);
    DrawFormattedText(wptr, [sessiontext3,'\n\n'], 'center', 'center', black);
    Screen(wptr,'FillRect',black,pRect'); 
    Screen('Flip',wptr);
    pause(2);
    
    %Pause before beginning of the block, pause for a second after text
    Screen('DrawTexture',wptr,fixglind,[],destRect);
    Screen(wptr,'FillRect',black,pRect'); 
    Screen('Flip',wptr);
    pause(1);
    
    %Initialize timer
    tic;
    for trials = 1:trialnum
      %printiter(trials);
      if ~cut %ESC key track
        %trialinbl = trials - output.tperb*(block-1);
        
        %Create image with specified snr
        trialgabor = slum*gabors(:,:,trials);
        %Shift domain to [0 1], convert to appropriate luminance
        %transformation for gaborimage color values, takes into account
        %monitor gamma
        if trials == 1
            bothscreen = nan(1,noisehz*4);
        end
        for n=1:noisehz*4
            thisimage = 255*( (trialgabor(:,:)+trialnoises(:,:,usnrs(trials),whichnoises(trials,n)) ...
               )/2 + .5);
            %thisimage(darkfix) = darkgray(1);
            thisimage(blackfix) = black(1);
            if trials > 1 %Clear former textures to save memory
                Screen('Close',bothscreen(n));
            end
            bothscreen(n) = Screen('MakeTexture',wptr,thisimage);
        end
        clear trialgabor fixx fixy trialflic
        
        trialflic = [ones(1,trialnframes(trials)) gaborflic];
        output.trialflic{trials} = trialflic;
        output.noiseflic{trials} = noiseflic;
          
        %Wait at least lboundwait seconds between trials
        lboundwait = output.intertrial(trials);
        output.elapsedtime(trials) = toc;
        if output.elapsedtime(trials) < lboundwait
            pause(lboundwait-output.elapsedtime(trials));
        end
        output.fixedtime(trials) = toc;
        
        CedrusResponseBox('FlushEvents',chandle);
        
        %Display rush loops (Rush is apparently obsolete in PTB3, test this)
        Priority(MaxPriority(wptr)); %New to PTB3
        
          %Loop 1: Noise interval for 500ms - 1000ms
        %Response interval for 1500ms - 2000ms, accept responses
        noisenum = 0;
        bwswitch = 1;
        clearresp = 0;
        evt = [];
        for i = 1:numCycleFrames(trials)
            if noiseflic(i)
                noisenum = noisenum + 1;
                bwswitch = mod(bwswitch,2) + 1; %Changes 1 to 2 and vica versa
            end
            if trialflic(i) == 2
                Screen('DrawTexture',wptr,bothscreen(noisenum),[],destRect);
                if clearresp == 0
                    clearresp = 1;
                end
            else
                Screen('DrawTexture',wptr,noisescreen(usnrs(trials),whichnoises(trials,noisenum)),[],destRect);
            end
            Screen(wptr,'FillRect',blackwhite{bwswitch},pRect(1,:)');
            Screen(wptr,'FillRect',blackwhite{trialflic(i)},pRect(2,:)');
            Screen('Flip',wptr);
            if clearresp == 1 %Flush Cedrus box responses after the noise interval
                CedrusResponseBox('FlushEvents',chandle);
                clearresp = 2;
            end
        end
    
        %Loop 2: Keep displaying black fixation spot (only) for 250ms to collect responses
        for frames = 1:round(refrate/4)
            Screen('DrawTexture',wptr,fixglind,[],destRect);
            Screen(wptr,'FillRect',black,pRect'); 
            Screen('Flip',wptr);
        end

        %Timer to calculate time between the last trial and the next
        tic;
        
        %Calculate trial accuracy
        if isempty(evt)
            evt = CedrusResponseBox('GetButtons',chandle);
        end
        if task == 1
            if blocktype(block) == 1 
                if isempty(evt)
                    correct = NaN;
                elseif evt.button == 6
                    correct = 1;
                else
                    correct = 0;
                end
            elseif blocktype(block) == 4
                if isempty(evt)
                    correct = NaN;
                elseif evt.button == 4
                    correct = 1;
                else
                    correct = 0;
                end
            elseif blocktype(block) == 2 || blocktype(block) == 5
                if isempty(evt)
                    correct = NaN;
                elseif (evt.button == 6 && output.spfs(trials) == gaborspf(4)) || ...
                        (evt.button == 4 && output.spfs(trials) == gaborspf(3))
                    correct = 1;
                else
                    correct = 0;
                end
            else
                if isempty(evt)
                    correct = NaN;
                elseif (evt.button == 6 && output.spfs(trials) == gaborspf(4) && output.randrots(trials) == 45) || ...
                    (evt.button == 6 && output.spfs(trials) == gaborspf(3) && output.randrots(trials) == -45) || ...
                    (evt.button == 4 && output.spfs(trials) == gaborspf(4) && output.randrots(trials) == -45) || ....
                    (evt.button == 4 && output.spfs(trials) == gaborspf(3) && output.randrots(trials) == 45)
                        correct = 1;
                else
                    correct = 0;
                end
            end
        elseif task == 2
            if isempty(evt)
                    correct = NaN;
            elseif (evt.button == 6 && output.spfs(trials) == gaborspf(4)) || ...
                   (evt.button == 4 && output.spfs(trials) == gaborspf(3))
                correct = 1;
            else
                correct = 0;
           end
        else
            if isempty(evt)
                    correct = NaN;
            elseif (evt.button == 6 && output.spfs(trials) > 2.5) || ...
                   (evt.button == 4 && output.spfs(trials) < 2.5)
                correct = 1;
            else
                correct = 0;
           end
        end
        

        estcorrect(trials) = correct;
        condition(trials) = blocktype(block);
        
        
        % Trial Number Display
        Screen('DrawTexture',wptr,fixglind,[],destRect);
        Screen('TextSize', wptr, 18);
        Screen('TextFont', wptr, myfont);
        Screen('DrawText', wptr, sprintf('B%i',block), 10, yres-140, black);
        Screen('DrawText', wptr, sprintf('T%i',trials), 10, yres-120, black);
        Screen(wptr,'FillRect',black,pRect');
        Screen('Flip',wptr);
        pause(.5)
        if ~cut
            if trials == trialnum
                %Show ending screen for 1 second
                dispcorrect = estcorrect;
                dispcorrect(isnan(dispcorrect)) = 0;
                percorrect = sum(dispcorrect((trials-output.tperb+1):trials))/output.tperb;
                endtext = ['Done!  ',...
                    num2str(round(percorrect*100)),'% correct this block. Thank you for participating!'];
                Screen('DrawTexture',wptr,fixglind,[],destRect);
                Screen('TextSize', wptr, fontsize);
                Screen('TextFont', wptr, myfont);
                Screen('DrawText',wptr, endtext,(xres - length(endtext)*9)/2,yres*(5/12),black);
                Screen(wptr,'FillRect',black,pRect'); 
                %Pause for 1 second
                pause(1);
                Screen('Flip',wptr);
                %Pause for 1 second
                pause(1);
                %Wait for spacebar to end program
                FlushEvents('keyDown');
                [char,~] = GetChar; %Wait for keypress to continue
                notspace=1;
                while notspace
                    switch char
                        case advancechar
                            notspace =0;
                        otherwise
                            [char,~] = GetChar; %Wait for keypress to continue
                            notspace =1;
                    end
                end
            elseif trials/output.tperb == round(trials/output.tperb)
                 %Take a break every 'output.tperb' trials and show ending Screens
                dispcorrect = estcorrect;
                dispcorrect(isnan(dispcorrect)) = 0;
                percorrect = sum(dispcorrect((trials-output.tperb+1):trials))/output.tperb;
                trialtext = ['Block ',num2str(block),' complete!  ',...
                    num2str(round(percorrect*100)),'% correct this block. You may now take a break!'];
                
                block = block + 1;
    
                Screen('DrawTexture',wptr,fixglind,[],destRect);
                Screen('TextSize', wptr, fontsize);
                Screen('TextFont', wptr, myfont);
                trialtext2 = blockprompt{blocktype(block)};
                DrawFormattedText(wptr, [trialtext,'\n\n',trialtext2,'\n\n',trialtext3], 'center', 'center', black);
                if task == 3
                    if blocktype(block) == 3 || blocktype(block) == 6
                        Screen('DrawTexture',wptr,hard_lowtext,[],leftinstruct);
                        Screen('DrawTexture',wptr,hard_hightext,[],rightinstruct);
                    elseif blocktype(block) == 2 || blocktype(block) == 5
                        Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
                        Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
                    else 
                        Screen('DrawTexture',wptr,easy_lowtext,[],leftinstruct);
                        Screen('DrawTexture',wptr,easy_hightext,[],rightinstruct);
                    end
                elseif task == 1
                    if blocktype(block) == 2 || blocktype(block) == 5
                        Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
                        Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
                    elseif blocktype(block) == 3 || blocktype(block) == 6
                        Screen('DrawTexture',wptr,dim_bluetext,[],leftinstruct2);
                        Screen('DrawTexture',wptr,dim_yellowtext,[],rightinstruct2);
                    else
                    end
                else
                    Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
                    Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
                end

                Screen(wptr,'FillRect',black,pRect'); 
                %Pause for 1 second
                pause(1);
                Screen('Flip',wptr);
                
                %Wait for spacebar
                FlushEvents('keyDown');
                [char,~] = GetChar; %Wait for keypress to continue
                notspace=1;
                while notspace
                    switch char
                        case advancechar
                            notspace =0;

                            %Wait for subject to press the middle button
                            Screen('DrawTexture',wptr,fixglind,[],destRect);
                            Screen('TextSize', wptr, fontsize);
                            Screen('TextFont', wptr, myfont);
                            DrawFormattedText(wptr, [trialtext,'\n\n',trialtext2,'\n\n',trialtext4], 'center', 'center', black);
                            if task == 3
                                if blocktype(block) == 3 || blocktype(block) == 6
                                    Screen('DrawTexture',wptr,hard_lowtext,[],leftinstruct);
                                    Screen('DrawTexture',wptr,hard_hightext,[],rightinstruct);
                                elseif blocktype(block) == 2 || blocktype(block) == 5
                                    Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
                                    Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
                                else 
                                    Screen('DrawTexture',wptr,easy_lowtext,[],leftinstruct);
                                    Screen('DrawTexture',wptr,easy_hightext,[],rightinstruct);
                                end
                            elseif task == 1
                                if blocktype(block) == 2 || blocktype(block) == 5
                                    Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
                                    Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
                                elseif blocktype(block) == 3 || blocktype(block) == 6
                                    Screen('DrawTexture',wptr,dim_bluetext,[],leftinstruct2);
                                    Screen('DrawTexture',wptr,dim_yellowtext,[],rightinstruct2);
                                else
                                end
                            else
                                Screen('DrawTexture',wptr,med_lowtext,[],leftinstruct);
                                Screen('DrawTexture',wptr,med_hightext,[],rightinstruct);
                            end

                            Screen(wptr,'FillRect',black,pRect'); 
                            Screen('Flip',wptr);
                            
                            CedrusResponseBox('FlushEvents',chandle);
                            notmiddle = 1;
                            while notmiddle
                                evt = CedrusResponseBox('WaitButtonPress',chandle);
                                if evt.button == 5
                                    notmiddle = 0;
                                end
                            end
                            CedrusResponseBox('FlushEvents',chandle);

                            Screen('DrawTexture',wptr,fixglind,[],destRect);
                            Screen('TextSize', wptr, fontsize);
                            Screen('TextFont', wptr, myfont);
                            % Screen('DrawText',wptr,sprintf('Block %i of the experiment has started! Good luck!',block),(xres - length(sessiontext3))/2,yres*(5/12),black);
                            DrawFormattedText(wptr, [sprintf('Please keep your eyes fixated on the dot. Block %i has started! Good luck!',block),'\n\n'], 'center', 'center', black);
                            Screen(wptr,'FillRect',black,pRect'); 
                            Screen('Flip',wptr);
                            %Timer to calculate time between the last trial and the next
                            %Pause for 2 seconds
                            pause(2);
                            tic;
                        case escapechar %Escape from experiment and save current data (for experimenter)
                            notspace =0;
                            %RestoreScreen(whichScreen);
                            ShowCursor;
                            Screen('CloseAll');
                            output.ESC_time = clock;
                            output.estcorrect = estcorrect;
%                             output.speed_cutoff = speed_cutoff;
%                             output.given_feedback = given_feedback;
                            output.condition = condition;
                            %Organize data and time in a string
                            rightnow = clock;
                            rightnow = num2cell(rightnow)';
                            timestr = sprintf('_%i',rightnow{1:5});
                            eval([subnum,'_ExpSession',num2str(sesnum),'=output;']);
                            if ~strcmp(subnum,'SZZ_test')
                                if ~exist([pwd,'/pdmfinalbehav'],'dir')
                                    mkdir('pdmfinalbehav');
                                end
                                eval(['save(''pdmfinalbehav/',subnum,'_ses',num2str(sesnum),'_task',num2str(task),timestr,'.mat'',''-struct'', ''',subnum,'_ExpSession',num2str(sesnum),''');']);
                                if exist('pdmfinalbehav/macroinfo.mat','file')
                                    macroinfo = load('pdmfinalbehav/macroinfo.mat');
                                    subsesfield = sprintf('%s_ses%d_task%d',subnum,sesnum,task);
                                    macroinfo.(subsesfield) = output;
                                    save('pdmfinalbehav/macroinfo.mat','-struct','macroinfo');
                                end
                            end
                            warning on all;
                            CedrusResponseBox('Close',chandle);
                            return
                        otherwise
                            [char,when] = GetChar; %Wait for keypress to continue
                            notspace =1;
                    end
                end
                
                %Pause before beginning of the block, pause for a second after text
                Screen('DrawTexture',wptr,fixglind,[],destRect);
                Screen(wptr,'FillRect',black,pRect'); 
                Screen('Flip',wptr);
                pause(1);
            end
            
        end
      end  
  end
catch me
    
    fprintf('\n');
    %RestoreScreen(whichScreen);
    ShowCursor;
    Screen('CloseAll');
    output.error_time = clock;
    output.estcorrect = estcorrect;
%     output.speed_cutoff = speed_cutoff;
%     output.given_feedback = given_feedback;
    output.condition = condition;
    %Organize data and time in a string
    rightnow = clock;
    rightnow = num2cell(rightnow)';
    timestr = sprintf('_%i',rightnow{1:5});
    eval([subnum,'_ExpSession',num2str(sesnum),'=output;']);
    if ~strcmp(subnum,'SZZ_test')
        if ~exist([pwd,'/pdmfinalbehav'],'dir')
            mkdir('pdmfinalbehav');
        end
        eval(['save(''pdmfinalbehav/',subnum,'_ses',num2str(sesnum),'_task',num2str(task),timestr,'.mat'',''-struct'', ''',subnum,'_ExpSession',num2str(sesnum),''');']);
        if exist('pdmfinalbehav/macroinfo.mat','file')
            macroinfo = load('pdmfinalbehav/macroinfo.mat');
            subsesfield = sprintf('%s_ses%d_task%d',subnum,sesnum,task);
            macroinfo.(subsesfield) = output;
            save('pdmfinalbehav/macroinfo.mat','-struct','macroinfo');
        end
    end
    CedrusResponseBox('Close',chandle);
    %PsychPortAudio('Close', goodhand);
    %PsychPortAudio('Close', badhand);
    rethrow(me); %rethrow reproduces the original error, stored in the object 'me'
end

fprintf('\n');

%RestoreScreen(whichScreen);
ShowCursor;
Screen('CloseAll');

%Output time finished
output.finish_time = clock;

%Estimated accuracy
output.estcorrect = estcorrect;
% output.speed_cutoff = speed_cutoff;
% output.given_feedback = given_feedback;
output.condition = condition;

%Organize data and time in a string
rightnow = clock;
rightnow = num2cell(rightnow)';
timestr = sprintf('_%i',rightnow{1:5});
eval([subnum,'_ExpSession',num2str(sesnum),'=output;']);
if ~strcmp(subnum,'SZZ_test')
    if ~exist([pwd,'/pdmfinalbehav'],'dir')
        mkdir('pdmfinalbehav');
    end
    eval(['save(''pdmfinalbehav/',subnum,'_ses',num2str(sesnum),'_task',num2str(task),timestr,'.mat'',''-struct'', ''',subnum,'_ExpSession',num2str(sesnum),''');']);
    if exist('pdmfinalbehav/macroinfo.mat','file')
        macroinfo = load('pdmfinalbehav/macroinfo.mat');
        subsesfield = sprintf('%s_ses%d_task%d',subnum,sesnum);
        macroinfo.(subsesfield) = output;
        save('pdmfinalbehav/macroinfo.mat','-struct','macroinfo');
    end
end

warning on all;

CedrusResponseBox('Close',chandle);


%% ----------------------------------------------------------------------%%
function [noises, allgabors, allspfs, allrandrot] = genexp5(numnoise,noisespfrq,numgabor,gaborspfrq,radius,task,blocknum,blocktype,output)
%GENEXP% - generates images for pdmexp5
%
%Useage: 
%  >> genexp5(numnoise,noisespfrq,ngabor,gaborspfrq)
%
%Inputs:
%   numnoise - Number of noise images to generate
%
%   noisespfrq - Spatial frequency of pixelated visual noise (cycles per cm)
%
%   numgabor - Number of gabor images to pregenerate
%
%   gaborspfrq - Spatial frequencies of gabors (cycles per cm)
%
%   radius - Radius size of fixation spot (cycles per cm)

%% Code

%Gabor size
gaborsize = 10;

% if round(numgabor/length(gaborspfrq)) ~= numgabor/length(gaborspfrq)
%     error('Number of Gabor spatial frequencies must be a divisor of the number of Gabor images');
% end

if numnoise > 0
    fprintf('Building noise images...\n');
end
noises = nan(1000,1000,numnoise);
% for m=1:numnoise
%     noises(:,:,m) = makepixeled([],radius,noisespfrq,[]);
% end

%%Combine two spatial frequencies to equally mask both high and low signal
%%stimuli
for m=1:numnoise
%     temphn = makepixeled([],radius,3,[]);
%     templn = makepixeled([],radius,2,[]);
%     noises(:,:,m) = (temphn + templn)/2;
      noises(:,:,m) = makenoise([],2,10,radius,[2 3]);
end

%%Make Gabor images
if ~exist([pwd,'/pregen/gabor'],'dir')
    mkdir('pregen/gabor');
end

if task == 1 || task == 2
    if numgabor > 0
        fprintf('Building Gabor images...\n');
        gabors = nan(1000,1000,numgabor);
        spf = [ones(1,numgabor/2)*gaborspfrq(3) ones(1,numgabor/2)*gaborspfrq(4)];
        spf = spf(randperm(length(spf)));  
        randrot = nan(numgabor,1);
        for m = 1:length(spf)
            randrot(m) = (randi(2)-1)*90 - 45;
            gabors(:,:,m) = makegabor([],gaborsize,randrot(m),[],spf(m));
        end
        allgabors = gabors;
        allspfs = spf;
        allrandrot = randrot;
    end
else 
   if numgabor > 0
        fprintf('Building Gabor images...\n');
        gabors = nan(1000,1000,numgabor);
        %spf = nan(numgabors,1);
        spf = [];
        randrot = nan(numgabor,1);
%         randdraw = [ones(1,trialnum/2) ones(1,trialnum/2)*2];
%         randdraw(randperm(length(randdraw)));        
         for b=1:blocknum
            if blocktype(b) == 1 || blocktype(b) == 4
                randdraw = [ones(1,output.tperb/2)*gaborspfrq(1) ones(1,output.tperb/2)*gaborspfrq(2)];
                randdraw = randdraw(randperm(length(randdraw)));  
            elseif blocktype(b) == 2 || blocktype(b) == 5
                randdraw = [ones(1,output.tperb/2)*gaborspfrq(3) ones(1,output.tperb/2)*gaborspfrq(4)];
                randdraw = randdraw(randperm(length(randdraw)));     
            else 
                randdraw = [ones(1,output.tperb/2)*gaborspfrq(5) ones(1,output.tperb/2)*gaborspfrq(6)];
                randdraw = randdraw(randperm(length(randdraw))); 
            end
            spf = [spf randdraw];
         end
         for m = 1:length(spf)
            randrot(m) = (randi(2)-1)*90 - 45;
            gabors(:,:,m) = makegabor([],gaborsize,randrot(m),[],spf(m));
         end
        allgabors = gabors;
        allspfs = spf;
        allrandrot = randrot;
           
   end
    
end

timeels = toc;
fprintf('The images took %3.2f minutes to generate and save.\n',timeels/60);
