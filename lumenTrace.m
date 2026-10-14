function lumenTrace
% LUMEN TRACE: image enhancement and exploratory forensic analysis.
fig = uifigure('Name','LUMEN TRACE — Hidden Detail Recovery & Image Forensics','Position',[80 80 1180 760]);
root = fileparts(mfilename('fullpath')); addpath(root);
state = struct('original',[],'analysis',[],'enhancements',[],'forensics',[],'evidence',[],'filename','');
layout = uigridlayout(fig,[3 4]); layout.RowHeight = {42,'1x',175}; layout.ColumnWidth = {'1x','1x','1x','1x'};
bar = uigridlayout(layout,[1 8]); bar.Layout.Row=1; bar.Layout.Column=[1 4]; bar.ColumnWidth={105,55,70,85,125,100,115,'1x'};
uibutton(bar,'Text','Open image…','ButtonPushedFcn',@openImage);
uilabel(bar,'Text','Gamma'); gammaField=uieditfield(bar,'numeric','Value',0.65,'Limits',[0.05 5]);
uibutton(bar,'Text','Enhance / compare','ButtonPushedFcn',@enhance);
uibutton(bar,'Text','Analyze forensics','ButtonPushedFcn',@forensic);
uibutton(bar,'Text','Evidence Map','ButtonPushedFcn',@evidence);
uibutton(bar,'Text','Export results…','ButtonPushedFcn',@exportResults);
status = uilabel(bar,'Text','Open an image to begin.');
titles={'Original','Recommended enhancement','Forensic evidence map','Input intensity histogram'}; ax=gobjects(4,1);
for k=1:4
 p=uipanel(layout,'Title',titles{k}); p.Layout.Row=2; p.Layout.Column=k; ax(k)=uiaxes(p,'Position',[10 10 250 460]); ax(k).XTick=[]; ax(k).YTick=[];
end
info=uitextarea(layout,'Editable','off'); info.Layout.Row=3; info.Layout.Column=[1 4]; info.Value={'LUMEN TRACE ready. Results are exploratory indicators, not proof of image tampering.'};
 function openImage(~,~)
  [f,p]=uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp','Image files'}); if isequal(f,0), return; end
  try, im=imread(fullfile(p,f)); state.original=im; state.filename=f; state.analysis=lumen.analyzeImage(im); state.enhancements=[]; state.forensics=[]; state.evidence=[];
   imshow(im,[],'Parent',ax(1)); cla(ax(2)); cla(ax(3)); cla(ax(4)); hold(ax(4),'on'); plot(ax(4),linspace(0,1,256),state.analysis.histogram,'k'); hold(ax(4),'off'); title(ax(4),'Input intensity histogram');
   s=state.analysis; info.Value={sprintf('%s | %d×%d | %d channel(s)',f,s.width,s.height,s.channels),sprintf('Intensity mean %.4g; std %.4g; contrast P1–P99 %.4g; entropy %.4g bits',s.mean,s.std,s.contrast,s.entropy),'Image Processing Toolbox is required for GUI display and forensic processing.','Use Enhance / compare to inspect all five outputs and metric scores.'}; status.Text='Image loaded; original retained unchanged.';
  catch e, uialert(fig,e.message,'Could not open image'); end
 end
 function enhance(~,~)
  if isempty(state.original), noImage(); return; end
  state.enhancements=lumen.enhanceImage(state.original,gammaField.Value); r=state.enhancements.recommendation;
  imshow(state.enhancements.images.(r),[],'Parent',ax(2)); title(ax(2),r,'Interpreter','none'); showComparison(state.enhancements);
  names=state.enhancements.names; metricLines=cell(numel(names),1);
  for ii=1:numel(names), m=state.enhancements.metrics(ii); metricLines{ii}=sprintf('%s: score %.3f | contrast %.3f | entropy %.2f | edge %.4g | hist sim %.3f | clipped %.1f%%',names{ii},m.score,m.contrast,m.entropy,m.edgeEnergy,m.distributionSimilarity,100*m.clippingFraction); end
  info.Value=[info.Value(1:min(3,numel(info.Value)));{['Recommendation: ' r];state.enhancements.reason};metricLines]; status.Text=['Recommended: ' r ' (comparison window opened)'];
 end
 function showComparison(enh)
  cf=uifigure('Name','LUMEN TRACE — Enhancement comparison','Position',[120 90 1200 720]); gl=uigridlayout(cf,[2 3]); gl.RowHeight={'1x','1x'}; gl.ColumnWidth={'1x','1x','1x'};
  for kk=1:numel(enh.names)
   nm=enh.names{kk}; m=enh.metrics(kk); pp=uipanel(gl,'Title',sprintf('%s | score %.3f',nm,m.score)); pp.Layout.Row=ceil(kk/3); pp.Layout.Column=mod(kk-1,3)+1;
   aa=uiaxes(pp,'Position',[5 5 360 270]); imshow(enh.images.(nm),[],'Parent',aa); aa.XTick=[]; aa.YTick=[];
  end
  pp=uipanel(gl,'Title','Score criteria and weights'); pp.Layout.Row=2; pp.Layout.Column=3; uitextarea(pp,'Position',[8 8 370 275],'Editable','off','Value',{'Contrast gain: 30%','Entropy: 25%','Edge energy (detail proxy): 25%','Histogram similarity to input: 10%','Clipping avoidance: 10%','These are measurable proxies, not a guarantee of perceptual quality.'});
 end
 function forensic(~,~)
  if isempty(state.original), noImage(); return; end
  state.forensics=lumen.detectForensics(state.original); status.Text='Forensic indicators calculated.';
  names=fieldnames(state.forensics.maps); lines={'Exploratory detector outputs (bright pixels indicate higher response):'};
  for i=1:numel(names), d=state.forensics.detectors.(names{i}); lines{end+1}=sprintf('%s: %s',names{i},d.message); end
  info.Value=[info.Value(1:min(3,numel(info.Value)));lines(:)];
 end
 function evidence(~,~)
  if isempty(state.original), noImage(); return; end
  if isempty(state.forensics), forensic([],[]); end
  state.evidence=lumen.evidenceMap(state.original,state.forensics); imshow(state.evidence.overlay,[],'Parent',ax(3)); title(ax(3),'Combined evidence (heuristic)');
  if any(state.evidence.mask(:)), details={'Per-detector share within candidate pixels:'}; else, details={'No candidate pixels were thresholded; detector shares use whole-frame response:'}; end
  for ii=1:numel(state.evidence.contributors), nm=state.evidence.contributors{ii}; details{end+1}=sprintf('%s: %.1f%%',nm,state.evidence.contributions.(nm)); end
  info.Value=[info.Value(1:min(3,numel(info.Value)));{sprintf('Evidence Map: %d spatial detector maps; candidate area %.2f%%.',numel(state.evidence.contributors),100*mean(state.evidence.mask(:)))};details(:);{'Contribution shares describe this fusion only; they are not calibrated likelihoods.';'A heatmap is an investigative aid, not probability, proof, or attribution.'}]; status.Text='Evidence map created.';
 end
 function exportResults(~,~)
  if isempty(state.original), noImage(); return; end
  [f,p]=uiputfile('lumen_trace_results.mat','Save analysis'); if isequal(f,0), return; end
  results=state; save(fullfile(p,f),'results'); [~,stem]=fileparts(f);
  if ~isempty(state.evidence), imwrite(state.evidence.overlay,fullfile(p,[stem '_overlay.png'])); end
  writeReport(fullfile(p,[stem '_report.txt']),results); status.Text='MAT data, available overlay, and text report exported.';
 end
 function writeReport(path,r)
  fid=fopen(path,'w'); if fid<0, uialert(fig,'Could not create the text report.','Export warning'); return; end
  c=onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid,'LUMEN TRACE — Exploratory image analysis report\n'); fprintf(fid,'Input: %s\n',r.filename);
  a=r.analysis; fprintf(fid,'Dimensions: %d x %d, %d channel(s)\nMean: %.6f\nStd: %.6f\nP1-P99 contrast: %.6f\nEntropy: %.4f bits\n',a.width,a.height,a.channels,a.mean,a.std,a.contrast,a.entropy);
  if ~isempty(r.enhancements)
   e=r.enhancements; fprintf(fid,'\nEnhancement recommendation: %s\n%s\n',e.recommendation,e.reason);
   for jj=1:numel(e.names), m=e.metrics(jj); fprintf(fid,'%s: score %.4f; contrast %.5f; entropy %.4f; edge energy %.6g; histogram similarity %.4f; clipped %.2f%%\n',e.names{jj},m.score,m.contrast,m.entropy,m.edgeEnergy,m.distributionSimilarity,100*m.clippingFraction); end
  end
  if ~isempty(r.forensics)
   fprintf(fid,'\nForensic detector observations and limitations:\n'); ns=fieldnames(r.forensics.detectors);
   for jj=1:numel(ns), d=r.forensics.detectors.(ns{jj}); fprintf(fid,'%s: %s\n',ns{jj},d.message); end
  end
  if ~isempty(r.evidence)
   if r.evidence.hasCandidates, fprintf(fid,'\nEvidence map candidate area: %.2f%%\nDetector contribution shares within candidates (relative fusion shares):\n',100*mean(r.evidence.mask(:))); else, fprintf(fid,'\nEvidence map candidate area: 0.00%%\nDetector contribution shares use whole-frame response because no candidates were thresholded:\n'); end
   for jj=1:numel(r.evidence.contributors), nm=r.evidence.contributors{jj}; fprintf(fid,'%s: %.2f%%\n',nm,r.evidence.contributions.(nm)); end
  end
  fprintf(fid,'\nCaution: these heuristic outputs are not calibrated probabilities or proof of manipulation. Natural texture, processing, and scene content can trigger them. Human review and independent validation are required.\n');
 end
 function noImage(), uialert(fig,'Open an image first.','No image'); end
end


