int agentLimit = 20000;
float sensorDistance = 6;
int scentStrength = 40;
int sensorSize = 1;
int senseAngle = 10;
ArrayList<Agent> agents;
ArrayList<FloatList> trailMap;
int turnStrength = 50;
float agentSpeed = 8.0;
boolean speedChanged = false;
int fadeRate = 100; 
int numThreads = 20;
float decayRate = .95;

void setup() {
  size(640, 360);
  //fullScreen();
  background(0);
  noStroke();
  fill(0, 102);
  noSmooth();
  stroke(10);
  setupTrailMap();
  setupAgents();
  strokeWeight(1);
  //frameRate(1);
}

void draw() {
  if (keyPressed) {
    if (key == 'q') {
      agentSpeed += 0.25;
      speedChanged = true;
    } else if (key == 'w') {
      agentSpeed -= 0.25;
      speedChanged = true;
    } else if (key == 'a') {
      turnStrength += 5;
    } else if (key == 's') {
      turnStrength -= 5;  
    } else if (key == 'z') {
      scentStrength += 10;
    } else if (key == 'x') {
      scentStrength -= 10;  
    } else if (key == 'e') {
      senseAngle += 0.01;
    } else if (key == 'r') {
      senseAngle -= 0.01;  
    } else if (key == 'c') {
      fadeRate += 5;
    } else if (key == 'v') {
      fadeRate -= 5;  
    } else if (key == 'o') {
      numThreads += 1;
    } else if (key == 'p') {
      numThreads -= 1;  
    } 
    
  } 
  color c = color(0, 0, 0, fadeRate);
  fill(c);
  rect(0,0,width,height);
  stroke(color(255));
  
  int agentsPerThread = agents.size() / numThreads;
  ArrayList<Thread> threads = new ArrayList<Thread>();
  for (int t = 0; t < numThreads; t++) {
    Thread newThread = new Thread(new AgentProcessor(t * agentsPerThread, agentsPerThread));
    threads.add(newThread);
  }
  try {
    for (int t = 0; t < threads.size(); t++) {
      threads.get(t).start();
    }
    for (int t = 0; t < threads.size(); t++) {
      threads.get(t).join();
    }
  } catch (InterruptedException e) {
      
  }
  
  //processAgents();
  processTrailMap();
  drawAgents(); //<>//
  //saveFrame();
}

void setupAgents() {
  agents = new ArrayList<Agent>();
  float centerX = width/2;
  float centerY = height/2;
  for (int i = 0; i < agentLimit; i++) {
    float y = random(height/4, (height/4)*3);
    float x = random(width/4, (width/4)*3);
    //float y = random(0, height);
    //float x = random(0, width);
    float angle = atan2((centerY - y), (centerX - x));
    if (angle < 0) {
      angle += 360;  
    }
    //float angle = random(0, 360);
    Agent agent = new Agent(x, y, angle, agentSpeed);
    agents.add(agent);  
  }
}

void processAgents() {
  for (int i = 0; i < agents.size(); i++) {
    Agent agent = agents.get(i);
    if (speedChanged) {
      agent.speed = agentSpeed;  
    }
    float oldX = agent.x;
    float oldY = agent.y;
    if (!(agent.x < 0 || agent.x > width - 1 || agent.y < 0 || agent.y > height -1)) {
      float currentVal = trailMap.get(int(agent.y)).get(int(agent.x));
      trailMap.get(int(agent.y)).set(int(agent.x), currentVal + scentStrength);  
    }
    float newX = agent.x + cos(degrees(agent.angle)) * agent.speed;
    float newY = agent.y + sin(degrees(agent.angle)) * agent.speed;
    agent.x = newX;
    agent.y = newY;
    if (agent.x < 0 || agent.x > width) {
      agent.angle -= 90;
    }
    if (agent.y < 0 || agent.y > height) {
      agent.angle = -agent.angle;  
    }
    float straight = agent.sense(0);
    float left = agent.sense(-senseAngle);
    float right = agent.sense(senseAngle);
    if (straight > left && straight > right) {
      //Do Nothing
    } else if (left > right) {
      agent.angle += radians(-random(turnStrength, turnStrength + 10)/100);
    } else if (right > left) {
      agent.angle += radians(random(turnStrength, turnStrength + 10)/100);  
    }
    //agent.angle += radians(random(-2, 2)/100);
    //stroke(color(min((left + right + straight)/2,200), (left + right + straight)/2, (left + right + straight)/2));
    line(oldX, oldY, agent.x, agent.y);
  }
  speedChanged = false;
}

void drawAgents() {
  noSmooth();
  stroke(255);
  for (int i = 0; i < agents.size(); i++) {
      Agent agent = agents.get(i);
      line(agent.oldX, agent.oldY, agent.x, agent.y);
  }
}

void setupTrailMap() {
  trailMap = new ArrayList<FloatList>(height);
  for (int y = 0; y < height; y++) {
    FloatList row = new FloatList(width);
    trailMap.add(row); //<>//
    for (int x = 0; x < width; x++) {
        row.set(x, 0);
    }
  }
}

void processTrailMap() {
  stroke(255);
  for (int y = 0; y < height; y++) {
    FloatList row = trailMap.get(y);
    for (int x = 0; x < width; x++) {
      //float currentVal = row.get(x);
      //stroke(currentVal * 10);
      //if (currentVal > 0) {
        //point(x, y);
      //}
      float sum = 0;
      int processed = 0;
      for (int xOffset = -1; xOffset <= 1; xOffset++) {
        for (int yOffset = -1; yOffset <= 1; yOffset++) {
          if (x + xOffset < 0 || x + xOffset > width - 1 || y + yOffset < 0 || y + yOffset > height - 1) {
            continue;
          }
          sum += trailMap.get(y + yOffset).get(x + xOffset);
          processed++;
        }
      }
      row.set(x, max(0, sum / processed * decayRate));
    }
  }
}

class Agent {
  float x;
  float y;
  float angle;
  float speed;
  float oldX;
  float oldY;
  
  public Agent(float x, float y, float angle, float speed) {
    this.x = x;
    this.y = y;
    this.angle = angle;
    this.speed = speed; 
    this.oldX = x;
    this.oldY = y;
  }
  
  public float sense(float angleOffset) {
    float sensorAngle = this.angle + angleOffset;
    float sensorDirX = cos(degrees(sensorAngle));
    float sensorDirY = sin(degrees(sensorAngle));
    float sensorCenterX = this.x + sensorDirX * sensorDistance;
    float sensorCenterY = this.y + sensorDirY * sensorDistance;
    //rect(sensorCenterX, sensorCenterY, 3, 3);
    int sum = 0;
    for (int offsetX = -sensorSize; offsetX <= sensorSize; offsetX++) {
      for (int offsetY = -sensorSize; offsetY <= sensorSize; offsetY++) {
        int targetX = int(sensorCenterX) + offsetX;
        int targetY = int(sensorCenterY) + offsetY;
        if (targetX < 0 || targetX > width -1 || targetY < 0 || targetY > height - 1) {
          continue;
        }
        sum += trailMap.get(targetY).get(targetX);    
      }
    }
    return sum;
  }
}

public class AgentProcessor implements Runnable {
  
  int startIndex;
  int range;
  public AgentProcessor(int startIndex, int range) {
    this.startIndex = startIndex;
    this.range = range;
  }
  
  @Override
  public void run() {
      for (int i = startIndex; i < startIndex + range; i++) {
        Agent agent = agents.get(i);
        processAgent(agent);
      }
  }
  
  
  private void processAgent(Agent agent) {
    if (speedChanged) {
      agent.speed = agentSpeed;  
    }
    agent.oldX = agent.x;
    agent.oldY = agent.y;
    if (!(agent.x < 0 || agent.x > width - 1 || agent.y < 0 || agent.y > height -1)) {
      float currentVal = trailMap.get(int(agent.y)).get(int(agent.x));
      trailMap.get(int(agent.y)).set(int(agent.x), currentVal + scentStrength);  
    }
    float newX = agent.x + cos(degrees(agent.angle)) * agent.speed;
    float newY = agent.y + sin(degrees(agent.angle)) * agent.speed;
    agent.x = newX;
    agent.y = newY;
    if (agent.x < 0 || agent.x > width) {
      agent.angle -= 90;
    }
    if (agent.y < 0 || agent.y > height) {
      agent.angle = -agent.angle;  
    }
    float straight = agent.sense(0);
    float left = agent.sense(-senseAngle);
    float right = agent.sense(senseAngle);
    if (straight > left && straight > right) {
      //Do Nothing
    } else if (left > right && left > straight) {
      agent.angle += radians(-random(turnStrength, turnStrength + 10)/100);
    } else if (right > left && right > straight) {
      agent.angle += radians(random(turnStrength, turnStrength + 10)/100);  
    } else if (left > straight && right > straight) {
        agent.angle += radians(random(-2, 2)/100);
    }
    //agent.angle += radians(random(-2, 2)/100);
    //stroke(color(min((left + right + straight)/2,200), (left + right + straight)/2, (left + right + straight)/2));
    //line(oldX, oldY, agent.x, agent.y);
  }
}
