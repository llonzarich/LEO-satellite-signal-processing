This model will perform object detection for a single "object" in an image.

More specifically, this model uses simple bounding box regression to predict whether the object is in the image ("signal" or "no signal") and, if applicable, the bounding box x-,y-pixel coordinates of 1 object in an image.

The training data will include 1 bounding box on each spectrogram image.

Bounding boxes will be placed around the entire signal pattern that is "ours" on the spectrogram image (on for 5, off for 5, on for 5, off for 5,...).

No ImageNet classification pretraining. perhaps better results if we did this?