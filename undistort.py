import cv2 
import numpy as np
import glob
from tempfile import TemporaryFile
# from tqdm import tqdm
# import PIL.ExifTags
# import PIL.Image



# undistort the image using the lens parameters calculated
def undistort():
	img = cv2.imread("boxes/1a.jpg", 1)
	showImg("og", img)
	K = np.load("cameraParams/K.npy")
	dist = np.load("cameraParams/dist.npy")
	h,w = img.shape[:2]
	newCameraMatrix, roi = cv2.getOptimalNewCameraMatrix(K,dist,(w,h),1,(w,h))
	ret = cv2.undistort(img, newCameraMatrix, dist)
	showImg("img", ret)

# helper function to show an image in opencv 
def showImg(name, image):
	cv2.namedWindow(name , cv2.WINDOW_NORMAL)
	cv2.imshow(name, image)
	cv2.waitKey(0) 
	cv2.destroyAllWindows()



undistort()
