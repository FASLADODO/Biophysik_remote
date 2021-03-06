clearvars -except testIMG

% lab path
imgPATH = 'T:\Marino\Microscopy\161027 - DIC Toydata\160308\Sample3\DIC_160308_2033.tif';
% outPATH = 'T:\Marino\Microscopy\161027 - DIC Toydata\160308\Sample3\Processed\';

% home path
% imgPATH = 'D:\OS_Biophysik\DIC_images\DIC_160308_2033.tif';
% outPATH = 'D:\OS_Biophysik\Processed\';

if( ~exist( 'testIMG', 'var' ) )
    testIMG = imread(imgPATH);
end

% figure(1);imagesc(testIMG);colormap(gray)

wind_vec = 3:2:15;

dims = size(testIMG);

numCols = dims(2)/600;
numRows = dims(1)/600;
imgStack = uint16(zeros(600, 600, numCols*numRows));

bw_stack_cell = cell( 1, length(wind_vec) );

% segManager = classSegmentationManager;

% breaking up larger image
tempIDX = 0;
for i=1:numCols
    for j=1:numRows
        tempIDX = tempIDX + 1;
        imgStack( :,:, tempIDX ) =...
            uint16( testIMG( 600*(i-1)+1:600*i, 600*(j-1)+1:600*j ) );
    end
end
clear tempIDX
imgCount = size(imgStack, 3);
img_ent = zeros( size( imgStack ) );

wind_idx = 0;

detection_rate = zeros( 1, length( wind_vec ) );
false_rate = zeros( 1, length( wind_vec ) );
accuracy_rate = zeros( 1, length( wind_vec ) );
detected_cells = zeros( 1, length( wind_vec ) );
missed_cells = zeros( 1, length( wind_vec ) );
cell_detection_rate = zeros( 1, length( wind_vec ) );

scale_factor = 1/3;

imgStack = imresize( imgStack, scale_factor );

for wind = 3:2:15
    
    img_ent = zeros( 200, 200, size( imgCount, 3 ) );
    
    wind_idx = wind_idx + 1;
    
    tic
    
    for i = 1:imgCount
        im = imgStack(:,:,i);
        
        % Search for texture in the image
        img_ent(:,:,i) = entropyfilt(im, ones( wind,wind ));
    end
    
    img_ent = img_stack_to_img_2D( img_ent, [15 15] );
    
    se = strel('disk',9);
    ent_smooth = imclose(img_ent, se);
    % figure(3);imagesc(ent_smooth);colormap(gray)
    
    % this one uses gmm model *************************
    num_clusts = 2;
    % tic();
    skip_size = 30;
    ent_vector = ent_smooth(:);
    options = statset( 'MaxIter', 200 );
    gmm = fitgmdist(ent_vector(1:skip_size:end), num_clusts, 'replicates',3, 'Options', options);
    idx = reshape(cluster(gmm, ent_smooth(:)), size(ent_smooth));
    % toc();
    
    % Order the clustering so that the indices are from min to max cluster mean
    [~,sorted_idx] = sort(gmm.mu);
    temp = zeros(num_clusts,1);
    for j = 1:num_clusts
        temp(j) = find( sorted_idx == j );
    end
    sorted_idx = temp; clear temp
    % some weird bug is happening here but I think the above fixed it
    new_idx = sorted_idx(idx); %**********************
    
    % % this one uses otzu thresholding ******************************
    % new_idx = imquantize( img_ent, multithresh( img_ent, 2 ) );
    % % figure(4);imagesc(new_idx)
    
    % eliminate all objects below minimum size threshold, considering connected
    % pixels of class ( 2 || 3 ) as objects
    
    
    % eliminate all objects below minimum size threshold, considering connected
    % pixels of class ( 2 || 3 ) as objects
    
    bwInterior = (new_idx > 1);
    cc = bwconncomp(bwInterior);
    
    sizeThresh = 10000;
    bSmall = cellfun(@(x)(length(x) < sizeThresh), cc.PixelIdxList);
    
    new_idx(vertcat(cc.PixelIdxList{bSmall})) = 1;
    
    % figure(5);imagesc(new_idx)
    
    % without doing anything else, lets see how the segmentation is just using
    % the classes 2 and 3 as belonging to cells
    
    img_segged_bw = ( new_idx > 1 );
    
    tot_time = toc;
    
    img_segged = testIMG;
    img_segged( bwperim( ( new_idx > 1 ) ) == 1 ) = max(max(testIMG));
    
    img_segged_stack = img_2D_to_img_stack( img_segged, [200, 200] );
    img_bw_stack = img_2D_to_img_stack( ( new_idx > 1 ), [200, 200] );
    
    % figure(6), imshow( img_segged, [] )
    
    % for i = 1:size( img_segged_stack, 3 )
    %
    %     % figure(7); subplot(1,2,1), imagesc( img_segged_stack(:,:,i)); colormap(gray);
    %     subplot( 1,2,2 ), imagesc( img_bw_stack(:,:,i) ); colormap(gray);
    %     pause
    %
    % end
    
    ground_truth_file = 'T:\Marino\Microscopy\161027 - DIC Toydata\160308\Sample3\DIC_160308_2033_labels.mat';
    
    load( ground_truth_file );
    
    ignore_list = [13, 16, 22, 32, 37, 38, 42, 43, 45, 47, 52, 58, 70, 72,...
        73, 74, 87, 88, 92, 94, 96, 101, 102, 103, 105, 107, 109, 110, 111,...
        124, 125, 126, 134, 139, 140, 150, 152, 155, 161, 162, 165, 169, 170, 176,...
        177, 179, 185, 186, 187, 190, 200, 201, 205, 206, 209, 210, 212, 216,...
        217, 218, 223, 224, 225];
    
    for ii = 1:length( ROI_cell )
        temp_roi = ROI_cell{ii};
        for iii = 1:length(temp_roi)
            temp_roi(iii).Mask = imresize( temp_roi(iii).Mask, scale_factor );
        end
        ROI_cell{ii} = temp_roi;
    end
    
    
    
    [ ground_truth_img, cell_cnts, cell_pix_cnts] =...
        bw_stack_from_roi_cell(ROI_cell, [200 200], ignore_list );
    
    summary_stats = evaluate_seg_results( img_bw_stack, ground_truth_img, ROI_cell );
    
    summary_stats( ignore_list ) = [];
    
    detection_rate(wind_idx) = mean( [summary_stats.detection_rate] );
    false_rate(wind_idx) = mean( [summary_stats.false_positive_rate] );
    accuracy_rate(wind_idx) = mean( [summary_stats.accuracy ] );
    detected_cells(wind_idx) = sum( [summary_stats.detected_cells] );
    missed_cells(wind_idx) = sum( [summary_stats.missed_cells] );
    cell_detection_rate(wind_idx) = detected_cells(wind_idx) / ( missed_cells(wind_idx) + detected_cells(wind_idx) );
    tim(wind_idx) = toc;
    
    fprintf( 'completed wind=%i, accuracy=%.03f, cell_detection=%.03f, t=%i\n',...
        wind, accuracy_rate(wind_idx), cell_detection_rate(wind_idx), tim(wind_idx) );
    
    temp_idx = [16, 17, 20, 23, 24, 25, 27, 28];
    
    img_stack_classes = img_2D_to_img_stack( new_idx, [200 200] );
    img_stack_ent = img_2D_to_img_stack( img_ent, [200 200] );
    
    out_dir = 'T:\Marino\presentation_files\200x200\';
    
    bw_stack_cell{wind_idx} = img_bw_stack;
    
    for i = 1:length( temp_idx )
        
        file_str = sprintf( 'wind_%02i_image_idx_%i_scaled_0_33', wind, temp_idx(i) );
        
        temp_img = double( imgStack( :,:, temp_idx(i) ) );
        % temp_img = (temp_img - min(min(temp_img)))/(max(max(temp_img)) - min(min(temp_img)));
        
        
        
        temp_bw = img_bw_stack( :,:, temp_idx(i) );
        temp_ent = double( img_stack_ent( :, :, temp_idx(i) ) );
        
        sat = 0.05;
        lim = quantile(temp_ent,[sat,1-sat]);
        temp_ent = min(1,max(0,(temp_ent-lim(1))/(lim(2)-lim(1))));
        
        lim = quantile(temp_img,[sat,1-sat]);
        temp_img = min(1,max(0,(temp_img-lim(1))/(lim(2)-lim(1))));
        
        file_str_raw = strcat( out_dir, file_str, '_raw.tif' );
        file_str_ent = strcat( out_dir, file_str, '_ent.png' );
        file_str_bw = strcat( out_dir, file_str, '_ent_bw.png' );
        
        %     temp_ent = (temp_ent - min(min(temp_ent)));
        %     temp_ent = temp_ent/max(max(temp_ent));
        
        imwrite( temp_img, file_str_raw );
        imwrite( temp_ent, file_str_ent );
        imwrite( temp_bw, file_str_bw );
        
    end
    
end

detection_rate = detection_rate';
false_rate = false_rate';
accuracy_rate = accuracy_rate';
detected_cells = detected_cells';
missed_cells = missed_cells';
cell_detection_rate = cell_detection_rate';

save( 'entropy_param_var_results_resize.mat', 'accuracy_rate', 'detection_rate', 'false_rate',...
    'detected_cells', 'missed_cells', 'cell_detection_rate', 'bw_stack_cell' );









