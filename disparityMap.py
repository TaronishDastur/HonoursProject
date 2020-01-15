import cv2
import numpy as np 
from matplotlib import pyplot as plt 
import open3d as o3d
import os

# required variables
MAX_IMG = 3



# helper function to show an image in opencv 
def showImg(image, name="img"):
	cv2.namedWindow(name , cv2.WINDOW_NORMAL)
	cv2.imshow(name, image)
	cv2.waitKey(0) 
	cv2.destroyAllWindows()


# ----------------------------------------------------#
# ----------------Disparity Map-----------------------#
# ----------------------------------------------------#

# function to get the disparity map 
def disparityMap(img1, img2, output):
	print("disparity map")
	'''
	h,w = img1.shape[:2]
	K = np.load('./cameraParams/K.npy')
	distCoef = np.load('./cameraParams/dist.npy') #distortion coeffients 
	newCameraMatrix, _ = cv2.getOptimalNewCameraMatrix(K,distCoef,(w,h), 1)

	# Undistort images
	# # note: for using the newCamMatrix replace the last value with new CamMatrix or K
	img1 = cv2.undistort(img1, K, distCoef, None, newCameraMatrix)
	img2 = cv2.undistort(img2, K, distCoef, None, newCameraMatrix)

	# crop the width and height 
	img1 = img1[150:h-150, 100:w-100]
	img2 = img2[150:h-150, 100:w-100]
	'''

	# showImg(img1)
	# showImg(img2)


	# modify img1 and 2 based on the camera calibration calculated 
	# img1 = cv2.remap(img1, lX, lY, cv2.INTER_LINEAR)
	# img2 = cv2.remap(img2, rX, rY, cv2.INTER_LINEAR)

	# run the sgmb function with the gui
	img1G = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
	img2G = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)

	# showImg(img1G)
	# showImg(img2G)

	disp = controlParams(img1G, img2G)
	map(img1, disp, output)


# run the sgbm algorithm with the required parameters 
def runSgbm(img1U, img2U, blockSize, numDisp):
	#values from https://jayrambhia.com/blog/disparity-mpas
	sgbm = cv2.StereoSGBM_create(
		blockSize = blockSize, #5
		numDisparities = numDisp*16, #192
		preFilterCap = 4,
		minDisparity = numDisp-20,
		uniquenessRatio = 10,
		speckleWindowSize = 150,
		speckleRange = 2,
		disp12MaxDiff = 7,
		P1 = 8*blockSize**2,
		P2 = 32*blockSize**2
		)
	depth = sgbm.compute(img1U, img2U).astype(np.float32)
	right= cv2.ximgproc.createRightMatcher(sgbm)
	return depth, sgbm, right


# blank function for create trackbar 
def nothing(x):
	pass


# function to create trackbar with an image 
# takes a list of names (also gets number of trackbars) and the image to be placed
def controlParams (img1, img2):
	print("run sgbm")
	cv2.namedWindow("disparityMap", cv2.WINDOW_NORMAL)
	cv2.createTrackbar("blockSize", "disparityMap" ,1,20, nothing)
	cv2.createTrackbar("numDisp", "disparityMap" ,1,30, nothing)

	depth = img1
	while (1):
		depth = cv2.normalize(depth, None, alpha = 0, beta = 1, norm_type=cv2.NORM_MINMAX, dtype=cv2.CV_32F)
		cv2.imshow("disparityMap", depth)
		k = cv2.waitKey(1)
		if (k == 27):
			cv2.destroyAllWindows
			break
		if (k == 32):
			blockSize = cv2.getTrackbarPos("blockSize", "disparityMap")
			numDisp = cv2.getTrackbarPos("numDisp", "disparityMap")
			depth, left, right = runSgbm(img1, img2, blockSize, numDisp)

	# filteredDepth = cv2.bilateralFilter(ret,10,150,150)
	# plt.imshow(depth,'gray')
	# plt.show()
	# depth = filterDepthMap(left, right, img1, img2)
	return depth


#calculate distance using the disparity map, focal length and baseline distance between the stereo camera
def calculateDistance(img1, disp, f, b):
	points3D = []
	for x in range(len(disp)):
		for y in range(len(disp[x])):
			if (disp[x][y] == 0):
				z = 0
			else:
				z = f*b/disp[x][y]
			xx = x*z/f
			yy = y*z/f
			if (len(points3D) == 0):
				points3D = [[xx,yy,z, img1[x][y][2], img1[x][y][1], img1[x][y][0]]]
			else:
				points3D.append([xx,yy,z, img1[x][y][2], img1[x][y][1], img1[x][y][0]])
			# print(len(points3D)) 
			# os.system('cls' if os.name == 'nt' else 'clear')
	return np.array(points3D)

# ----------------------------------------------------#
# ------------------Point cloud-----------------------#
# ----------------------------------------------------#

def map(img1, disp, outputFileName):
	print("get 3d map")
	f = np.load('./cameraParams/focalLength.npy')
	h,w = img1.shape[:2]
	# f = (f / 5.76) *w    #convert to pixels
	f = 3740
	baseline = 160

	# Q = np.float32(
	# [[1,0,0,0],
 #    [0,-1,0,0],
 #    [0,0,f*0.05,0],
 #    [0,0,0,1]])

	# Q = np.load('./cameraParams/Q.npy')
	# Q = np.float32([[1,0,0,-w/2.0],
	# 	[0,-1,0,h/2.0],
	# 	[0,0,0,-f],
	# 	[0,0,1,0]])
	
	# print(disp.shape)
	# print(h, w)

	points3D = calculateDistance(img1, disp, f, baseline)

	'''
	points3D = cv2.reprojectImageTo3D(disp, Q)

	
	
	print(points3D.shape)
	# cv2.imshow("disparityMap", points3D)

	
	colors = cv2.cvtColor(img1, cv2.COLOR_BGR2RGB)
	maskMap = disp > disp.min()
	
	
	outputPoints = points3D[maskMap]
	
	outputColors = colors[maskMap]
	'''
	outputPoints = points3D
	print ("creating the output file")

	writePly(outputPoints, outputFileName)

# Function to create point cloud file
def writePly(vertices, filename):
	# colors = colors.reshape(-1,3)
	# vertices = np.hstack([vertices.reshape(-1,3),colors])
	# vertices = np.hstack([vertices, colors])

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


def showPly(name):
	pcd = o3d.io.read_point_cloud(name)
	o3d.visualization.draw_geometries([pcd])

# ----------------------------------------------------#
# --------------------Main code-----------------------#
# ----------------------------------------------------#

def main():
	#Load pictures
	for i in range (1, 1+MAX_IMG):
		# plant, room
		img1 = cv2.imread('./game/%dR.png' % i)
		img2 = cv2.imread('./game/%dL.png' % i)
		outputFileName = 'game_output' + str(i) + '.ply'
		disparityMap(img1, img2, outputFileName)
		# showPly("output.ply")
	

main()



