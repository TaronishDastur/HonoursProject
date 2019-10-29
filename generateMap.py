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
MAX_IMG = 3
outputFileName = ''

#Load camera parameters
ret = np.load('./cameraParams/ret.npy')
K = np.load('./cameraParams/K.npy')
dist = np.load('./cameraParams/dist.npy')

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

	# downscale images
	# img1U = cv2.pyrDown(img1U) 
	# img2U = cv2.pyrDown(img2U)

	# showImg("img1U", img1U)
	# showImg("img2U", img2U)

	dispMap, blockSize, numDisp =  controlParams(img1U, img2U)
	# stereo = cv2.StereoBM_create(16, 15)
	# disparity = stereo.compute(img1U,img2U)
	# plt.imshow(disparity,'gray')
	# plt.show()


	map(img1U, img2U, dispMap, blockSize, numDisp , filename)


# run the sgbm algorithm with the required parameters 
def runSgbm(img1U, img2U, blockSize, numDisp):
	#values from https://jayrambhia.com/blog/disparity-mpas
	sgbm = cv2.StereoSGBM_create(
		blockSize = blockSize, #5
		numDisparities = numDisp*16, #192
		preFilterCap = 4,
		minDisparity = -64,
		uniquenessRatio = 1,
		speckleWindowSize = 150,
		speckleRange = 2,
		disp12MaxDiff = 10,
		P1 = 600,
		P2 = 2400
		)
	return sgbm.compute(img1U, img2U)


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
		# plt.imshow(ret,'gray')
		# plt.show()
		cv2.imshow("disparityMap", ret)
		k = cv2.waitKey(1)
		if (k == 27):
			cv2.destroyAllWindows
			break
		if (k == 32):
			blockSize = cv2.getTrackbarPos("blockSize", "disparityMap")
			numDisp = cv2.getTrackbarPos("numDisp", "disparityMap")
			ret = runSgbm(img1, img2, blockSize, numDisp)
	return ret, blockSize, numDisp


# generate the 3d matrix from sgbm
def map(img1, img2, disp, blockSize, numDisp, outputFileName):
	print("get 3d map")
	h,w = img1.shape[:2]
	focalLength = np.load('./cameraParams/focalLength.npy')
	Q = np.float32(
	[[1,0,0,0],
    [0,-1,0,0],
    [0,0,focalLength*0.05,0],
    [0,0,0,1]])

	points3D = cv2.reprojectImageTo3D(disp, Q)
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
	vertices = np.hstack([vertices.reshape(-1,3),colors])

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
		img1 = cv2.imread('./chair/%da.jpg' % i)
		img2 = cv2.imread('./chair/%db.jpg' % i )
		outputFileName = 'output' + str(i) + '.ply'
		disparityMatrix(img1, img2, outputFileName)
	

main()

# https://becominghuman.ai/stereo-3d-reconstruction-with-opencv-using-an-iphone-camera-part-i-c013907d1ab5

