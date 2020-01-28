// Functions for mouse, GUI, anything not part of the robot logic or landscape //<>//

float currX, currY = 0;
float postX, postY = 0;
float zoom = 0.5;
float xDiff, yDiff = 0, zDiff;
boolean beginTrans = false;

float mouseSensitivity = -20;
float xRatio, yRatio, zRatio = 0;
float xAngle, yAngle = 0;

float preX, preY = 0;
float preHorizontalDiff, preVerticalDiff = 0;
float postHorizontalDiff, postVerticalDiff = 0;

void mousePressed() {
  if (mousePressed) {
    if (!beginTrans) {
      preX = mouseX;
      preY = mouseY;
      preHorizontalDiff = postHorizontalDiff;
      preVerticalDiff = postVerticalDiff;
      beginTrans = true;
    } else {
      postX = mouseX;
      postY = mouseY;
      postHorizontalDiff = preX - postX + preHorizontalDiff;
      postVerticalDiff = preY- postY + preVerticalDiff;
      rotateY(-postHorizontalDiff / (100 - mouseSensitivity));
      rotateX(postVerticalDiff / (100 - mouseSensitivity));
    }
  } else if (mousePressed == false)
  {
    beginTrans = false;
    preHorizontalDiff = postHorizontalDiff;
    preVerticalDiff = postVerticalDiff;
    rotateY(-preHorizontalDiff / (100 - mouseSensitivity));
    rotateX(preVerticalDiff / (100 - mouseSensitivity));
  }
}


void mouseWheel(int delta) {
  if (delta == 1)
  {
    if (zoom > 0.10) { 
      zoom -= 0.05;
    }
  } else if (delta == -1) { 
    zoom += 0.05;
  }
}

// Returns
Cube cubeAt(int x, int y, int z) {    
  if (x >= 0 && x < worldSize && y >= 0 && y < worldSize && z >= 0 && z < worldSize && !space[x][y][z].isEmpty()) { 
    return space[x][y][z].get(0);
  }
  return null;
}



float camSpeed = 10;
int[] td = {0, 0, 0};

float xVector = 0;
float yVector = 0;
float zVector = 0;
float ratio = 0;

boolean[] pressedKeys = new boolean[6];

void keyReleased() {

  if (keyCode == ENTER) { 
    paused = !paused;
  }

  if (key == 'm') { 
    drawModel = !drawModel;
  }

  if (key == 'w') { 
    pressedKeys[0] = false;
  }   
  if (key == 's') { 
    pressedKeys[1] = false;
  }     
  if (key == 'a') { 
    pressedKeys[2] = false;
  }  
  if (key == 'd') { 
    pressedKeys[3] = false;
  }
  if (key == ' ') { 
    pressedKeys[4] = false;
  }
  if (key == CODED && keyCode == SHIFT) { 
    pressedKeys[5] = false;
  }
}

void keyPressed() {
  //if (key == 'w') { 
  //  pressedKeys[0] = true;
  //}   
  //if (key == 's') { 
  //  pressedKeys[1] = true;
  //}     
  //if (key == 'a') { 
  //  pressedKeys[2] = true;
  //}  
  //if (key == 'd') { 
  //  pressedKeys[3] = true;
  //}
  //if (key == ' ') { 
  //  pressedKeys[4] = true;
  //}
  //if (key == CODED && keyCode == SHIFT) { 
  //  pressedKeys[5] = true; 
    if (keyCode==UP) {
      zoom += inc;
    }
    if (keyCode==DOWN) {
      zoom -= inc;
    }
    rect(width>>1, height>>1, zoom, zoom);
  }


/*
void keyDown() { 
 ratio = camSpeed / sqrt( (camRotX * camRotX) + (camRotY * camRotY) + (camRotZ * camRotZ));
 if (pressedKeys[0]) {                
 camX += camRotX * ratio;
 camY += camRotY * ratio;
 camZ += camRotZ * ratio;              
 } 
 
 if (pressedKeys[1]) {
 camX -= camRotX * ratio;
 camY -= camRotY * ratio;
 camZ -= camRotZ * ratio;
 } 
 
 if (pressedKeys[2]) { 
 camX += camRotZ * ratio;
 camZ -= camRotX * ratio;
 } 
 
 if (pressedKeys[3]) { 
 camX -= camRotZ * ratio;
 camZ += camRotX * ratio;
 }
 
 if (pressedKeys[4]) {
 camY -= camSpeed;
 }
 
 if (pressedKeys[5]) {
 camY += camSpeed;
 } 
 }
 */


// Check if model is complete, only used for debugging purposes
boolean checkFinished() {
  for (int i = 0; i < currentModel.w; i++) {
    for (int j = 0; j < currentModel.d; j++) {
      for (int k = 0; k < currentModel.h; k++) {
        if (currentModel.inModel(currentModel.x + i, currentModel.y + j, k)) {
          if (cubeAt(currentModel.x + i, currentModel.y + j, k) == null || cubeAt(currentModel.x + i, currentModel.y + j, k).status < 3 ) {
            return false;
          }
        }
      }
    }
  }
  return true;
}



/*
read file 
 */
int[][] readFile(String filename, int reduce) {
  int pointNum = 0;
  String[] lines = loadStrings(filename);
  int[][] pcloud = new int[lines.length][3];
  for (int i = 0; i < lines.length; i++) {
    String[] pieces = splitTokens(lines[i]);
    if (pieces.length == 3) {
      pcloud[pointNum++] = asInt(pieces, reduce );
    }
  }
  return pcloud;
}



public int[] asInt(String[] pieces, int reduce) {
  int x = Math.abs(Integer.parseInt(pieces[0]))/reduce;
  int y = Math.abs(Integer.parseInt(pieces[1]))/reduce;
  int z = Math.abs(Integer.parseInt(pieces[2]))/reduce;
  return new int[]{x, y, z};
}


public int getMaxIElement(int[][] list, int i) {
  int max = 0;
  for (int[] f : list) {
    //int m = Integer.max(Integer.max(f[0], f[1]), f[2]);
    int m = f[i];
    if (max < m)
      max = m;
  }
  return max;
}

public int getMinIElement(int[][] list, int i) {
  int min = 20000000;
  for (int[] f : list) {
    //int m = Integer.max(Integer.max(f[0], f[1]), f[2]);
    int m = f[i];
    if (min > m)
      min = m;
  }
  return min;
}

/*
check how many cubes are currently in a particular state
 */
int noOfCubes(ArrayList<Cube> cubeList, int state) {
  int counter = 0;
  for (Cube c : cubeList) {
    if (c.status == state) {
      counter++;
    }
  }
  return counter;
}

/*
check number of cubes on a level
 */
int noOfCubesOnFloor(ArrayList<Cube> cubeList, int floor) {
  int counter = 0;
  for (Cube c : cubeList) {
    if (c.gZ == floor) {
      counter++;
    }
  }
  return counter;
}
