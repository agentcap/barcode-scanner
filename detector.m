function out = detector(img)
    %% Locally Adaptive Thresholding
    bw = imbinarize(img ,'adaptive','ForegroundPolarity','dark')==0;
    figure
    subplot(2,2,1)
    imshow(bw);

    %% Filtering By Eccentricity
    subplot(2,2,2)
    prop = regionprops(bw,'Eccentricity');
    ecc = -sort(-cat(1,prop.Eccentricity));
    e_range = min(60,size(ecc,1));
    bw_e = bwpropfilt(bw,'Eccentricity',[ecc(e_range) ecc(1)]);
    imshow(bw_e);
    
    %% Filtering By Major Axis Length
    subplot(2,2,3)
    prop = regionprops(bw_e,'MajorAxisLength');
    axis_length = cat(1,prop.MajorAxisLength);
    h = histogram(axis_length,50);
    [~,idx] = max(h.BinCounts);
    l_range = 20;                            % Make this dyanaminc
    range = h.BinEdges([max(1,idx-l_range-1),min(idx+l_range+1,size(h.BinEdges,2))]);
    bw_l = bwpropfilt(bw_e,'MajorAxisLength',range);
    imshow(bw_l);

    %% Filtering By Orientation
    subplot(2,2,4)
    prop = regionprops(bw_l,'Orientation');
    axis_length = cat(1,prop.Orientation);
    h = histogram(axis_length,[-90:0,1:90]);
    [~,idx] = max(h.BinCounts);
    o_range = 20;
    range = h.BinEdges([max(1,idx-o_range-1),min(idx+o_range+1,size(h.BinEdges,2))]);
    bw_o = bwpropfilt(bw_l,'Orientation',range);

    if( idx-o_range-1 < 1)
        range = h.BinEdges([mod(idx-o_range-1,size(h.BinEdges,2))+1,size(h.BinEdges,2)]);
        bw_o = logical(bw_o + bwpropfilt(bw_l,'Orientation',range));
    elseif( idx+o_range+1 > size(h.BinEdges,2))
        range = h.BinEdges([1,mod(idx+o_range+1,size(h.BinEdges,2))+1]);
        bw_o = logical(bw_o + bwpropfilt(bw_l,'Orientation',range));
    end
    imshow(bw_o);

    out = 1 - bw_o; %return value
end