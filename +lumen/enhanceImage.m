function out = enhanceImage(im,gammaValue)
% Apply point/global transforms and compare with simple explainable indicators.
if nargin<2, gammaValue=0.65; end
s=lumen.analyzeImage(im); g=s.gray;
names={'negative','logarithmic','gamma','contrastStretch','histogramEqualization'}; imgs=struct();
imgs.negative=1-g; imgs.logarithmic=log1p(9*g)/log(10); imgs.gamma=g.^gammaValue;
lo=percentile(g(:),1); hi=percentile(g(:),99); imgs.contrastStretch=min(max((g-lo)/max(hi-lo,eps),0),1);
counts=histcounts(g(:),0:1/256:1); cdf=cumsum(counts)/numel(g); idx=min(floor(g*256)+1,256); imgs.histogramEqualization=reshape(cdf(idx),size(g));
base=metrics(g,g); rows=repmat(struct('contrast',0,'entropy',0,'edgeEnergy',0,'distributionSimilarity',0,'clippingFraction',0,'score',0),1,numel(names)); scores=zeros(1,numel(names));
for i=1:numel(names)
 x=imgs.(names{i}); m=metrics(x,g);
 contrastScore=min(m.contrast/max(base.contrast,0.05),2)/2;
 detailScore=min(m.edgeEnergy/max(base.edgeEnergy,1e-5),2)/2;
 score=0.30*contrastScore+0.25*m.entropy/8+0.25*detailScore+0.10*m.distributionSimilarity+0.10*(1-m.clippingFraction);
 rows(i)=m; rows(i).score=score; scores(i)=score;
end
[~,k]=max(scores); out=struct('images',imgs,'names',{names},'scores',scores,'metrics',rows,'recommendation',names{k}, ...
 'reason',sprintf('Highest combined score: contrast 30%%, entropy 25%%, edge energy 25%%, histogram similarity 10%%, clipping avoidance 10%%. Gamma=%.3g.',gammaValue), ...
 'baseline',base);
end
function m=metrics(x,reference)
x=min(max(x,0),1); edges=linspace(0,1,257); h=histcounts(x(:),edges); p=h/sum(h); p=p+eps; p=p/sum(p); hr=histcounts(reference(:),edges); q=hr/sum(hr); q=q+eps; q=q/sum(q); mid=(p+q)/2;
js=0.5*sum(p.*log2(p./mid))+0.5*sum(q.*log2(q./mid));
gx=diff(x,1,2); gy=diff(x,1,1); energy=sqrt((sum(gx(:).^2)+sum(gy(:).^2))/(numel(gx)+numel(gy)+eps));
clip=mean(x(:)<=0.002 | x(:)>=0.998);
m=struct('contrast',percentile(x(:),99)-percentile(x(:),1),'entropy',-sum(p.*log2(p)),'edgeEnergy',energy,'distributionSimilarity',max(0,1-js),'clippingFraction',clip,'score',0);
end
function y=percentile(x,p)
x=sort(x(:)); q=1+(numel(x)-1)*p/100; a=floor(q); b=ceil(q); y=x(1); if a==b, y=x(a); else, y=x(a)+(q-a)*(x(b)-x(a)); end
end
