close all;
clear all;
clc;

 num_class = 3;

 

%% Initialization
%Reading the data
path = 'C:\Users\Admin\Documents\Education\MAIA-Spain\Segmentation\Atlas\em\RegisteredImages\Intensities\';

folder = dir(path);
folder = folder(~ismember({folder.name},{'.','..'})); % Condition to discriminante files

% Declaration of variables
nVolumes = numel(folder);
num_classes = 4;             % 1=CSF || 2=White Matter || 3=Gray Matter || 4=Background
labeled_images = struct();   
intensity_images = struct();

%% Load labeled and intensity images    
dataset_merged = [];
for i=1:nVolumes 
    % Directories of the output from elastix
    current_intensity_path = [path 'result' num2str(i) '.nii' ]; % Correspond to the intensity registrated to the reference
%     current_labels_path = [path 'result' num2str(i) ];      % Correspond to the label registrated to the reference
    
    % Images
    intensity_image = load_untouch_nii( current_intensity_path );
%     label_image = load_untouch_nii( current_labels_path);
    
    % Save all the images in a single volume (will be 4D) 
    images_all(:, :, :, i) = double(intensity_image.img(:, :, :));
    intensity_image = double(intensity_image.img(:));
    temp = intensity_image(intensity_image > 0);
    dataset_merged = [dataset_merged(:); temp(:)];
    
%      labels_all(:, :, :, i) = label_image.img(:,:,:); 
end

 tic;
 
 image = dataset_merged;
 msize = numel(image);
 
 image = image(randperm(msize, round(msize/10000)));
 idx = kmeans(image(:), num_class);
 
 for i=1:num_class
    m(i) = mean(image(idx == i));
    s(i) = cov(image(idx == i));
 end
 [m sortidx] = sort(m);
 s = s(sortidx);
 
 image_linearized = image;
 h = image;
for i = 1:size(image_linearized, 1)
    for c = 1:num_class
        p(i,c) = exp(-0.5 * (image_linearized(i) - m(c))' * inv(s(c)) * (image_linearized(i) - m(c)))/(2*pi*sqrt(s(c)));
    end
    sump(i) = sum(p(i,:));
end
conv_likelihood(1) = sum(h .* log(sump'));

iter = 1;
while(1)
    iter = iter + 1;
     
     for j=1:num_class
        temp = h .* p(:,j)./sump';
        mem_weights(j) = sum(temp);
        m(j) = sum(h.*temp)/mem_weights(j);
     end
     
     for i = 1:size(image_linearized, 1)
        for c = 1:num_class
            p(i,c) = exp(-0.5 * (image_linearized(i) - m(c))' * inv(s(c)) * (image_linearized(i) - m(c)))/(2*pi*sqrt(s(c)));
        end 
        sump(i) = sum(p(i,:));
     end
     conv_likelihood(iter) = sum(h .* log(sump'));
    
     convergence_achieved = (conv_likelihood(iter) - conv_likelihood(iter - 1)) < 0.0001;
     if convergence_achieved
         disp(iter);
         break;
     end
end
toc
 %%

ref_directory = ['' 'C:\Users\Admin\Documents\Education\MAIA-Spain\Segmentation\Atlas\em\atlas.nii'];
ref = load_untouch_nii(ref_directory);
ref = ref.img;

refNii = make_nii(ref);
save_nii(refNii,'pipo.nii'); 
 
imagesRAW = images_all(:,:,:,5); 
mask = zeros(size(imagesRAW,1),size(imagesRAW,2));


for img_ind=1:size(imagesRAW,3)
    imageRAW = imagesRAW(:, :, img_ind);
    for i=1:size(imagesRAW,1)
       for j=1:size(imagesRAW,2)
          for n = 1:num_class
                point_p(n) = exp(-0.5 * (imageRAW(i,j) - m(n))' * inv(s(n)) * (imageRAW(i,j) - m(n)))/(2*pi*sqrt(s(n)));
          end
          if(imageRAW(i,j) == 0)
             mask(i,j) = 0;
          else
              
              a = find(point_p == max(point_p));
              mask(i,j) = a(1);
          end
       end
    end

    figure; imshow(mask,[]);
    title('Segmentation result');


end
execution_time = toc;