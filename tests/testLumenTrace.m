function tests = testLumenTrace
% Deterministic smoke tests and synthetic copy-move metric example.
tests=functiontests(localfunctions);
end
function testAnalysisAndTransforms(t)
A=uint8(repmat(uint8(linspace(30,80,128)),96,1)); s=lumen.analyzeImage(A); verifyEqual(t,s.width,128); verifyEqual(t,s.height,96); verifyGreaterThan(t,s.entropy,0);
e=lumen.enhanceImage(A); verifyEqual(t,numel(e.names),5); verifyTrue(t,isfield(e.images,e.recommendation)); verifyEqual(t,numel(e.metrics),5); verifyTrue(t,all([e.metrics.score]>=0 & [e.metrics.score]<=1)); verifyGreaterThanOrEqual(t,e.metrics(1).distributionSimilarity,0); verifyLessThanOrEqual(t,e.metrics(1).distributionSimilarity,1);
end
function testImageFileFormats(t)
A=uint8(repmat(linspace(0,255,48),32,1)); exts={'.png','.jpg','.tif','.bmp'};
for i=1:numel(exts)
 path=[tempname exts{i}]; cleanup=onCleanup(@() deleteIfPresent(path)); %#ok<NASGU>
 imwrite(A,path); loaded=imread(path); s=lumen.analyzeImage(loaded); verifyEqual(t,s.width,48); verifyEqual(t,s.height,32);
end
end
function deleteIfPresent(path)
if exist(path,'file'), delete(path); end
end
function testTypesAndNoise(t)
rng(4); samples={uint8(randi(255,80,100)),uint8(255*rand(80,100,3)),uint8(min(max(128+25*randn(80,100),0),255))};
for i=1:numel(samples), s=lumen.analyzeImage(samples{i}); verifyEqual(t,s.width,100); f=lumen.detectForensics(samples{i}); verifyTrue(t,isfield(f.maps,'noiseInconsistency')); ev=lumen.evidenceMap(samples{i},f); verifyEqual(t,size(ev.mask),size(s.gray)); if ~isempty(ev.contributors), verifyEqual(t,sum(cell2mat(struct2cell(ev.contributions))),100,'AbsTol',1e-8); end, end
end
function testSyntheticCopyMoveMetrics(t)
% A copied textured patch is planted at a known location; scores are measured, not asserted as detector success.
rng(9); A=rand(128); A(81:112,81:112)=A(17:48,17:48); truth=false(size(A)); truth(81:112,81:112)=true;
f=lumen.detectForensics(A); pred=f.maps.copyMove>0.5; TP=sum(pred(:)&truth(:)); FP=sum(pred(:)&~truth(:)); FN=sum(~pred(:)&truth(:)); precision=TP/(TP+FP+eps); recall=TP/(TP+FN+eps); F1=2*precision*recall/(precision+recall+eps); iou=TP/(TP+FP+FN+eps);
verifyGreaterThanOrEqual(t,[precision recall F1 iou],[0 0 0 0]); fprintf('Synthetic copy-move P=%.3f R=%.3f F1=%.3f IoU=%.3f\n',precision,recall,F1,iou);
end
function testControlledDemoCopyMoveMetrics(t)
% Report real detector scores against the supplied pasted-destination mask;
% deliberately do not assert that the heuristic achieves a target accuracy.
root=fileparts(fileparts(mfilename('fullpath')));
im=imread(fullfile(root,'demo_inputs','demo_copy_move_controlled.png'));
truth=imread(fullfile(root,'demo_inputs','demo_copy_move_ground_truth.png'))>0;
f=lumen.detectForensics(im); pred=f.maps.copyMove>0.5;
verifyEqual(t,size(pred),size(truth));
TP=sum(pred(:)&truth(:)); FP=sum(pred(:)&~truth(:)); FN=sum(~pred(:)&truth(:));
precision=TP/(TP+FP+eps); recall=TP/(TP+FN+eps);
F1=2*precision*recall/(precision+recall+eps); iou=TP/(TP+FP+FN+eps);
verifyTrue(t,all(isfinite([precision recall F1 iou])));
fprintf('Controlled demo copy-move (destination only): P=%.3f R=%.3f F1=%.3f IoU=%.3f\n',precision,recall,F1,iou);
end



