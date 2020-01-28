import cv2
import numpy as np 
import glob
from matplotlib import pyplot as plt 
import open3d as o3d
import numpy as np
import copy

# ----------------------------------------------------#
# ------------------Create 3D Map---------------------#
# ----------------------------------------------------#
MAX_IMG = 1
outputFileName = 'merged.ply'

#Load camera parameters

ret = np.load('./cameraParams/ret.npy')
K = np.load('./cameraParams/K.npy')
dist = np.load('./cameraParams/dist.npy')
f = np.load('./cameraParams/focalLength.npy')
R = np.load("cameraParams/rvec.npy")
T = np.load("cameraParams/tvec.npy")

'''
K1 = np.array([3979.911, 0, 1244.772],[0, 3979.911, 1019.507],[0, 0, 1]) 
K2 = np.array([3979.911, 0, 1369.115], [0, 3979.911, 1019.507], [0, 0, 1])
doffs=124.343 	#distance of sx and sy points 
baseline=193.001
w=2964
h=2000
disp=270  #disparity
isint=0
vmin=23
vmax=245
dyavg=0
dymax=0
'''

h, w = 0, 0 

# helper function to show an image in opencv 
def showImg(name, image):
	cv2.namedWindow(name , cv2.WINDOW_NORMAL)
	cv2.imshow(name, image)
	cv2.waitKey(0) 
	cv2.destroyAllWindows()


# function to get the disparity matrix 
def disparityMatrix(img1, img2, filename):
	h,w = img1.shape[:2]
	newCameraMatrix, roi = cv2.getOptimalNewCameraMatrix(K,dist,(w,h),1,(w,h))

	#Undistort images
	# note: for using the newCamMatrix replace K with newCameraMatrix in the two lines
	img1U = cv2.undistort(img1, K, dist, None, newCameraMatrix)
	img2U = cv2.undistort(img2, K, dist, None, newCameraMatrix)

	
	dispMap, blockSize, numDisp =  controlParams(img1U, img2U)
	map(img1U, img2U, dispMap, blockSize, numDisp , filename)



# run the sgbm algorithm with the required parameters 
def runSgbm(img1U, img2U, blockSize, numDisp):
	#values from https://jayrambhia.com/blog/disparity-mpas
	sgbm = cv2.StereoSGBM_create(
	    minDisparity = numDisp,
	    numDisparities = numDisp*16,
	    blockSize = blockSize,
	    uniquenessRatio = 10,
	    speckleWindowSize = 100,
	    speckleRange = 1,
	    disp12MaxDiff = 5,
	    P1 = 8*3*blockSize**2,
	    P2 = 32*3*blockSize**2,
		)

	disp = sgbm.compute(img1U, img2U).astype(np.float32)
	return disp


# run the sbm algorithm with the required parameters 
def runSbm(img1U, img2U, blockSize, numDisp):
	sbm = cv2.createStereoBM(numDisparities=numDisp, blockSize=blockSize)
	return sbm.compute(img1U, img2U)


# blank function for create trackbar 
def nothing(x):
	pass


# function to create trackbar with an image 
# takes a list of names (also gets number of trackbars) and the image to be placed
def controlParams (img1, img2):
	print("run sgbm")
	cv2.namedWindow("disparityMap", cv2.WINDOW_NORMAL)
	cv2.createTrackbar("blockSize", "disparityMap" ,1,10, nothing)
	cv2.createTrackbar("numDisp", "disparityMap" ,1,20, nothing)

	ret = img1
	while (1):
		cv2.imshow("disparityMap", ret)
		k = cv2.waitKey(1)
		if (k == 27):
			cv2.destroyAllWindows
			break
		if (k == 32):
			blockSize = cv2.getTrackbarPos("blockSize", "disparityMap")
			numDisp = cv2.getTrackbarPos("numDisp", "disparityMap")
			ret = runSgbm(img1, img2, blockSize, numDisp)

	threshold = cv2.threshold(ret, 0.6, 1.0, cv2.THRESH_BINARY)[1]
	ret = cv2.morphologyEx(threshold, cv2.MORPH_OPEN, np.ones((12,12),np.uint8))

	plt.imshow(ret,'gray')
	plt.show()

	return ret, blockSize, numDisp


# generate the 3d matrix from sgbm
def map(img1, img2, disp, blockSize, numDisp, outputFileName):

	print("get 3d map")
	h,w = img1.shape[:2]
	Q = np.float32(
	[[1,0,0,0],
    [0,-1,0,0],
    [0,0,f*0.05,0],
    [0,0,0,1]])
	
	
	points3D = cv2.reprojectImageTo3D(disp, Q)
	# points3D = cv2.perspectiveTransform(disp)

	
	cv2.imshow("disparityMap", points3D)
	colors = cv2.cvtColor(img1, cv2.COLOR_BGR2RGB)
	print(points3D)
	maskMap = disp > disp.min()
	
	outputPoints = points3D[maskMap]
	outputColors = colors[maskMap]

	
	print ("creating the output file")
	writePly(outputPoints, outputColors, outputFileName)

# Function to create point cloud file
def writePly(vertices, colors, filename):
	colors = colors.reshape(-1,3)
	# vertices = np.hstack([vertices.reshape(-1,3),colors])
	vertices = np.hstack([vertices, colors])

	ply_header = '''ply
	format ascii 1.0
	element vertex %(vert_num)d
	property float x
	property float y
	property float z
	property uchar red
	property uchar green
	property uchar blue
	end_header
	'''


	with open(filename, 'w') as f:
		f.write(ply_header %dict(vert_num=len(vertices)))
		np.savetxt(f,vertices,'%f %f %f %d %d %d')




# ----------------------------------------------------#
# --------------------Main code-----------------------#
# ----------------------------------------------------#

def main():
	#Load pictures
	for i in range (1, 1+MAX_IMG):
		img1 = cv2.imread('images/plant/%dl.png' % i)
		img2 = cv2.imread('images/plant/%dr.png' % i )
		outputFileName = 'output' + str(i) + '.ply'
		disparityMatrix(img1, img2, outputFileName)
	

main()

# https://becominghuman.ai/stereo-3d-reconstruction-with-opencv-using-an-iphone-camera-part-i-c013907d1ab5

