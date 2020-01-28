// Main class //<>// //<>//
import java.awt.*;
import javax.swing.*;
import java.awt.event.*;
import java.util.*;


ArrayList<Cube>[][][] space;
ArrayList<Integer> startPoints;

ArrayList<Cube> cubes;

int winWidth = 1500;
int winHeight = 800; 
int worldSize;

int cubeWidth = 20;

int[][] plyFile; 

Model currentModel;

boolean paused = true;
boolean drawModel = true;


int totalFrames = 0; // Total number of frames until simulation finished: for testing
boolean simFinished;

int time;
int wait = 2000;
int cn;

final static byte inc = 1;



//load the file first
void settings() {
  plyFile = readFile("plant.txt", 1);
  println(plyFile.length);
  size(1500, 800, P3D);
  smooth();
  
   // intialize the variables
  cubes = new ArrayList<Cube>();
  
  int maxX = getMaxIElement(plyFile, 0);
  int maxZ = getMaxIElement(plyFile, 1);
  int maxY = getMaxIElement(plyFile, 2);
  int minX = getMinIElement(plyFile, 0);
  int minZ = getMinIElement(plyFile, 1);
  int minY = getMinIElement(plyFile, 2);

  //worldSize = (Integer.max(Integer.max(maxX, maxZ), maxY) + 1);
  //println(worldSize);
  println("Intialize space array");
  // Init the 3d space arrays
  println(maxX, maxY, maxZ);
  space = new ArrayList[maxX+1][maxY+1][maxZ+1];
  for (int i = 0; i < space.length; i++) {
    for (int j = 0; j < space[0].length; j++) {
      for (int k = 0; k < space[0][0].length; k++) {
        space[i][j][k] = new ArrayList();
      }
    }
  }   


  //store the points where z is at 0 to place beacon points
  startPoints = new ArrayList<Integer>();

  println("Adding cubes");
  int len  = plyFile.length;
  currentModel = new Model(0, 0, maxX+1, maxY+1, maxZ+1);
  for (int i =0; i< len; i++) {
    int x = plyFile[i][0];
    int y = plyFile[i][2];
    int z = plyFile[i][1];
    if (currentModel.model[x][y][z] != 1) {
      currentModel.setModel(x, y, z, 1);
      cn++;
      if (plyFile[i][1] == 0 ) {
        startPoints.add(i);
      }
    }
  }
}

// Initialization
void setup () {
  frameRate(60);   

  colorMode(RGB, 225);    

  for (int i = 0; i < pressedKeys.length; i++) {
    pressedKeys[i] = false;
  }


   Cube beaconCube; //<>//

  for (int i = 0; i < startPoints.size(); i++) {
    //int x =startPoints.get((int)random(startPoints.size() - 1) + 1);
    int x = startPoints.get(i);
    beaconCube = new Cube(plyFile[x][0], plyFile[x][2], plyFile[x][1]);
    beaconCube.status = 2;
    beaconCube.cubeModel = currentModel.mClone();
    cubes.add(beaconCube);

    //currentModel.currLevel++;
  }

  time = millis();
}


/*
Add cubes to the cubelist
 */
ArrayList<Cube> addCubes(ArrayList<Cube> cubes) {
  //add 10 cubes if the number of moving cubes is > number of stationary cubes
  println("Adding 10 more cubes, total cubes = " + cubes.size());
  if (noOfCubesOnFloor(cubes,0) < 20 || cubes.size() < cn) {
    for (int i = 0; i < 10; i++) {  
      int rX = (int)random(worldSize - 2) + 1;
      int rY = (int)random(worldSize - 2) + 1;
      int rZ = 0;
      while (cubeAt(rX, rY, rZ) != null) {
        rX = (int)random(worldSize - 2) + 1;
        rY = (int)random(worldSize - 2) + 1;
      }
      Cube c = new Cube(rX, rY, rZ);
      c.cubeModel = currentModel.mClone();
      cubes.add(c);
    }
  }

  return cubes;
}


/*
Add beacon cubes to the cubelist
 */

// Render function
void draw() {
  //camera(camX, camY, camZ, camX + camRotX, camY + camRotY, camZ + camRotZ, 0, 1, 0);
  background(200, 200, 200);
  scale(zoom);
  
  //if (mousePressed)
  //  if      (mouseButton == LEFT)   zoom += inc;
  //  else if (mouseButton == RIGHT)  zoom -= inc;

  //rect(width>>1, height>>1, zoom, zoom);
  
  

  // Position of camera
  translate((winWidth / 2) * (1 / zoom), (winHeight / 2) * (1 / zoom), 50);
  //rotateX(HALF_PI);

  mousePressed();
 
  if (!paused) {
    if (millis() - time >= wait) {
      cubes= addCubes(cubes);
      time = millis();//also update the stored time
    }
    for (int i = 0; i < cubes.size(); i++) {
      cubes.get(i).update();
    }
  }

  currentModel.update(); // Only used for rendering
  drawFloor();

}


// Code that renders the flat plane
void drawFloor() {
  strokeWeight(1);
  pushMatrix();
  translate(0, 0, -1);
  fill(255, 255, 255);
  for (int i = 0; i < space.length; i++) {
    for (int j = 0; j < space[0].length; j++) {

      rect(-(cubeWidth * (space.length/2)) + (i * cubeWidth), -(cubeWidth * (space[0].length/2)) + (j * cubeWidth), cubeWidth, cubeWidth);

      for (int k = 0; k < space[0][0].length; k++) {
        translate(0, 0, cubeWidth);
      }

      translate(0, 0, -cubeWidth * space[0][0].length);
    }
  }  
  popMatrix();
}
