This model will perform object detection for multiple "objects" in an image.

Bounding boxes will be place around the strong yellow-colored regions on the spectrogram image (these regions correlate to the signal being "on").


________________________________________________________________
        YOLO specifics
----------------------------------------------------------------
We will leverage YOLO to predict the bounding box x-,y-pixel coordinates of multiple objects in an image and visualize.
- specifically, we are using yolov5 and the yolov5s model (fast, decent accuracy)


The YOLO algorithm annotates each bounding box with 5 descriptors: 
(1) value corresponding to object class (signal=0)
(2) center of bounding box
(3) width
(4) height


Training the model using yolov5s model:
(1) navigate to the yolov5s directory
(2) run 'python train.py ...' with the following arguments:
    - '--img': defines the input image size
    - '--batch': determine the batch size 
    - '--epochs': specify the total number of training epochs. (1 epoch=1 full pass over entire training set)
    - '--data': path to your dataset.yaml file
    - '--weights': path to the initial weights file. Use pretrained weights. For fast convergence and superior results. Only train from scratch if you have a very very large dataset.
    - '--name': the name of the output folder.
(2.5) mine: 'python train.py --img 640 --batch 16 --epochs 100 --data ../dataset.yaml --weights yolov5s.pt --name spectrogram-yolo' 
(3) training outputs is created with the following stuff
    - weights/best.pt: your best model
    - results.png: training loss/accuracy graphs
    opt.yaml: the training settings used
    training_batch*.npg: visual logs of training batches
(3.5) mine: output directory 'spectrogram-yolo' is created


Visualizing the training process:
- option 1: comet logging and visualization
            (1) pip install comet_ml # install Comet library
            (2) export COMET_API_KEY=YOUR_API_KEY_HERE # set your Comet API key (create a free account on Comet.ml)
            (3) python train.py --img 640 --epochs 3... # train your model. Comet automatically logs everything!
- option 2: local logging
            (1) training results are automatically logged using TensorBoard and saved as csv files within the specific experiment directory.


After training the model:
- YOLOv5 will create results in 'bbox_ml_model_YOLO/yolov5/runs/train/spectrogram-yolo/
- the output directory contains training logs, loss curves, and the best performing model weights (best.pt)
- the trained model is ready to be deployed with testing data or further refined. 


Running interference (detecting objects on new images, aka test images)
(1) run 'python detect.py ..' with the following arguments:
    - '--weights': path to your trained model
    - '--source': path to your test image or folder of test images
    - '--conf': confidence threshold for showing detections 
(1.5) mine: 'python detect.py --weights runs/train/spectrogram-yolo/weights/best.pt --source /Users/lydialonzarich/Desktop/CMU_REUSE/leo-signal-proc/bbox_ml_model_YOLO/yolo-data/images/test --conf 0.25'
(2) bounding boxes will be predicted on all .png image files in the 'yolo-data/images/test' directory
(3) output results are created in 'yolov5/runs/detect/exp/' directory with the the annotated images


Evaluating model performance (evaluating on validation set again) (optional)
(1) used to compare predictions against actual annotations
(2) run 'python val.py ...' with the following arguments:
     - '--weights': path to your trained model (i'll use runs/train/spectrogram-yolo/weights/best.pt)
    - '--data': path to test images (i'll use 'dataset.yaml')
    - '--task': (i'll use 'test')


