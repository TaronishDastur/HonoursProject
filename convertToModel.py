import open3d as o3d
import numpy as np

# pcd_load = o3d.io.read_point_cloud("chair.ply")

# remove outliers
def display_inlier_outlier(cloud, ind):
    inlier_cloud = cloud.select_down_sample(ind)
    outlier_cloud = cloud.select_down_sample(ind, invert=True)

    print("Showing outliers (red) and inliers (gray): ")
    outlier_cloud.paint_uniform_color([1, 0, 0])
    inlier_cloud.paint_uniform_color([0.8, 0.8, 0.8])
    # o3d.visualization.draw_geometries([inlier_cloud, outlier_cloud])



# load the point cloud file and convert it to np array
pcd = o3d.io.read_point_cloud("chair.ply")
xyzList = np.asarray(pcd.points)
print(xyzList.shape)

print('Read point cloud and reduce size')
# for i,e in enumerate(xyzList):
for i in range(len(xyzList)):
	e = xyzList[i]
	# print(e)
	e = np.rint(e) / 10000
	# print(e)
	xyzList[i] = e 

xyzList = np.unique(xyzList, axis=0)
print(xyzList.shape)


# find the max X,Y,Z value  --> that is the floor

xVar = {}
yVar = {}
zVar = {}
for x in xyzList:
	elX = x[0]
	elY = x[2]
	elZ = x[1]
	if (elX in xVar):
		xVar[elX] = xVar[elX] +1
	else: 
		xVar[elX] = 1

	if elY in yVar:
		yVar[elY] = yVar[elY] +1
	else:
		yVar[elY] = 1


	if elZ in zVar:
		zVar[elZ] = zVar[elZ] +1
	else:
		zVar[elZ] = 1		

vx=list(xVar.values())
kx=list(xVar.keys())
maxX =  kx[vx.index(max(vx))]

vy=list(yVar.values())
ky=list(yVar.keys())
maxY =  ky[vy.index(max(vy))]

vz=list(zVar.values())
kz=list(zVar.keys())
maxZ =  kz[vz.index(max(vz))]


# remove all elements around the floor 
reducedList = []
for i,x in enumerate(xyzList):
	# if (x[2] > maxY):
	# 	reducedList.append(x)
	if (x[1] > maxZ):
		reducedList.append(x)
	# if (x[0] > maxZ):
	# 	reducedList.append(x)			
	# if (x[0] > maxY+ 5.0):
	# 	# x =np.reshape(np.transpose(x), (1, 3))
	# reducedList.append(x)


# bring the y axis to the ground
mn = 100000
for x in (reducedList):
	if (x[1] < mn):
		mn = x[1]

for i, x in enumerate(reducedList):
	reducedList[i][1] = reducedList[i][1] - mn



reducedList = np.array(reducedList)
print(reducedList.shape)


# convert the modified vectors to a point cloud 
pcd.points = o3d.utility.Vector3dVector(reducedList)

# remove the outliers around a radius 
pcd = pcd.voxel_down_sample(voxel_size=3)
o3d.visualization.draw_geometries([pcd])

uni_down_pcd = pcd.uniform_down_sample(every_k_points=5)
cl, ind = pcd.remove_statistical_outlier(nb_neighbors=20,
                                                    std_ratio=0.5)
o3d.visualization.draw_geometries([cl])

# convert the point cloud back to vector 
newList = np.asarray(cl.points)
print(newList.shape)
np.savetxt("QbiQ/game.txt", newList, fmt='%d', delimiter=' ', newline='\n')
