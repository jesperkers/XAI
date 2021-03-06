% test_compute_relevance_tri_sq_rot.m - computing the relevance of all test images from the T&S dataset

% this script uses LRP Toolbox v.1.2.0

%% parameters
config_params_tri_sq;

verbose = true;
step = 1;

%arch = input('Chose architecture (1 = lenet5_maxpool, 2 = short_relu): ');
%arch = 1;
arch = 2;

method = 3; % alpha-beta rule

%% data loading
% load MAT files with data
load(test_images_full_fname);
num_test_images = size(test_images,1);
load(test_labels_full_fname);
if verbose
    disp(['Loaded ', num2str(num_test_images) ,' test images and labels']);
end

%% initialize relevance matrix and prediction labels
rel_matrix = zeros(num_test_images, im_dim(1)*im_dim(2));
pred_test_labels = zeros(num_test_images,1);
%% normalize & reshape the data and labels
[norm_test_images] = normalize_input4lenet(test_images, im_dim, num_channels, reshape_order);
norm_test_images = reshape(norm_test_images, [size(norm_test_images,1), im_dim(1) * im_dim(2)]);
if verbose
    disp(['Normaised ', num2str(num_test_images) ,' test images']);
end
[test_labels] = reshape_labels(test_labels);
if verbose
    disp(['Reshaped ', num2str(num_test_images) ,' test labels']);
end

%% load the model
switch arch
    case 1
        net = model_io.read(lenet5_maxpool_full_model_fname);
    case 2
        net = model_io.read(short_relu_full_model_fname);        
end
if verbose
    disp('Loading the pre-trained model...');
end


%% compute and the relevance maps for each test image
for s = 1:length(shape_labels)
    selected_class = shape_labels(s);
    switch s
        case 1
            select_label = 'square';
        case 2
            select_label = 'triangle';
    end
    if save_relevance
        relevance_fullfname = fullfile(path2experiments,...
            [relevance_fname_base '_selected_' select_label '.mat']);
    end
    select = (1:size(test_labels,2) == s)*1.;
    
    for index = 1:num_test_images
        if verbose
            if (mod(index,100)== 0)
                disp(['Computing relevance of image ' num2str(index) ...
                    ' out of ' num2str(num_test_images) ' for selected class ' select_label ]);
            end
        end
        test_image = norm_test_images(index,:,:,:);
        or_image = test_images(index,:,:,:);
        
        [comp_hm, R, pred, gray_diff] = compute_lrp_heatmap(or_image, test_image, im_dim, ...
            net, method, select, shape_labels);
        %            switch pred
        %                case 1
        %                    pred_class = 'square';
        %                case 2
        %                    pred_class = 'triangle';
        %            end
        rel_matrix(index,:) = R(:)';
        pred_test_labels(index) = pred;
    end
    if save_relevance
        save(relevance_fullfname, "rel_matrix");
        save(predictions_fullfname, "pred_test_labels")
    end
end

