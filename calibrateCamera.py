import cv2
import numpy as np 
import glob


# ----------------------------------------------------#
# ----Calibrate the camera and save the parameters----#
# ----------------------------------------------------#




# function to calibrate the camera
def calibrateCamera ():
	criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
	chessboardSize = (7,6)
	objPoints = []
	imgPoints = []
	# objp = np.zeros((np.prod(chessboardSize),3),dtype=np.float32)
	# objp[:,:2] = np.mgrid[0:chessboardSize[0], 0:chessboardSize[1]].T.reshape(-1,2)
	objp = np.zeros((np.prod(chessboardSize),3),dtype=np.float32)
	objp[:,:2] = np.mgrid[0:chessboardSize[0], 0:chessboardSize[1]].T.reshape(-1,2)

	images = glob.glob('photos/*.jpg')
	# for i in range (1,70):
	for imgPath in images:
		# imgPath = "photos/"
		# imgPath += str(i) + ".jpg"
		image = cv2.imread(imgPath)
		greyImage = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
		ret,corners = cv2.findChessboardCorners(greyImage, chessboardSize, None)

		if (ret == True):
			corners2 = cv2.cornerSubPix(greyImage, corners, (11, 11), (-1,-1), criteria)
			objPoints.append(objp)
			imgPoints.append(corners2)
			# img = cv2.drawChessboardCorners(image, (7,6), corners2,ret)
			# cv2.namedWindow("name" , cv2.WINDOW_NORMAL)
			# cv2.imshow("name", img)
			# cv2.waitKey(0)


	
	# cv2.destroyAllWindows()
	ret, K, dist, rvecs, tvecs = cv2.calibrateCamera(objPoints, imgPoints,greyImage.shape[::-1], None, None)


	#save parameters into numpy file so we dont have to repeat this over and over again
	np.save("cameraParams/ret", ret)
	np.save("cameraParams/K", K)
	np.save("cameraParams/dist", dist)
	np.save("cameraParams/rvec", rvecs)
	np.save("cameraParams/tvec", tvecs)
	np.save("cameraParams/focalLength", 4.25) #focal length in mm
	np.save("cameraParams/imgPoints", imgPoints)
	np.save("cameraParams/objPoints", objPoints)




# calculate the error of calibration
def calibrationError():
	# load the files
	K = np.load("cameraParams/K.npy")
	dist = np.load("cameraParams/dist.npy")
	rvec = np.load("cameraParams/rvec.npy")
	tvec = np.load("cameraParams/tvec.npy")
	imgPoints = np.load("cameraParams/imgPoints.npy")
	objPoints = np.load("cameraParams/objPoints.npy")
	total = 0
	for i in range (len(objPoints)):
		pp = cv2.projectPoints(objPoints[i], rvec[i], tvec[i], K, dist)
		total += cv2.norm(imgPoints[i],pp[0], cv2.NORM_L2)/len(pp[0])
			
	total = total/len(objPoints)
	print("Calibration error = ", total)



# calibrateCamera()
calibrationError()


# https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_calib3d/py_calibration/py_calibration.html#calibration
# https://docs.opencv.org/2.4/modules/highgui/doc/user_interface.html?highlight=waitkey
# https://docs.opencv.org
# https://becominghuman.ai/stereo-3d-reconstruction-with-opencv-using-an-iphone-camera-part-i-c013907d1ab5
# https://pysource.com/2018/07/19/check-if-two-images-are-equal-with-opencv-and-python/
