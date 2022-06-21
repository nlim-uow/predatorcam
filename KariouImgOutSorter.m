warning('off', 'MATLAB:MKDIR:DirectoryExists');
files1=dir('d:/WS080/**/*.AVI');
files2=dir('d:/WS080/**/*.MOV');
files=cat(1,files1,files2);
fileCount=size(files,1)
imCount=100000;

for i = 1:fileCount
try    
    file=files(i);
    temp=split(file.folder,'\');
    folder="e:/matlabout/"+join(temp(2:end,1),'/');
    filename=file.folder+"/"+file.name
    [a,b,c]=fileparts(file.name);
    mkdir(folder);
    outFile=folder+"/"+b+"_box"+c;
    matFiles=dir(file.folder+"/"+b+"*.mat");
    if (size(matFiles,1)>0)
       matFile=matFiles(1);
       gTruthData=load(matFile.folder+"/"+matFile.name);
       gTruthLoaded=1;
    else
       gTruthLoaded=0;
    end
    if gTruthLoaded==0
        continue
    end
    videoSource = VideoReader(filename);
    detector = vision.ForegroundDetector(...
'NumTrainingFrames', 5, ...
'InitialVariance', 20*20);
blob = vision.BlobAnalysis(...
'CentroidOutputPort', false, 'AreaOutputPort', false, ...
'BoundingBoxOutputPort', true, ...
'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 49);
shapeInserter = vision.ShapeInserter('BorderColor','White');
%videoPlayer = vision.VideoPlayer();

%v = VideoWriter(outFile,'Motion JPEG AVI');
%v.FrameRate=20
%v.Quality = 95;
%open(v)
clear('mask1');
clear('mask4');
frameNo=0;
while hasFrame(videoSource)
frameNo=frameNo+1;
frame  = readFrame(videoSource);
vMax=size(frame,1);
hMax=size(frame,2);
fgMask = detector(frame);
bbox   = blob(fgMask);
if exist('mask1','var')==0
    mask1 = zeros(size(fgMask));
    mask4 = zeros(size(fgMask));
end
for box = bbox'
    yMin=max(box(2)-50,1);
    yMax=min(box(2)+box(4)+50,vMax);
    xMin=max(box(1)-50,1);
    xMax=min(box(1)+box(3)+50,hMax);
    mask1(yMin:yMax,xMin:xMax)=mask1(yMin:yMax,xMin:xMax)+1;
end
mask4=mask4+fgMask;
BW=bwareafilt(mask1>0.001,[15000 inf]);
num_prop=numel(regionprops(BW));
BW2=bwareafilt(mask4>0.01,[15000 inf]);
num_prop2=numel(regionprops(BW2));

for m=1:num_prop
    BW3=bwareafilt(BW,m);
    BW3=bwareafilt(BW3,1,'smallest');
    okInd=find(BW3>0);
    if size(okInd,1)>1
        [ii,jj]=ind2sub(size(BW3),okInd);
        yMin=min(ii);
        xMin=min(jj);
        yMax=max(ii);
        xMax=max(jj);
        h1=yMax-yMin+1;
        w1=xMax-xMin+1;
        imcropped=imcrop(frame,[xMin,yMin,w1,h1]);
        im=imresize(imcropped,[224 224]);
        imCount=imCount+1;
        imwritten=0;
        fileOut=imCount+".png";
        if gTruthLoaded==1
            critters=gTruthData.gTruth.LabelData.Properties.VariableNames;
            noCritters=size(critters,2);
            outFolder='e:/matlabout/img2/';
            for j=1:noCritters
                if(strcmp(critters{j},'Rat'))
                    outFolder='e:/matlabout/img2/rat';
                elseif(strcmp(critters{j},'Cat'))
                    outFolder='e:/matlabout/img2/cat';
                elseif(strcmp(critters{j},'Possum'))
                    outFolder='e:/matlabout/img2/possum';
                elseif(strcmp(critters{j},'Stoat'))
                    outFolder='e:/matlabout/img2/stoat';
                elseif(strcmp(critters{j},'Rabbit'))
                    outFolder='e:/matlabout/img2/rabbit';
                elseif(strcmp(critters{j},'Bird'))
                    outFolder='e:/matlabout/img2/bird';
                elseif(strcmp(critters{j},'Leaf'))
                    outFolder='e:/matlabout/img2/empty';
                end
                bboxData=table2array(gTruthData.gTruth.LabelData(frameNo,j));
                if(size(bboxData{1},2)==4)
                    for k=1:size(bboxData{1},1)
                        x2=bboxData{1}(k,1);
                        y2=bboxData{1}(k,2);
                        w2=bboxData{1}(k,3);
                        h2=bboxData{1}(k,4);
                        iou=iouCalc(xMin,yMin,w1,h1,x2,y2,w2,h2);
                        if(iou>0.05)
                           imwrite(im,outFolder+"/"+fileOut);
                           imwritten=1;
                        end
                    end
                end
            end
        end
        if imwritten==0
           outFolder='e:/matlabout/img2/';
           imwrite(im,outFolder+"/"+fileOut);
        end

    end
end
mask2=cat(3,BW,BW,BW);
mask3=cat(3,BW2,BW2,BW2);
out    = frame.*uint8(mask2);
out2    = frame.*uint8(mask3);
%writeVideo(v,out);
%videoPlayer(out);
%pause(0.00);
mask1=mask1./2;
mask4=mask4./2;
end
%close(v)
catch
end
end