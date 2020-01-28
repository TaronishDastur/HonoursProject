import cv2
import numpy as np 
import glob


# ----------------------------------------------------#
# ----Calibrate the camera and save the parameters----#
# ----------------------------------------------------#


# function to calibrate the camera
def calibrateCamera (lr):
	criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
	chessboardSize = (7,7)
	objPoints = []
	imgPoints = []
	# objp = np.zeros((np.prod(chessboardSize),3),dtype=np.float32)
	# objp[:,:2] = np.mgrid[0:chessboardSize[0], 0:chessboardSize[1]].T.reshape(-1,2)
	objp = np.zeros((np.prod(chessboardSize),3),dtype=np.float32)
	objp[:,:2] = np.mgrid[0:chessboardSize[0], 0:chessboardSize[1]].T.reshape(-1,2)

	if (lr == "left"):
		images = glob.glob('Calibration/*L.jpg')
	if (lr == "right"):
		images = glob.glob('Calibration/*R.jpg')
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
	ret, K, dist, rvecs, tvecs = cv2.calibrateCamera(objPoints, imgPoints,greyImage.shape[::-1], None, None)
	#save parameters into numpy file so we dont have to repeat this over and over again
	if (lr == "left"):
		np.save("cameraParams/retL", ret)
		np.save("cameraParams/KL", K)
		np.save("cameraParams/distL", dist)
		np.save("cameraParams/rvecL", rvecs)
		np.save("cameraParams/tvecL", tvecs)
		np.save("cameraParams/focalLengthL", 4.25) #focal length in mm
		np.save("cameraParams/imgPointsL", imgPoints)
		np.save("cameraParams/objPointsL", objPoints)
	if (lr == "right"):
		np.save("cameraParams/retR", ret)
		np.save("cameraParams/KR", K)
		np.save("cameraParams/distR", dist)
		np.save("cameraParams/rvecR", rvecs)
		np.save("cameraParams/tvecR", tvecs)
		np.save("cameraParams/focalLengthR", 4.25) #focal length in mm
		np.save("cameraParams/imgPointsR", imgPoints)
		np.save("cameraParams/objPointsR", objPoints)


# calculate the error of calibration
def calibrationError(lr):
	# load the files
	if (lr == "left"):
		K = np.load("cameraParams/KL.npy")
		dist = np.load("cameraParams/distL.npy")
		rvec = np.load("cameraParams/rvecL.npy")
		tvec = np.load("cameraParams/tvecL.npy")
		imgPoints = np.load("cameraParams/imgPointsL.npy")
		objPoints = np.load("cameraParams/objPointsL.npy")
	if (lr == "right"):
		K = np.load("cameraParams/KR.npy")
		dist = np.load("cameraParams/distR.npy")
		rvec = np.load("cameraParams/rvecR.npy")
		tvec = np.load("cameraParams/tvecR.npy")
		imgPoints = np.load("cameraParams/imgPointsR.npy")
		objPoints = np.load("cameraParams/objPointsR.npy")

	total = 0
	for i in range (len(objPoints)):
		pp = cv2.projectPoints(objPoints[i], rvec[i], tvec[i], K, dist)
		total += cv2.norm(imgPoints[i],pp[0], cv2.NORM_L2)/len(pp[0])
			
	total = total/len(objPoints)
	print("Calibration error = ", total)


def calibrateMultipleCameras():
	KL = np.load('./cameraParams/KL.npy')
	imgPointsL = np.load("cameraParams/imgPointsL.npy")
	distCoefL = np.load('./cameraParams/distL.npy')
	objPointsL = np.load("cameraParams/objPointsL.npy")

	KR = np.load('./cameraParams/KR.npy')
	imgPointsR = np.load("cameraParams/imgPointsR.npy")
	distCoefR = np.load('./cameraParams/distR.npy')

	# CHANGE THIS VALUE IF CAMERA CHANGES
	(h,w) =(4032, 1960)
	criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
	
	#find rotation and translation between the two images
	(_, _, _, _, _, R, T, _, _) = cv2.stereoCalibrate(
		objPointsL, imgPointsL, imgPointsR, KL, distCoefL, KR, distCoefR, 
		(h,w), None, None, None, None,
        cv2.CALIB_FIX_INTRINSIC, criteria)


	# rectify
	(rectL, rectR, leftProj, rightProj, depthMap, leftROI, rightROI) = cv2.stereoRectify(
		KL, distCoefL, KR, distCoefR,
		(h,w), R, T, None, None, None, None, None,
		cv2.CALIB_ZERO_DISPARITY, 0.25)


	# find and save the left and right image values 
	lX, lY = cv2.initUndistortRectifyMap( KL, distCoefL, rectL,
        leftProj, (h,w), cv2.CV_32FC1)

	rX, rY = cv2.initUndistortRectifyMap( KR, distCoefR, rectR,
        rightProj, (h,w), cv2.CV_32FC1)

	np.save("cameraParams/Q", depthMap)


# main function
def main():
	print("Calibrate left camera")
	calibrateCamera("left")
	print("Calibrate right camera")	
	calibrateCamera("right")

	print("Calibration error left camera")
	calibrationError("left")
	print("Calibration error right camera")
	calibrationError("right")

	print("Find Q matrix")
	calibrateMultipleCameras()


# https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_calib3d/py_calibration/py_calibration.html#calibration
# https://docs.opencv.org/2.4/modules/highgui/doc/user_interface.html?highlight=waitkey
# https://docs.opencv.org
# https://becominghuman.ai/stereo-3d-reconstruction-with-opencv-using-an-iphone-camera-part-i-c013907d1ab5
# https://pysource.com/2018/07/19/check-if-two-images-are-equal-with-opencv-and-python/
