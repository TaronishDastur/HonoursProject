// The cube robot class

class Cube {
    public int gX, gY, gZ;    
    public int dir;        // 0 - None | 1 - N | 2 - E | 3 - S | 4 - W

    public int status = 0;      // 0 - Wandering/Moving  | 1 - Climbing Stage | 2 - Need to fill | 3 - Self-set | 4 - Completely done

    public boolean moving;
    public boolean receivedSignal = false; // Received  "turn back on" signal

    int upDown;            // Copy of checkSpace function return value

    int prevDir;  // Previous direction of movement

    int prevX, prevY, prevZ;
    float moveSpeed;           // Cube flop movement speed    
    float turnOver;            // Cube flopping rotation angle    

    int swingTB = 0;
    int swingLR = 0;

    // Variables needed for cube rendering
    int changeX = 1;
    int changeY = 1;
    int changeZ = 1;
    int transX = 0;
    int transY = 0;
    int transZ = 0;
    
    public boolean hasTarget = false;
    public float targetRange = 999999;
    public int[] target;

    int[] spacesToFill;    // The 6 directional spaces around this cube that needs to be filled, order: NESWTB | 012345

    public int r, g, b;
    
    int stuckCount;  // How many frames the cube got stuck for
    int stuckLimit = 5;

    int dirLock = 3;
    
    public int dirPointer = -1;
    int beaconPos = -1; // If cube is listening on beacon in status 2, keep track of where it is in relation to cube

    public Model cubeModel;

    int delay = 30;          // Number of frames to delay information passing
    int range = worldSize;   // Range to scan for the beacon
    
    int broadcastCount = -1; // -1 - Not broadcasting | 0 - broadcast frame | > 0 - counting down
    int broadcastWaveCount = range;
    
    Cube(int x, int y, int z) {
        moveSpeed = 0.15;
        turnOver = 0;
        prevDir = 0;
        dir = 0;
        moving = false;

        r = 50;
        g = 190;
        b = 160;

        gX = x;
        gY = y;
        gZ = z;

        spacesToFill = new int[6];
        for (int i = 0; i < 6; i++) { spacesToFill[i] = 0; }

        // Add to global space variable
        space[gX][gY][gZ].add(this);
    }

    // Using wireless communication, find how many green cubes are on the current level
    int countSet() {
        int count = 0;
        
        int range = (int)(sqrt(pow(cubeModel.w, 2) + pow(cubeModel.d, 2))) + 1;
        
        for (int i = -range; i <= range; i++) {
            if (gX + i >= 0 && gX + i < worldSize) {
                for (int j = -range; j <= range; j++) {
                    if (gY + j >= 0 && gY + j < worldSize) {
                        if (cubeModel.inModel(gX + i, gY + j, cubeModel.currLevel) && cubeAt(gX + i, gY + j, cubeModel.currLevel) != null && cubeAt(gX + i, gY + j, cubeModel.currLevel).status >= 2) {
                            count++;    
                        }
                    }
                }    
            }                
        }
        return count;
    }

    // Broadcast to other cubes (with delay) of change in model
    void broadcast() {
        if (broadcastCount > 0) { broadcastCount--; }
        else if (broadcastCount == 0) {  // After delay, communcation is achieved
            for (int i = -broadcastWaveCount; i <= broadcastWaveCount; i++) {
                if (gX + i >= 0 && gX + i < worldSize) {
                    for (int j = -broadcastWaveCount; j <= broadcastWaveCount; j++) {
                        if (gZ + j >= 0 && gZ + j < worldSize) {                            
                            if (gY >= broadcastWaveCount) { // North face
                                Cube tc = cubeAt(gX + i, gY - broadcastWaveCount, gZ + j);
                                if (tc != null) {
                                    tc.cubeModel.currLevel = cubeModel.currLevel;                           // Copy current floor level
                                    if (tc.status >= 2 && broadcastCount == -1) { broadcastCount = delay; } // If cube is of status 2 or higher and not currently broadcasting, start broadcasting                                                                                               
                                }                                                                   
                            }
                            if (gY < worldSize - broadcastWaveCount) { // South face
                                Cube tc = cubeAt(gX + i, gY + broadcastWaveCount, gZ + j);
                                if (tc != null) {
                                    tc.cubeModel.currLevel = cubeModel.currLevel;         
                                    if (tc.status >= 2 && broadcastCount == -1) { broadcastCount = delay; } 
                                }                           
                            }                              
                        }
                    }    
                }                 
            }
             
            for (int i = -(broadcastWaveCount-1); i <= (broadcastWaveCount-1); i++) {
                if (gY + i >= 0 && gY + i < worldSize) {
                    for (int j = -broadcastWaveCount; j <= broadcastWaveCount; j++) {
                        if (gZ + j >= 0 && gZ + j < worldSize) {                            
                            if (gX >= broadcastWaveCount) { // West face
                                Cube tc = cubeAt(gX - broadcastWaveCount, gY + i, gZ + j);
                                if (tc != null) {
                                    tc.cubeModel.currLevel = cubeModel.currLevel;
                                    if (tc.status >= 2 && broadcastCount == -1) { broadcastCount = delay; } 
                                }                                    
                            }
                            if (gX < worldSize - broadcastWaveCount) { // East face
                                Cube tc = cubeAt(gX + broadcastWaveCount, gY + i, gZ + j);
                                if (tc != null) {
                                    tc.cubeModel.currLevel = cubeModel.currLevel;
                                    if (tc.status >= 2 && broadcastCount == -1) { broadcastCount = delay; } 
                                }                                    
                            }                              
                        }
                    }    
                }                 
            }    
            
            for (int i = -(broadcastWaveCount-1); i <= (broadcastWaveCount-1); i++) {
                if (gX + i >= 0 && gX + i < worldSize) {
                    for (int j = -(broadcastWaveCount-1); j <= (broadcastWaveCount-1); j++) {
                        if (gY + j >= 0 && gY + j < worldSize) {                            
                            if (gZ >= broadcastWaveCount) { // Bottom face
                                Cube tc = cubeAt(gX + i, gY + j, gZ - broadcastWaveCount);
                                if (tc != null) {
                                    tc.cubeModel.currLevel = cubeModel.currLevel;
                                    if (tc.status >= 2 && broadcastCount == -1) { broadcastCount = delay; } 
                                }                                    
                            }
                            if (gZ < worldSize - broadcastWaveCount) { // Top face
                                Cube tc = cubeAt(gX + i, gY + j, gZ + broadcastWaveCount);
                                if (tc != null) {
                                    tc.cubeModel.currLevel = cubeModel.currLevel;
                                    if (tc.status >= 2 && broadcastCount == -1) { broadcastCount = delay; } 
                                }                                    
                            }                              
                        }
                    }    
                }                 
            }  
            
            broadcastCount = delay;  // Set delay again for next wave
            broadcastWaveCount++;   // Signal next wave
            
            if (broadcastWaveCount == range) { // We're done broadcasting
                broadcastCount = -1;                    
            }
        }        
        
    }

    // Signal the beacon if cube is in place but not done   
    void signalBeacon () {
        if (gZ > 0) { return; }
        // Broadcast to cubes without target
        for (int i = - (range / 2); i <= (range / 2); i++) {
            if (gX + i >= 0 && gX + i < worldSize) {
                for (int j = - (range / 2); j <= (range / 2); j++) {                
                    if (gY + j >= 0 && gY + j < worldSize) {
                        for (int k = - (range / 2); k <= (range / 2); k++) {
                            if (gZ + k >= 0 && gZ + k < worldSize) {
                                
                                if (cubeAt(gX + i, gY + j, gZ + k) != null && cubeAt(gX + i, gY + j, gZ + k).status == 0 && !cubeAt(gX + i, gY + j, gZ + k).moving){
                                    
                                    if ( sqrt((i*i) + (j*j) + (k*k)) < cubeAt(gX + i, gY + j, gZ + k).targetRange) {
                                        cubeAt(gX + i, gY + j, gZ + k).targetRange = sqrt((i*i) + (j*j) + (k*k));
                                        cubeAt(gX + i, gY + j, gZ + k).hasTarget = true;
                                        cubeAt(gX + i, gY + j, gZ + k).target = new int[3];
                                        cubeAt(gX + i, gY + j, gZ + k).target[0] = gX;
                                        cubeAt(gX + i, gY + j, gZ + k).target[1] = gY;
                                        cubeAt(gX + i, gY + j, gZ + k).target[2] = gZ;
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    }

    // Update the known spaces to fill by asking the model
    // As well as asking the attached beacon cubes if theyre done if my spaces are done
    void updateSpacesToFill() {      
        // 012345 | NESWTB
        for (int i = 0; i < 6; i++) { spacesToFill[i] = 0; } 
        spacesToFill = cubeModel.getSpacesToFill(gX, gY, gZ, spacesToFill); // Ask model for which of the 6 directions need to be filled  
     
        boolean done = true;
        
        int rng = 0;
        
        if (gZ == cubeModel.currLevel) { rng = 4; }
        else { rng = 6; }
            
        for (int i = 0; i < rng; i++) {
            if (spacesToFill[i] == 1) { 
                done = false;
                break;
            }
        }
        
        if (done) { status = 3; }
        else {
            status = 2;            
            dirPointer = -1;                
            while (dirPointer == -1) {
                int rnd = (int)random(rng);
                if (spacesToFill[rnd] == 1) { dirPointer = rnd; }
            }
        }    
    }

    void moveTowardsTarget() {
        if (moving || target == null) return;
        // Only move towards the target in 1 direction at a time

        int stepX = target[0] - gX;
        int stepY = target[1] - gY;
        int stepZ = target[2] - gZ;
        int r = (int)random(2);

        // Currently hitting one of the sides of the target cube
        if (abs(stepX) + abs(stepY) + abs(stepZ) == 1) {
            status = 1;
            return;
        }

        if (stepX == 0 && stepY == 0 && abs(stepZ) > 1 ) {
            dir = (int)random(4) + 1;    
        } else if (stepX == 0) {
            if (stepY > 0) { 
                dir = 3;
            } else { 
                dir = 1;
            }
        } else if ( stepY == 0) {
            if (stepX > 0) { 
                dir = 2;
            } else { 
                dir = 4;
            }
        } else {            
            if (stepX > 0 && stepY > 0) {   // NW
                switch (r) {
                case 0:
                    dir = 2; // E
                    return;
                case 1:
                    dir = 3; // S
                }
            }

            if (stepX < 0 && stepY > 0) {   // NE
                switch (r) {
                case 0:
                    dir = 4; // W
                    return;
                case 1:
                    dir = 3; // S
                }
            }

            if (stepX < 0 && stepY < 0) {   // SE
                switch (r) {
                case 0:
                    dir = 4; // W
                    return;
                case 1:
                    dir = 1; // N
                }
            }

            if (stepX > 0 && stepY < 0) {   // SW
                switch (r) {
                case 0:
                    dir = 2; // E
                    return;
                case 1:
                    dir = 1; // N
                }
            }
        }
    }

    // Find the next direction to move in while climbing
    // by scanning the nearby area for beacons and the path they need
    
    void climbNext() {           
        // find a random, valid beacon to listen on
        Cube beacon = null;
        int r = -1;
        int[] checked = new int[6];
        boolean invalid = false;
        
        ArrayList<Integer> rInts = new ArrayList<Integer>();
        for (int i = 0; i < 6; i++) { rInts.add(i); }
        Collections.shuffle(rInts);
        
        for (int i = 0; i < 6; i++) {   
            int rnd = rInts.get(i);            
            
            switch(rnd) {           
                case 0: if (cubeAt(gX-1, gY, gZ) != null && cubeAt(gX-1, gY, gZ).status == 2) { beacon = cubeAt(gX-1, gY, gZ); r = 0; } break; // Beacon at W  
                case 1: if (cubeAt(gX+1, gY, gZ) != null && cubeAt(gX+1, gY, gZ).status == 2) { beacon = cubeAt(gX+1, gY, gZ); r = 1; } break; // Beacon at E   
                case 2: if (cubeAt(gX, gY-1, gZ) != null && cubeAt(gX, gY-1, gZ).status == 2) { beacon = cubeAt(gX, gY-1, gZ); r = 2; } break; // Beacon at N
                case 3: if (cubeAt(gX, gY+1, gZ) != null && cubeAt(gX, gY+1, gZ).status == 2) { beacon = cubeAt(gX, gY+1, gZ); r = 3; } break; // Beacon at S
                case 4: if (cubeAt(gX, gY, gZ-1) != null && cubeAt(gX, gY, gZ-1).status == 2) { beacon = cubeAt(gX, gY, gZ-1); r = 4; } break; // Beacon at B
                case 5: if (cubeAt(gX, gY, gZ+1) != null && cubeAt(gX, gY, gZ+1).status == 2) { beacon = cubeAt(gX, gY, gZ+1); r = 5; } break; // Beacon at T
            }
            if (r != -1) { break; }          
        }
        
        if (r == -1) {
            Collections.shuffle(rInts);
            for (int i = 0; i < 6; i++) {   
                int rnd = rInts.get(i);            
                
                switch(rnd) {           
                    case 0: if (cubeAt(gX-1, gY, gZ) != null && cubeAt(gX-1, gY, gZ).status == 3) { beacon = cubeAt(gX-1, gY, gZ); r = 0; } break; // Beacon at W  
                    case 1: if (cubeAt(gX+1, gY, gZ) != null && cubeAt(gX+1, gY, gZ).status == 3) { beacon = cubeAt(gX+1, gY, gZ); r = 1; } break; // Beacon at E   
                    case 2: if (cubeAt(gX, gY-1, gZ) != null && cubeAt(gX, gY-1, gZ).status == 3) { beacon = cubeAt(gX, gY-1, gZ); r = 2; } break; // Beacon at N
                    case 3: if (cubeAt(gX, gY+1, gZ) != null && cubeAt(gX, gY+1, gZ).status == 3) { beacon = cubeAt(gX, gY+1, gZ); r = 3; } break; // Beacon at S
                    case 4: if (cubeAt(gX, gY, gZ-1) != null && cubeAt(gX, gY, gZ-1).status == 3) { beacon = cubeAt(gX, gY, gZ-1); r = 4; } break; // Beacon at B
                    case 5: if (cubeAt(gX, gY, gZ+1) != null && cubeAt(gX, gY, gZ+1).status == 3) { beacon = cubeAt(gX, gY, gZ+1); r = 5; } break; // Beacon at T
                }
                if (r != -1) { break; }          
            }
        }
        
        beaconPos = r;        
        int neededDir = beacon.dirPointer; // Get direction from beacon
        cubeModel.currLevel = beacon.cubeModel.currLevel;  // Also get the currLevel info from beacon
        
 
        // Beacon needs cube at direction i = 012345 | NESWTB    r = 012345 | WENSBT
        // r is the beacon we're listening to currently
        //System.out.println(i + ", " + r);
        switch(neededDir) {            
                case 0: // Need N
                    switch(r) {            
                        case 0: dir = 1; break; // Beacon is W
                        case 1: dir = 1; break; // Beacon is E
                        case 2: // Beacon is N
                                
                                int rn = 0;
                                if (cubeAt(gX-1, gY-1, gZ) != null && cubeAt(gX+1, gY-1, gZ) != null) {
                                    dir = 1;
                                } else {
                                    rn = (int)random(2);
                                    switch(rn) {
                                        case 0: dir = 2;
                                        case 1: dir = 4;                                            
                                    }
                                }
                                dir = (int)random(4) + 1;                        
                                break;
                        case 3: dir = 1; break; // Beacon is S  **
                        case 4: dir = 1; break; // Beacon is Top
                        case 5: dir = 1; break; // Beacon is Bottom
                    }
                    break;
                case 1: // Need E
                    switch(r) {            
                        case 0: dir = 2; break; // **
                        case 1: 
                                
                                int rn = 0;
                                if (cubeAt(gX+1, gY-1, gZ) != null && cubeAt(gX+1, gY+1, gZ) != null) {
                                    dir = 2;
                                } else {
                                    rn = (int)random(2);
                                    switch(rn) {
                                        case 0: dir = 1;
                                        case 1: dir = 3;                                            
                                    }
                                }          
                                dir = (int)random(4) + 1;                      
                                break;
                        case 2: dir = 2; break;
                        case 3: dir = 2; break;
                        case 4: dir = 2; break;
                        case 5: dir = 2; break;        
                    }
                    break;
                case 2: // Need S
                    switch(r) {            
                        case 0: dir = 3; break;
                        case 1: dir = 3; break;
                        case 2: dir = 3; break; // **
                        case 3:
                                
                                int rn = 0;
                                if (cubeAt(gX+1, gY+1, gZ) != null && cubeAt(gX-1, gY+1, gZ) != null) {
                                    dir = 3;
                                } else {
                                    rn = (int)random(2);
                                    switch(rn) {
                                        case 0: dir = 2;
                                        case 1: dir = 4;                                            
                                    }
                                }      
                                dir = (int)random(4) + 1;                          
                                break;
                        case 4: dir = 3; break;
                        case 5: dir = 3; break;        
                    }
                    break;
                case 3: // Need W
                    switch(r) {            
                        case 0:                                 
                                int rn = 0;
                                if (cubeAt(gX-1, gY+1, gZ) != null && cubeAt(gX-1, gY-1, gZ) != null) {
                                    dir = 4;
                                } else {
                                    rn = (int)random(2);
                                    switch(rn) {
                                        case 0: dir = 1;
                                        case 1: dir = 3;                                            
                                    }
                                } 
                                dir = (int)random(4) + 1;                               
                                break;
                        case 1: dir = 4; break; // **
                        case 2: dir = 4; break;
                        case 3: dir = 4; break;
                        case 4: dir = 4; break;
                        case 5: dir = 4; break;        
                    }
                    break;
                case 4: // Need T
                    switch(r) {            
                        case 0: dir = 4; break;
                        case 1: dir = 2; break;
                        case 2: dir = 1; break;
                        case 3: dir = 3; break;
                        case 4: dir = (int)random(4) + 1; break;
                        case 5: dir = (int)random(4) + 1; break;        
                    }
                    break;
                case 5: // Need B
                    switch(r) {            
                        case 0: dir = 2; break;
                        case 1: dir = 4; break;
                        case 2: dir = 3; break;
                        case 3: dir = 1; break;
                        case 4: dir = (int)random(4) + 1; break;
                        case 5: dir = (int)random(4) + 1; break;   
                    }
                    break;
            }
            
    }
    
    // This function runs only when status = 3, 
    // find a status 2 beacon closest to the cube, set direction pointer to the greatest out of the x,y,z to that beacon
    // find beacon using euclidean distance
    void setDirectionPointer() {  
        // Find all status 2 beacons within range (range = max(x y z) of model)

        int range = (int)sqrt(pow(cubeModel.w, 2) + pow(cubeModel.d, 2) + pow(cubeModel.h, 2));
        ArrayList<Cube> status2cubes = new ArrayList<Cube>();
               
        for (int i = -(range); i <= range; i++) {
            for (int j = -(range); j <= range; j++) {
                for (int k = -(range); k <= range; k++) {
                    if (cubeAt(i + gX, j + gY, k + gZ) != null && cubeAt(i + gX, j + gY, k + gZ).status == 2) {
                        status2cubes.add(cubeAt(i + gX, j + gY, k + gZ));   
                    }
                }
            }
        }
        
        if (status2cubes.size() == 0) { return; }
        
        int minCubeInd = 0;
        float minDist = 99999;
        float dist;
        
        for (int i = 0; i < status2cubes.size(); i++) {
            dist = sqrt(pow(status2cubes.get(i).gX - gX, 2) + pow(status2cubes.get(i).gY - gY, 2) + pow(status2cubes.get(i).gZ - gZ, 2));
            if (dist < minDist) {
                minDist = dist;
                minCubeInd = i;    
            }
        }
        
        Cube minCube = status2cubes.get(minCubeInd);
        
        float total = abs(minCube.gX - gX) + abs(minCube.gY - gY) + abs(minCube.gZ - gZ);
        
        int NSPriority = Math.round((float)abs(minCube.gY - gY) / total * 100);
        int EWPriority = Math.round((float)abs(minCube.gX - gX) / total * 100);
        int UDPriority = Math.round((float)abs(minCube.gZ - gZ) / total * 100);
        
        ArrayList<Integer> directions = new ArrayList<Integer>();
               
        if (minCube.gX > gX) { for (int i = 0; i < EWPriority; i++) { directions.add(1); } }
        else { for (int i = 0; i < EWPriority; i++) { directions.add(3); } }
        
        if (minCube.gY > gY) { for (int i = 0; i < NSPriority; i++) { directions.add(2); } }
        else { for (int i = 0; i < NSPriority; i++) { directions.add(0); } }
        
        // favor top
        if (minCube.gZ > gZ) { for (int i = 0; i < UDPriority; i++) { directions.add(4); directions.add(4); directions.add(4); } }
        else { for (int i = 0; i < UDPriority; i++) { directions.add(5); } }
        
        Collections.shuffle(directions);
        
        if (directions.size() > 0) { dirPointer = directions.get(0); } else {
            println("Uh Oh");     
        }

    }

    // Cube render function / CBUPDATE
    void update() {

        pushMatrix();
                
        changeX = 1;
        changeY = 1;
        changeZ = 1;
        transX = 0;
        transY = 0;
        transZ = 0;
        if (countSet() == cubeModel.floors[cubeModel.currLevel]) {
                            if (cubeModel.currLevel < cubeModel.h-1) { 
                                cubeModel.currLevel++;
                                broadcastCount = delay;          
                                broadcastWaveCount = 1; 
                            }             
                        }    
        switch (status) {        
            case 0:
                r = 50;
                g = 190;
                b = 160;
                // INSERT DIRECTION LOGIC HERE
                if (hasTarget) {
                    r = 200;
                    g = 200;
                    b = 10;
                    moveTowardsTarget();
                } else {
                    moveRandom();
                }                
                int intendedDir = dir;
                upDown = checkSpace();            
                
                if (stuckCount > stuckLimit) {    
                   // If cube was stuck for more than 10 loops,
                    if (intendedDir == 2 || intendedDir == 4) {
                        if ((int)random(10) < 5) { dir = 1; } else { dir = 3; }    
                    } else if (intendedDir == 1 || intendedDir == 3) {
                        if ((int)random(10) < 5) { dir = 2; } else { dir = 4; }    
                    } else {
                        dir = (int)random(4) + 1;
                    }
                    upDown = checkSpace();
                    stuckCount = 0;               
                }
                if (dir == 0) { 
                    stuckCount++; 
                    
                } // Cube didn't go anywhere this update turn
                
                // After direction logic, direction decided
                if (moving) {
                    switch (dir) {               
                        case 1:
                            if (moving) moveNorth();
                            break;
                        case 2:                        
                            if (moving) moveEast();
                            break;
                        case 3:
                            if (moving) moveSouth();
                            break;
                        case 4:
                            if (moving) moveWest();
                            break;
                    }
                } else {
                    translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length / 2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                }                
                break;
    
            case 1: // Climbing phase
                r = 110;
                g = 110;
                b = 240;  

                if (!moving) { 
                    if (cubeModel.inModel(gX, gY, gZ) && gZ == cubeModel.currLevel) { 
                        status = 2;
                        
                        if (countSet() == cubeModel.floors[cubeModel.currLevel]) {
                            if (cubeModel.currLevel < cubeModel.h-1) { 
                                cubeModel.currLevel++;
                                broadcastCount = delay;          
                                broadcastWaveCount = 1; 
                            }             
                        }    
                                          
                        translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length / 2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                        break;
                    } else {
                        climbNext();
                        upDown = checkSpace();                        
                    }                              
                }
  
                if (stuckCount > stuckLimit) {          // If cube was stuck for more than 10 loops,
                    climbNext();
                    upDown = checkSpace();
                    stuckCount = 0;               
                }
                if (dir == 0) { 
                    stuckCount++;                     
                } // Cube didn't go anywhere this update turn              
               
                if (moving) {
                    switch (dir) {               
                        case 1:
                            if (moving) moveNorth();
                            break;
                        case 2:                        
                            if (moving) moveEast();
                            break;
                        case 3:
                            if (moving) moveSouth();
                            break;
                        case 4:
                            if (moving) moveWest();
                            break;
                        }
                } else {
                    translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length / 2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                }                    
                break;
    
            case 2: // Beacon
                r = 240;
                g = 30;
                b = 30;   
                signalBeacon();                
                updateSpacesToFill();                
                broadcast();
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length / 2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));   
                break;    
       
            case 3: // Self-set
                r = 0;
                g = 180;
                b = 0;
                signalBeacon();
                broadcast();                
                updateSpacesToFill();                    
                
                if (status == 3) { setDirectionPointer(); }                      
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length / 2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                break;
    
            case 4: // Done
                r = 150;
                g = 150;
                b = 150;
                                          
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length / 2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                break;
        }        
        
        strokeWeight(0.1);          

        // Render cube
        scale(10);

        beginShape(QUADS);

        fill(r, g, b);
        vertex(-1 + changeX, 1 + changeY, 1 + changeZ);
        vertex( 1 + changeX, 1 + changeY, 1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, 1 + changeZ);
        vertex(-1 + changeX, -1 + changeY, 1 + changeZ);

        vertex( 1 + changeX, 1 + changeY, 1 + changeZ);
        vertex( 1 + changeX, 1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, 1 + changeZ);

        vertex( 1 + changeX, 1 + changeY, -1 + changeZ);
        vertex(-1 + changeX, 1 + changeY, -1 + changeZ);
        vertex(-1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, -1 + changeZ);

        vertex(-1 + changeX, 1 + changeY, -1 + changeZ);
        vertex(-1 + changeX, 1 + changeY, 1 + changeZ);
        vertex(-1 + changeX, -1 + changeY, 1 + changeZ);
        vertex(-1 + changeX, -1 + changeY, -1 + changeZ);

        vertex(-1 + changeX, 1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, 1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, 1 + changeY, 1 + changeZ);
        vertex(-1 + changeX, 1 + changeY, 1 + changeZ);

        vertex(-1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, -1 + changeZ);
        vertex( 1 + changeX, -1 + changeY, 1 + changeZ);
        vertex(-1 + changeX, -1 + changeY, 1 + changeZ);

        endShape();
        popMatrix();
        prevDir = dir;
    }

    void changeDir(int direction) {
        if (!moving) {
            this.dir = direction;
        }
    }    

    void moveRandom() {   
        if (!moving) dir = (int)random(4) + 1;
    }

    // Function decides whether it needs to go up, down or straight.
    // If return value is 0, just go straight
    // If > 0, go up that many spaces
    // If < 0, go down that many spaces : CHSPACE
    int checkSpace () {
        if (moving || prevDir == 0 || dir == 0) { 
            return upDown;
        } // We're still moving, or not moving at all

        int modX = 0;
        int modY = 0;    
        int count = 0;

        moving = true; 

        switch (dir) {
        case 1: // - North
            modX = 0;
            modY = -1;                
            break;
        case 2: // - East  
            modX = 1;
            modY = 0;                
            break; 
        case 3: // - South
            modX = 0;
            modY = 1;                
            break;
        case 4: // - West
            modX = -1;
            modY = 0;                
            break;
        }

        // Check if within world boundaries
        if (gX + modX >= worldSize || gX + modX < 0 ||  gY + modY >= worldSize || gY + modY < 0 || gZ < 0) { 
            dir = 0;
            moving = false;
            return 0;
        }
        
        // Check if there is a non-set cube in the way (this is mostly for testing, to keep the program smooth)
        if (status < 2 && cubeAt(gX + modX, gY + modY, gZ) != null && cubeAt(gX + modX, gY + modY, gZ).status < 2) {
            moving = false;
            this.dir = 0;
            return 0;
        }

        // If cube isn't going to be attached to another cube or the ground, can't move there
        if (cubeAt(gX + modX - 1, gY + modY, gZ) == null &&
            cubeAt(gX + modX + 1, gY + modY, gZ) == null &&
            cubeAt(gX + modX, gY + modY - 1, gZ) == null &&
            cubeAt(gX + modX, gY + modY + 1, gZ) == null &&
            cubeAt(gX + modX, gY + modY, gZ - 1) == null &&
            cubeAt(gX + modX, gY + modY, gZ + 1) == null) {
            dir = 0;
            moving = false;            
            return 0;
        }
       
        
       
        boolean hasDir = false;
        
        if (status == 0 && gZ == 0 && cubeAt(gX + modX, gY + modY, gZ) == null) { // on ground      
        //if (gZ == 0 && cubeAt(gX + modX, gY + modY, gZ) == null) { // on ground                
            if (status < 2 && (cubeAt(gX + modX, gY + modY, gZ-1) != null && cubeAt(gX + modX, gY + modY, gZ-1).status < 2)) {
                moving = false;
                this.dir = 0;
                return 0;
            }
                   
            space[gX + modX][gY + modY][gZ].add(0, this);            
            hasDir = true;
        } 
        if (!hasDir) { // WENSBT            
            switch (beaconPos) {        
                case 5:
                    if (!hasDir && cubeAt(gX, gY, gZ+1) != null && cubeAt(gX, gY, gZ+1).status > 1) { // Wall is ceiling
                        if (cubeAt(gX + modX, gY + modY, gZ+1) == null) {
                            swingTB = 5;
                            space[gX + modX][gY + modY][gZ+1].add(0, this);
                            hasDir = true;
                        } else if (cubeAt(gX+modX, gY+modY, gZ) == null && cubeAt(gX + modX, gY + modY, gZ+1).status > 1) {
                            swingTB = -5;
                            space[gX + modX][gY + modY][gZ].add(0, this);     
                            hasDir = true;
                        }  
                    }
                    break;
                
                case 4:
                    if (!hasDir && cubeAt(gX, gY, gZ-1) != null && cubeAt(gX, gY, gZ-1).status > 1) { // Wall is floor
                        // Swing around corner
                        if (cubeAt(gX + modX, gY + modY, gZ-1) == null) {
                            swingTB = 6;
                            space[gX + modX][gY + modY][gZ-1].add(0, this);
                            hasDir = true;
                        } else if (cubeAt(gX + modX, gY + modY, gZ) == null && cubeAt(gX + modX, gY + modY, gZ-1).status > 1) {
                            swingTB = -6;
                            space[gX + modX][gY + modY][gZ].add(0, this);    
                            hasDir = true; 
                        }  
                    }
                    break;
                
                case 0:
                    if (!hasDir && cubeAt(gX-1, gY, gZ) != null && cubeAt(gX-1, gY, gZ).status > 1) {  // Wall is to the west            
                        if (dir == 2 || dir == 4) {
                            // Swing around corner
                            if (gZ-modX >= 0 && cubeAt(gX - 1, gY, gZ-modX) == null) {
                                swingTB = 4;
                                space[gX - 1][gY][gZ-modX].add(0, this);
                                hasDir = true;
                            } else if (gZ-modX >= 0 && cubeAt(gX,gY,gZ-modX) == null && cubeAt(gX - 1, gY, gZ-modX).status > 1){
                                swingTB = -4;
                                space[gX][gY][gZ-modX].add(0, this);     
                                hasDir = true;
                            }
                        } else {
                            if (cubeAt(gX + modX - 1, gY + modY, gZ) == null) {
                                swingLR = 4;
                                space[gX + modX - 1][gY + modY][gZ].add(0, this);
                                hasDir = true;
                            } else if (cubeAt(gX + modX, gY + modY, gZ) == null && cubeAt(gX + modX - 1, gY + modY, gZ).status > 1) {
                                swingLR = -4;
                                space[gX + modX][gY + modY][gZ].add(0, this);   
                                hasDir = true;  
                            } 
                        }                               
                    }
                    break;
                   
                case 1:
                    if (!hasDir && cubeAt(gX+1, gY, gZ) != null && cubeAt(gX+1, gY, gZ).status > 1) {  // Wall is to the east        
                        if (dir == 2 || dir == 4) {
                            // Swing around corner
                            if (gZ+modX >= 0 && cubeAt(gX+1, gY, gZ+modX) == null) {
                                swingTB = 2;
                                space[gX+1][gY][gZ+modX].add(0, this);
                                hasDir = true;
                            } else if (gZ+modX >= 0 && cubeAt(gX, gY, gZ+modX) == null && cubeAt(gX+1, gY, gZ+modX).status > 1) {
                                swingTB = -2;
                                space[gX][gY][gZ+modX].add(0, this);     
                                hasDir = true;
                            }
                        } else {
                            if (cubeAt(gX + modX + 1, gY + modY, gZ) == null) {
                                swingLR = 2;
                                space[gX + modX + 1][gY + modY][gZ].add(0, this);
                                hasDir = true;
                            } else if (cubeAt(gX + modX, gY+modY, gZ) == null && cubeAt(gX + modX + 1, gY + modY, gZ).status > 1) {
                                swingLR = -2;
                                space[gX + modX][gY + modY][gZ].add(0, this);    
                                hasDir = true; 
                            } 
                        }     
                    }
                    break;
                
                case 2:
                    if (!hasDir && cubeAt(gX, gY-1, gZ) != null && cubeAt(gX, gY-1, gZ).status > 1) {  // Wall is to the north
                        // Swing around corner
                        if (dir == 1 || dir == 3) {
                           if (gZ-modY >=0 && cubeAt(gX, gY-1, gZ-modY) == null) {
                               swingTB = 1;
                               space[gX][gY-1][gZ-modY].add(0, this);
                               hasDir = true;
                           } else if (gZ-modY >= 0 && cubeAt(gX, gY, gZ-modY) == null && cubeAt(gX, gY-1, gZ-modY).status > 1) {
                               swingTB = -1;
                               space[gX][gY][gZ-modY].add(0, this);     
                               hasDir = true;
                           } 
                        } else {
                            if (cubeAt(gX + modX, gY - 1, gZ) == null) {
                                swingLR = 1;
                                space[gX + modX][gY - 1][gZ].add(0, this);
                                hasDir = true;
                            } else if (cubeAt(gX + modX, gY, gZ) == null && cubeAt(gX + modX, gY - 1, gZ).status > 1) {
                                swingLR = -1;
                                space[gX + modX][gY][gZ].add(0, this);  
                                hasDir = true;   
                            }
                        }                    
                    }
                    break;
                    
                case 3:
                    if (!hasDir && cubeAt(gX, gY+1, gZ) != null && cubeAt(gX, gY+1, gZ).status > 1) {  // Wall is to the south            
                        if (dir == 1 || dir == 3) {
                            // Swing around corner
                            if (gZ+modY >= 0 && cubeAt(gX, gY+1, gZ+modY) == null) {
                                swingTB = 3;
                                space[gX][gY+1][gZ+modY].add(0, this);
                                hasDir = true;
                            } else if (gZ+modY >= 0 && cubeAt(gX,gY,gZ+modY) == null && cubeAt(gX, gY+1, gZ+modY).status > 1) {
                                swingTB = -3;
                                space[gX][gY][gZ+modY].add(0, this);     
                                hasDir = true;
                            }
                        } else {
                            if (cubeAt(gX + modX, gY+1, gZ) == null) {
                                swingLR = 3;
                                space[gX + modX][gY+1][gZ].add(0, this);
                                hasDir = true;
                            } else if (cubeAt(gX + modX, gY, gZ) == null && cubeAt(gX + modX, gY+1, gZ).status > 1) {
                                swingLR = -3;
                                space[gX + modX][gY][gZ].add(0, this);     
                                hasDir = true;
                            }
                        }
                         
                    }
                    break;            
            }       
        }
        
        if (!hasDir) {
            moving = false;
            this.dir = (int)random(4) + 1;
            return 0;
        }
        
        return count;
    }

    void moveEast() {
        
        prevX = gX;
        prevY = gY;
        prevZ = gZ;
        
        changeX = -1;
        changeY = 1;
        transX = cubeWidth;
        transY = 0;

        float flopAngle;
        if (swingLR == 0 && swingTB == 0) {
            translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
            if (turnOver < HALF_PI) {            
                rotateY(turnOver); //x must be reverse
                turnOver += moveSpeed; // acceleration     

                // Finish moving
            } else {
                rotateY(HALF_PI);
                gX++;
                turnOver = 0;
                prevDir = 0;
                dir = 0;
                moving = false;
                space[prevX][prevY][prevZ].clear();
                return;
            }
        } else {
            if (swingTB == 4 || swingTB == -4) {
                changeX = 1;
                changeY = 1;
                transX = 0;
                transY = 0;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingTB == 4) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateY(turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(flopAngle);
                    gZ--;
                    if (swingTB > 0) { gX--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 2 || swingTB == -2) {
                changeZ = -1;
                transZ = cubeWidth;                
                //changeX = 1;
                //transX = 0;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 2) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateY(turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(flopAngle);
                    gZ++;
                    if (swingTB > 0) { gX++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 5 || swingTB == -5) {
                changeZ = -1;
                transZ = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 5) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateY(turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(flopAngle);
                    gX++;
                    if (swingTB > 0) { gZ++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            } else if (swingTB == 6 || swingTB == -6) {
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 6) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateY(-turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(-flopAngle);
                    gX++;
                    if (swingTB > 0) { gZ--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            } 
            
            if (swingLR == 1 || swingLR == -1) {
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 1) { flopAngle = PI; } else { flopAngle = HALF_PI; }
                
                if (turnOver < flopAngle) {            
                    rotateZ(-turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(-flopAngle);
                    gX++;
                    if (swingLR > 0) { gY--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingLR == 3 || swingLR == -3) {
                changeX = -1;
                changeY = -1;
                transX = cubeWidth;
                transY = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 3) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateZ(-turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(-flopAngle);
                    gX++;
                    if (swingLR > 0) { gY++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            }
        }
    }

    void moveWest() {
   
        prevX = gX;
        prevY = gY;
        prevZ = gZ;
        
        changeX = 1;
        changeY = 1;
        transX = 0;
        transY = 0;

        float flopAngle;

        
        if (swingLR == 0 && swingTB == 0) {
            translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
            if (turnOver < HALF_PI) {            
                rotateY(-turnOver); //x must be reverse
                turnOver += moveSpeed; // acceleration     

                // Finish moving
            } else {
                rotateY(-HALF_PI);
                gX--;
                turnOver = 0;
                prevDir = 0;
                dir = 0;
                moving = false;
                space[prevX][prevY][prevZ].clear();
                return;
            }
        } else {      
            if (swingTB == 2 || swingTB == -2) {
                changeX = -1;
                changeY = 1;
                transX = cubeWidth;
                transY = 0;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingTB == 2) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateY(-turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(-flopAngle);
                    gZ--;
                    if (swingTB > 0) { gX++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 4 || swingTB == -4) {
                changeZ = -1;
                //changeY = 1;
                transZ = cubeWidth;
                //transY = 0;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 4) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateY(-turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(-flopAngle);
                    gZ++;
                    if (swingTB > 0) { gX--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 5 || swingTB == -5) {
                changeZ = -1;
                transZ = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 5) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateY(-turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(-flopAngle);
                    gX--;
                    if (swingTB > 0) { gZ++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            } else if (swingTB == 6 || swingTB == -6) {

                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 6) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateY(turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateY(flopAngle);
                    gX--;
                    if (swingTB > 0) { gZ--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            }
            
            if (swingLR == 1 || swingLR == -1) {
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 1) { flopAngle = PI; } else { flopAngle = HALF_PI; }
                
                if (turnOver < flopAngle) {            
                    rotateZ(turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(flopAngle);
                    gX--;
                    if (swingLR > 0) { gY--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingLR == 3 || swingLR == -3) {
                changeX = 1;
                changeY = -1;
                transX = 0;
                transY = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 3) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateZ(turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(flopAngle);
                    gX--;
                    if (swingLR > 0) { gY++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                    
            }
        }
    }

    void moveSouth() {     
        
        prevX = gX;
        prevY = gY;
        prevZ = gZ;
        
        changeX = 1;
        changeY = -1;
        transX = 0;
        transY = cubeWidth;

        float flopAngle;

        if (swingLR == 0 && swingTB == 0) {
            translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
            if (turnOver < HALF_PI) {            
                rotateX(-turnOver); //x must be reverse
                turnOver += moveSpeed; // acceleration     

                // Finish moving
            } else {
                rotateX(-HALF_PI);
                gY++;
                turnOver = 0;
                prevDir = 0;
                dir = 0;
                moving = false;
                space[prevX][prevY][prevZ].clear();
                return;
            }
        } else {       
            if (swingTB == 1 || swingTB == -1) {
                changeX = 1;
                changeY = 1;
                transX = 0;
                transY = 0;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingTB == 1) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateX(-turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(-flopAngle);
                    gZ--;
                    if (swingTB > 0) { gY--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 3 || swingTB == -3) {
                changeZ = -1;
                transZ = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 3) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateX(-turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(-flopAngle);
                    gZ++;
                    if (swingTB > 0) { gY++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 5 || swingTB == -5) {
                changeZ = -1;
                transZ = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 5) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateX(-turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(-flopAngle);
                    gY++;
                    if (swingTB > 0) { gZ++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            } else if (swingTB == 6 || swingTB == -6) {
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 6) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateX(turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(flopAngle);
                    gY++;
                    if (swingTB > 0) { gZ--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            }
            
            if (swingLR == 2 || swingLR == -2) {
                changeX = -1;
                changeY = -1;
                transX = cubeWidth;
                transY = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 2) { flopAngle = PI; } else { flopAngle = HALF_PI; }
                
                if (turnOver < flopAngle) {            
                    rotateZ(-turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(-flopAngle);
                    gY++;
                    if (swingLR > 0) { gX++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingLR == 4 || swingLR == -4) {
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 4) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateZ(-turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(-flopAngle);
                    gY++;
                    if (swingLR > 0) { gX--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                    
            }
        }
    }

    void moveNorth() {     
        
        prevX = gX;
        prevY = gY;
        prevZ = gZ;
        
        changeX = 1;
        changeY = 1;
        transX = 0;
        transY = 0;

        float flopAngle;
                 
        if (swingLR == 0 && swingTB == 0) {
            translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
            if (turnOver < HALF_PI) {            
                rotateX(turnOver); //x must be reverse
                turnOver += moveSpeed; // acceleration     

                // Finish moving
            } else {
                rotateX(HALF_PI);
                gY--;
                turnOver = 0;
                prevDir = 0;
                dir = 0;
                moving = false;
                space[prevX][prevY][prevZ].clear();
                return;
            }
        } else {  
            if (swingTB == 3 || swingTB == -3) {
                changeX = 1;
                changeY = -1;
                transX = 0;
                transY = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingTB == 3) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateX(turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(flopAngle);
                    gZ--;
                    if (swingTB > 0) { gY++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 1 || swingTB == -1) {
                changeZ = -1;
                transZ = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 1) { flopAngle = PI; } else { flopAngle = HALF_PI; }

                if (turnOver < flopAngle) {            
                    rotateX(turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(flopAngle);
                    gZ++;
                    if (swingTB > 0) { gY--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingTB == 5 || swingTB == -5) {
                changeZ = -1;
                transZ = cubeWidth;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 5) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateX(turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(flopAngle);
                    gY--;
                    if (swingTB > 0) { gZ++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            } else if (swingTB == 6 || swingTB == -6) {
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth) + transZ);
                if (swingTB == 6) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateX(-turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateX(-flopAngle);
                    gY--;
                    if (swingTB > 0) { gZ--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingTB = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                   
            } 
            
            if (swingLR == 2 || swingLR == -2) {
                changeX = -1;
                changeY = 1;
                transX = cubeWidth;
                transY = 0;
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 2) { flopAngle = PI; } else { flopAngle = HALF_PI; }
                
                if (turnOver < flopAngle) {            
                    rotateZ(turnOver); //x must be reverse
                    turnOver += moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(flopAngle);
                    gY--;
                    if (swingLR > 0) { gX++; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }
            } else if (swingLR == 4 || swingLR == -4) {
                translate(-(cubeWidth * (space.length / 2)) +(gX * cubeWidth) + transX, -(cubeWidth * (space[0].length/2)) +(gY * cubeWidth) + transY, (gZ * cubeWidth));
                if (swingLR == 4) { flopAngle = -PI; } else { flopAngle = -HALF_PI; }
                
                if (turnOver > flopAngle) {            
                    rotateZ(turnOver); //x must be reverse
                    turnOver -= moveSpeed; // acceleration     
    
                    // Finish moving
                } else {
                    rotateZ(flopAngle);
                    gY--;
                    if (swingLR > 0) { gX--; }
                    turnOver = 0;
                    prevDir = 0;
                    dir = 0;
                    moving = false;
                    swingLR = 0;
                    space[prevX][prevY][prevZ].clear();
                    return;
                }                    
            }
        }        
    }
}
    
