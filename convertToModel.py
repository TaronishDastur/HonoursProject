import open3d as o3d
import numpy as np
import math
from scipy.spatial import KDTree

# ----------------------------------------------------#
# ---Modify the point cloud for Cube representation---#
# ----------------------------------------------------#


readFileName = "PointClouds/game1.ply"
saveFileName = "QbiQ/test.txt"

# load the point cloud file and convert it to np array
ply = o3d.io.read_point_cloud(readFileName)
xyzList = np.asarray(ply.points)
print(xyzList.shape)

print('Read point cloud and reduce size')
# for i,e in enumerate(xyzList):
for i in range(len(xyzList)):
	e = xyzList[i]
	# plant --> 200000
	# box --> 10000
	e = np.absolute(np.rint(e / 10000))
	# print(e)
	xyzList[i] = e 

xyzList = np.unique(xyzList, axis=0)
print(xyzList.shape)


# Transpose the list so the x,y,z planes are in individual rows
xyzListT = np.transpose(xyzList)
xList = xyzListT[0]
yList = xyzListT[1]
zList = xyzListT[2]

# Find maximum x, y, z values
xDict = {}
yDict = {}
zDict = {}

for e in xyzList:
	if e[0] in xDict: 
		xDict[e[0]] += 1
	else:
		xDict[e[0]] = 1

	if e[1] in yDict: 
		yDict[e[1]] += 1
	else:
		yDict[e[1]] = 1

	if e[2] in zDict: 
		zDict[e[2]] += 1
	else:
		zDict[e[2]] = 1		

maxAtX = list(xDict.keys())[list(xDict.values()).index(max(xDict.values()))]
maxAtY = list(yDict.keys())[list(yDict.values()).index(max(yDict.values()))]
maxAtZ = list(zDict.keys())[list(zDict.values()).index(max(zDict.values()))]


	
# remove elements at where the floor is i.e. max y count --> remove elements in the x,y plane
# Note: Modify as needed by the Model to remove maximum possible points 
reducedList = []
for e in xyzList:
	if (e[2] > maxAtZ ):
		reducedList.append(e)

	if (reducedList[-1][1] < maxAtY +5  ):
		reducedList.pop(-1)


reducedList = np.array(reducedList)
print(reducedList.shape)

# convert the modified vectors to a point cloud 
ply.points = o3d.utility.Vector3dVector(reducedList)

# remove the outliers around a radius 
ply = ply.voxel_down_sample(voxel_size=3)
o3d.visualization.draw_geometries([ply])

uni_down_ply = ply.uniform_down_sample(every_k_points=5)
cl, ind = ply.remove_statistical_outlier(nb_neighbors=20,
                                                    std_ratio=0.5)
o3d.visualization.draw_geometries([cl])

# convert the point cloud back to vector 
reducedList = np.asarray(cl.points)


# bring the axis to the ground and center model
newListT = np.transpose(reducedList)
minX = int(min(newListT[0]))
minY = int(min(newListT[1]))
minZ = int(min(newListT[2]))

for i, x in enumerate(reducedList):
	reducedList[i][1] -= minY
	reducedList[i][0] -= minX
	reducedList[i][2] -= minZ


# find the 10 closest points to each point and create a path to it
# for e in reducedList:
newList = []
for i,p1 in enumerate(reducedList):
# for i in range (2):
	# p1 = reducedList[i]
	kdtree=KDTree(reducedList)
	dist,points=kdtree.query(p1, 10)
	for p in range (9):
		p2 = reducedList[points[p+1]]
		x, y, z = p1

		# loop though the list and find the nearest neighbours in each direction
		for x in range(int(p1[0]), int(p2[0])):
			newList.append([x, y, z])
		for y in range(int(p1[1]), int(p2[1])):
			newList.append([x, y, z])
		for z in range(int(p1[2]), int(p2[2])):
			newList.append([x, y, z])

newList = np.array(newList)
newList = np.unique(newList, axis=0)


# remove floating points by adding points to the ground if needed
newList2 = []
for p1 in newList:
	pointBelow = False
	pointAttached = False
	for p2 in newList:
		if (int(p2[0]) == int(p1[0]) and int(p2[2]) == int(p1[2]) and p2[1] < p1[1]):
			pointBelow = True
		if ((int(p2[0]) == int(p1[0])-1) or (int(p2[0]) == int(p1[0])+1) or (int(p2[2]) == int(p1[2])-1) or (int(p2[2]) == int(p1[2])+1)):
			pointAttached == True
	# add a point to the ground from every point if there is no point below int
	if (pointBelow == False and pointAttached == False):
		for j in range (int(p1[1])):
			newList2.append([p1[0], j, p1[2]])

np.append(newList, newList2, axis = 0)

newList = np.unique(newList, axis=0)


# Save the list as a text file
print(newList.shape)
np.savetxt(saveFileName, newList, fmt='%d', delimiter=' ', newline='\n')
