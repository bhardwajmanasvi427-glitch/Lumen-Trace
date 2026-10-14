function s = analyzeImage(im)
% Basic intensity statistics; RGB is analyzed after luminance conversion.
if ~(isnumeric(im)||islogical(im)) || isempty(im), error('Input must be a nonempty numeric image.'); end
x=im2double(im); if ndims(x)==3 && size(x,3)>=3, g=0.298936*x(:,:,1)+0.587043*x(:,:,2)+0.114021*x(:,:,3); else, g=x(:,:,1); end
g=min(max(g,0),1); edges=linspace(0,1,257); counts=histcounts(g(:),edges); p=counts/sum(counts); p=p(p>0);
s=struct('width',size(im,2),'height',size(im,1),'channels',size(im,3),'mean',mean(g(:)),'std',std(g(:)),'contrast',percentile(g(:),99)-percentile(g(:),1),'entropy',-sum(p.*log2(p)),'histogram',counts,'gray',g);
end

function y=percentile(x,p)
x=sort(x(:)); q=1+(numel(x)-1)*p/100; a=floor(q); b=ceil(q); y=x(1); if a==b, y=x(a); else, y=x(a)+(q-a)*(x(b)-x(a)); end
end

