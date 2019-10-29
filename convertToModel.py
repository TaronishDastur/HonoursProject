import vtkplotter as vtk
import numpy as np


# vp = Plotter(N=4, axes=0, bg='w')

reader = vtk.vtkPLYReader()
reader.SetFileName(filename)
reader.Update()

'''
act = vp.load(datadir+"mergedPcl.pcl")
vp.show(act, at=0)

noise = np.random.randn(act.N(), 3) * 0.04

pts0 = Points(act.getPoints() + noise, r=3).legend("noisy cloud")
vp.show(pts0, at=1)

pts1 = smoothMLS2D(pts0, f=0.4)  # smooth cloud, input actor is modified

print("Nr of points before cleaning polydata:", pts1.N())

# impose a min distance among mesh points
pts1.clean(tol=0.01).legend("smooth cloud")
print("             after  cleaning polydata:", pts1.N())

vp.show(pts1, at=2)

# reconstructed surface from point cloud
reco = recoSurface(pts1, bins=128).legend("surf reco")
vp.show(reco, at=3, axes=7, zoom=1.2, interactive=1)

'''
'''
reader = vtk.vtkPLYReader()
reader.SetFileName(filename)
reader.Update()

mapper = vtk.vtkPolyDataMapper()
mapper.SetInputConnection(reader.GetOutputPort())

actor = vtk.vtkActor()
actor.SetMapper(mapper)

renderer = vtk.vtkRenderer()
renderWindow = vtk.vtkRenderWindow()
renderWindow.AddRenderer(renderer)
renderWindowInteractor = vtk.vtkRenderWindowInteractor()
renderWindowInteractor.SetRenderWindow(renderWindow)

renderer.AddActor(actor)
renderer.SetBackground(.3, .6, .3)   #Background color green

renderWindow.Render()
renderWindowInteractor.Start()
'''

# https://github.com/marcomusy/vtkplotter/blob/master/LICENSE