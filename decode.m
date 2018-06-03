function out = decode(img)
    I = img;
    if(size(img,3) == 3)
        img = rgb2gray(img);
    end
    img = detector(img);
    
    %% Crop the image to desired size
    [~,b] = sort(-sum((1-img')));
    sel = round(mean(b(1:50)));

    %% Take band aroung 'sel' and convert it to scan line
    range = 10;
    band = img(sel-range:sel+range,:);
    inp =round(sum(band)./(2*range));

    %% Finding the run length encoding of the scanned line
    idx = find(diff([inp(1)-1, inp]));
    barCode = [inp(idx); diff([idx,numel(inp)+1])];
    barCode(1,:) = (barCode(1,:) ~= 1); % Fliping 0's and `'s

    %% Find the 1 0 1 pattern in the barcode(Update)
    len = size(barCode,2);
    s_idx = 1;
    for i = 1:len-2
       if isequal(barCode(1,[i,i+1,i+2]),[1,0,1])
           s_idx = i+3;
           break;
       end
    end

    %% Compute the map
    % map => mapping of the digit encoding
    %     => [left_odd,left_even, right,relation_to_digit_1]
    map = [0:9;
        "0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011";
        "0100111", "0110011", "0011011", "0100001", "0011101", "0111001", "0000101", "0010001", "0001001", "0010111";
        "1110010", "1100110", "1101100", "1000010", "1011100" ,"1001110", "1010000", "1000100", "1001000", "1110100";
        "OOOOOOEEEEEE", "OOEOEEEEEEEE", "OOEEOEEEEEEE", "OOEEEOEEEEEE", "OEOOEEEEEEEE", "OEEOOEEEEEEE", "OEEEOOEEEEEE", "OEOEOEEEEEEE", "OEOEEOEEEEEE", "OEEOEOEEEEEE";];
    left = [3 2 1 1; 2 2 2 1; 2 1 2 2; 1 4 1 1;1 1 3 2;1 2 3 1; 1 1 1 4; 1 3 1 2; 1 2 1 3; 3 1 1 2; 1 1 2 3; 1 2 2 2; 2 2 1 2; 1 1 4 1; 2 3 1 1; 1 3 2 1; 4 1 1 1; 2 1 3 1;3 1 2 1; 2 1 1 3];
    left_p = ['O','O','O','O','O','O','O','O','O','O','E','E','E','E','E','E','E','E','E','E'];
    left_m = [0:9, 0:9];
    right = [3 2 1 1; 2 2 2 1; 2 1 2 2; 1 4 1 1;1 1 3 2;1 2 3 1; 1 1 1 4; 1 3 1 2; 1 2 1 3; 3 1 1 2;];
    right_m = 0:9;

    %% Ensure reading from left to right 
    first = barCode(:,s_idx:s_idx+6*4-1);
    width = zeros(1,size(first(1,:),2));
    for i = 1:4:size(first(1,:),2)
        tmp = [i,i+1,i+2,i+3];
        x = sum(first(2,tmp))/7;
        width(tmp) = x;
    end
    first(2,:) = first(2,:)./width;
    second = barCode(:,s_idx+6*4+5:s_idx+2*6*4+5-1);
    for i = 1:4:size(first(1,:),2)
        tmp = [i,i+1,i+2,i+3];
        x = sum(second(2,tmp))/7;
        width(tmp) = x;
    end
    second(2,:) = second(2,:)./width;

    str = "";
    str = strcat(str,repmat(int2str(first(1,1)),1,round(first(2,1))));
    str = strcat(str,repmat(int2str(first(1,2)),1,round(first(2,2))));
    str = strcat(str,repmat(int2str(first(1,3)),1,round(first(2,3))));
    str = strcat(str,repmat(int2str(first(1,4)),1,round(first(2,4))));
    
    % The first digit from the left group is always encoded with odd parity
    if isempty(map(2,ismember(map(2,:),str)))
       temp = first;
       first = second(:,size(second,2):-1:1);
       second = temp(:,size(temp,2):-1:1);
    end

    code = [first,second]; % Bar code in the right order


    out = ""; % Decoded Text
    par = ""; % Holds the parity of each digit

    %% Find the digits using Map
    for i=1:4:size(code,2)
        str = "";
        str = strcat(str,repmat(int2str(code(1,i)),1,round(code(2,i))));
        str = strcat(str,repmat(int2str(code(1,i+1)),1,round(code(2,i+1))));
        str = strcat(str,repmat(int2str(code(1,i+2)),1,round(code(2,i+2))));
        str = strcat(str,repmat(int2str(code(1,i+3)),1,round(code(2,i+3))));
        

        if ~isempty(map(1,ismember(map(2,:),str)))
            out = strcat(out,map(1,ismember(map(2,:),str)));
            par = strcat(par,"O");
        elseif ~isempty(map(1,ismember(map(3,:),str)))
            out = strcat(out,map(1,ismember(map(3,:),str)));
            par = strcat(par,"E");
        elseif ~isempty(map(1,ismember(map(4,:),str)))
            out = strcat(out,map(1,ismember(map(4,:),str)));
            par = strcat(par,"E");
        else
            if code(1,i) == 0
                idx = knnsearch(left,code(2,[i,i+1,i+2,i+3]));
                out = strcat(out,int2str(left_m(idx)));
                par = strcat(par,left_p(idx));
            else
                idx = knnsearch(right,code(2,[i,i+1,i+2,i+3]));
                out = strcat(out,int2str(right_m(idx)));
                par = strcat(par,'E');
            end
        end
    end

    %% Find the first digit using the Parity
    out = strcat(map(1,ismember(map(5,:),par)),out);

    %% Check Party-bit

    figure
    subplot(1,1,1)
    imshow(I)
    title(out)
end
