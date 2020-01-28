// The model class that represents the model to be built.
// Imagine the model as a 3 dimensional figure, with certain coordinates containing cubes and others not, to create a structure.
class Model {
    public int x, y; // The x y location of the model, 'top-left'
    public int w, d, h; // The width, depth and height of the model;
    int modelCubeWidth = 20;
    
    public int totalCubes;  // Total number of cubes that make up the structure
    
    public int[][][] model; // The 3d array that represents the model
    
    public int[] floors;    // The number of cubes needed on each floor
    public int currLevel = 0;
    
    Model(int mx, int my, int mw, int md, int mh) {
        x = mx;
        y = my;
        w = mw;
        d = md;        
        h = mh;
        
        model = new int[w][d][h];
        for (int i = 0; i < w; i++) {
            for (int j = 0; j < d; j++) {
                for (int k = 0; k < h; k++) {
                    model[i][j][k] = 0;
                }
            }    
        }
        
        floors = new int[mh];
        
        for (int i = 0; i < h; i++) {
            floors[i] = 0;    
        }
    }
    
    Model mClone() {
        Model newModel = new Model(x, y, w, d, h);
        newModel.model = model;
        newModel.totalCubes = totalCubes;
        newModel.floors = floors;
        newModel.currLevel = currLevel;
        return newModel; 
    }
    
    void setModel(int x, int y, int z, int val) {
        model[x][y][z] = val;
        updateFloors();   
    }
    
    void updateFloors() {
        for (int i = 0; i < h; i++) {
            floors[i] = 0;    
        }
        
        for (int i = 0; i < w; i++) {
            for (int j = 0; j < d; j++) {                
                for (int k = 0; k < h; k++) {                
                    if (model[i][j][k] == 1) {
                        floors[k]++;
                    }                
                }               
            }
        }
    }
    
    /*
    update and draw model
    */
    void update() {
        if (drawModel) {
            strokeWeight(0);
            fill(90, 90, 90, 40);
            for (int i = 0; i < w; i++) {
                for (int j = 0; j < d; j++) {
                    for (int k = 0; k < h; k++) {
                        if (model[i][j][k] == 1) {drawModelCube(i + x, j + y, k); }
                    }
                }    
            }
        } 
    }
    
    /*
    check if the model is finished 
    */
    public boolean modelFinished() {
        boolean finished = true;
        for (int i = 0; i < w; i++) {
            for (int j = 0; j < d; j++) {
                for (int k = 0; k < h; k++) {
                    if (model[i][j][k] == 1 && space[i + x][j + y][k].isEmpty()) { finished = false; }
                }
            }    
        }
        return finished;
    }
    
    
    void drawModelCube(int gX, int gY, int gZ) {          
        pushMatrix();        
        
        int changeX = 1;
        int changeY = 1;
        int changeZ = 1;
        int transX = 0;
        int transY = 0;
        
        translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX + 3, -(cubeWidth * (space[0].length / 2)) +(gY * cubeWidth) + transY + 3, (gZ * cubeWidth) + 3);
        
        //change this to change the size of the cubes 
        scale(10); 
        
        beginShape(QUADS);
        fill(150, 150, 150);
        stroke(0,0,0);
        strokeWeight(0.2);
        
        vertex(-1 + changeX,  1 + changeY,  1 + changeZ);
        vertex( 1 + changeX,  1 + changeY,  1 + changeZ);
        vertex( 1 + changeX, -1 + changeY,  1 + changeZ);
        vertex(-1 + changeX, -1 + changeY,  1 + changeZ);
          
        vertex( 1 + changeX,  1 + changeY,  1 + changeZ);
        vertex( 1 + changeX,  1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY,  1 + changeZ);
          
        vertex( 1 + changeX,  1 + changeY, -1 + changeZ);
        vertex(-1 + changeX,  1 + changeY, -1 + changeZ);
        vertex(-1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, -1 + changeZ);
          
        vertex(-1 + changeX,  1 + changeY, -1 + changeZ);
        vertex(-1 + changeX,  1 + changeY,  1 + changeZ);
        vertex(-1 + changeX, -1 + changeY,  1 + changeZ);
        vertex(-1 + changeX, -1 + changeY, -1 + changeZ);
          
        vertex(-1 + changeX,  1 + changeY, -1 + changeZ);
        vertex( 1 + changeX,  1 + changeY, -1 + changeZ);
        vertex( 1 + changeX,  1 + changeY,  1 + changeZ);
        vertex(-1 + changeX,  1 + changeY,  1 + changeZ);
          
        vertex(-1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY,  1 + changeZ);
        vertex(-1 + changeX, -1 + changeY,  1 + changeZ);
          
        endShape();
        popMatrix();
    }
    
    
    boolean inModel (int cX, int cY, int cZ) {
        int fX = cX - x;
        int fY = cY - y;
        if (fX < 0 || fX >= w || fY < 0 || fY >= d || cZ < 0 || cZ >= h) { return false; }
        if (model[fX][fY][cZ] == 1) { return true; }
        return false;   
    }
    
    // Model responds with spaces around the asking cube that needs to be filled
    // The only cubes that can ask this are cubes that are in beacon status,
    // So we know they fill a certain spot in the model already.
    public int[] getSpacesToFill(int cX, int cY, int cZ, int[] container) {
         //only fill top if the sides are filled
        if (inModel(cX, cY - 1, cZ) && (cubeAt(cX, cY - 1, cZ) == null || cubeAt(cX, cY - 1, cZ).status < 2)) { container[0] = 1; }  // N
        if (inModel(cX + 1, cY, cZ) && (cubeAt(cX + 1, cY, cZ) == null || cubeAt(cX + 1, cY, cZ).status < 2)) { container[1] = 1; }  // E
        if (inModel(cX, cY + 1, cZ) && (cubeAt(cX, cY + 1, cZ) == null || cubeAt(cX, cY + 1, cZ).status < 2)) { container[2] = 1; }  // S
        if (inModel(cX - 1, cY, cZ) && (cubeAt(cX - 1, cY, cZ) == null || cubeAt(cX - 1, cY, cZ).status < 2)) { container[3] = 1; }  // W
        if (inModel(cX, cY, cZ + 1) && (cubeAt(cX, cY, cZ + 1) == null || cubeAt(cX, cY, cZ + 1).status < 2)) { container[4] = 1; }  // T
        if (inModel(cX, cY, cZ - 1) && (cubeAt(cX, cY, cZ - 1) == null || cubeAt(cX, cY, cZ - 1).status < 2)) { container[5] = 1; }  // B    
        return container;        
    }
    
}
