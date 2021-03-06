% for i=0:testInfo.getLength - 1
%     if strcmpi(testInfo.item(i).getNodeName, 'Cycle Time')
%         phoneNumber = testInfo.item(i).getTextContent
%     end
% end

% client = loadOmero();
% session = client.createSession(user, password);
% client.enableKeepAlive(60);
% images = getImages(session, ids);
% client.closeSession();

% Raw Data access
% 
% if( ~exist( 'fluor_img', 'var' ) )
%     fluor_img = imread( 'T:\Marino\Microscopy\170629\Fluor_405_170629_1100.tif' );
% end
% 
% 
% fluor_stack = img_2D_to_img_stack(fluor_img, [600 600] );
%  
% bw_stack = zeros( size( fluor_stack ) );
% cc = cell( size(fluor_stack, 3), 1 );
% 
% figure(1)
% for i = 1:size( fluor_stack, 3 )
%     [bw_stack(:,:,i), cc{i}, img_stats(i)] = threshold_fluor_img( fluor_stack(:,:,i), 1000 );
%     subplot(1,2,1), imshow(fluor_stack(:,:,i), []), subplot(1,2,2), imshow( bw_stack(:,:,i), [] )
% end
% 
% 
% figure(1)
% for i = 1:length( stats )
%    bb_center = [stats(i).BoundingBox(1) + stats(i).BoundingBox(3)/2,...
%                 stats(i).BoundingBox(2) + stats(i).BoundingBox(4)/2];
%             
%    subimg_topleft = [ min( [ max( [bb_center(1)-300, 1] ), size(dic_scan, 2 )-599 ] ) ,...
%                         min( [ max( [bb_center(2)-299, 1] ), size(dic_scan, 1)-599 ] ) ];
%    subimg = dic_scan( subimg_topleft(2):subimg_topleft(2)+599,...
%                         subimg_topleft(1):subimg_topleft(1)+599 );
%    imshow( subimg, [] ), title( sprintf('i = %i', i ) );
%    pause
% end
test_img = imread( 'T:\Marino\Microscopy\Raw Images for Michael\higher signal to noise\sample 3\Cell1 BFP 10%.tif');

filter_sizes = 0:1:100;
smoother_imgs = cell( length(filter_sizes), 1 );
img_var = zeros( length(filter_sizes), 1);
img_grad_mean = zeros( length(filter_sizes), 1);
img_ent = zeros( length(filter_sizes), 1);

for i = 1:length(filter_sizes)
    smoother_imgs{i} = imgaussfilt(test_img, i);
    img_var(i) = var( var( double(smoother_imgs{i} ) ) );
    [Gmag,Gdir] = imgradient( double(smoother_imgs{i} ));
    img_grad_mean(i) = mean( mean( Gmag ) );
    temp = double(smoother_imgs{i});
    temp = ( temp - min(min(temp)))/(max(max(temp)) - min(min(temp)));
    img_ent(i) = entropy( temp );
end


figure(1), plot( filter_sizes, img_var, 'b-' ), title('variance'), grid on
figure(2), plot( filter_sizes, img_grad_mean, 'b-' ), title('gradient'), grid on
figure(3), plot( filter_sizes, img_ent, 'b-' ), title('entropy'), grid on

