import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.joints.*;

Box2DProcessing box2d;
ArrayList<SpaceCreature> creatures = new ArrayList<>();
MouseJoint mouseJoint;
ArrayList<Star> stars = new ArrayList<>();
float time = 0;

void setup() {
  size(1000, 600);
  //fullScreen();
  smooth();
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -10); // Reduced gravity for space-like feel
  createBoundaries();
  
  // Create starfield
  for (int i = 0; i < 100; i++) {
    stars.add(new Star());
  }

  // Spawn initial space creatures
  for (int i = 0; i < 8; i++) {
    creatures.add(new SpaceCreature(random(width), random(50, height - 50)));
  }
}

void draw() {
  background(10, 5, 30); // Deep space background
  time += 0.02;
  
  // Draw animated starfield
  for (Star star : stars) {
    star.update();
    star.display();
  }
  
  // Draw nebula-like effects
  drawNebula();
  
  box2d.step();
  displayBoundaries();

  // Display all space creatures
  for (SpaceCreature creature : creatures) {
    creature.display();
  }
}

void drawNebula() {
  noStroke();
  for (int i = 0; i < 5; i++) {
    float x = width/2 + cos(time + i) * 200;
    float y = height/2 + sin(time * 0.5 + i) * 100;
    fill(70, 130, 180, 20);
    ellipse(x, y, 300, 300);
    fill(147, 112, 219, 15);
    ellipse(x + 50, y - 50, 200, 200);
  }
}

class Star {
  float x, y, z;
  float pz;
  
  Star() {
    x = random(-width/2, width/2);
    y = random(-height/2, height/2);
    z = random(width);
    pz = z;
  }
  
  void update() {
    z = z - 10;
    if (z < 1) {
      z = width;
      x = random(-width/2, width/2);
      y = random(-height/2, height/2);
      pz = z;
    }
  }
  
  void display() {
    fill(255);
    noStroke();
    
    float sx = map(x / z, 0, 1, 0, width);
    float sy = map(y / z, 0, 1, 0, height);
    float r = map(z, 0, width, 4, 0);
    
    float px = map(x / pz, 0, 1, 0, width);
    float py = map(y / pz, 0, 1, 0, height);
    
    stroke(255);
    line(px, py, sx, sy);
  }
}

void createBoundaries() {
  float[][] boundaryData = {
    {width/2, height-10, width, 20},    // floor
    {10, height/2, 20, height},         // left wall
    {width-10, height/2, 20, height},   // right wall
    {width/2, 10, width, 20}            // ceiling
  };
  
  for (float[] data : boundaryData) {
    BodyDef bd = new BodyDef();
    bd.type = BodyType.STATIC;
    bd.position.set(box2d.coordPixelsToWorld(data[0], data[1]));
    Body boundary = box2d.createBody(bd);
    
    PolygonShape shape = new PolygonShape();
    shape.setAsBox(box2d.scalarPixelsToWorld(data[2]/2), box2d.scalarPixelsToWorld(data[3]/2));
    
    boundary.createFixture(shape, 1);
  }
}

void displayBoundaries() {
  // Draw glowing boundaries
  stroke(0, 150, 255, 150);
  strokeWeight(3);
  noFill();
  rect(0, 0, width, height);
  
  // Draw corner decorations
  drawCornerDecoration(0, 0);
  drawCornerDecoration(width, 0);
  drawCornerDecoration(0, height);
  drawCornerDecoration(width, height);
}

void drawCornerDecoration(float x, float y) {
  pushMatrix();
  translate(x, y);
  stroke(0, 150, 255, 150);
  noFill();
  float size = 40;
  if (x > 0) size *= -1;
  line(0, 0, size, 0);
  line(0, 0, 0, size);
  popMatrix();
}

class SpaceCreature {
  Body core, upperArm1, upperArm2, lowerArm1, lowerArm2;
  RevoluteJoint joint1, joint2, joint3, joint4;
  float glowIntensity;
  color creatureColor;
  
  SpaceCreature(float x, float y) {
    glowIntensity = random(150, 255);
    creatureColor = color(random(100, 255), random(100, 255), random(100, 255));
    createBodyParts(x, y);
    createJoints();
  }

  void createBodyParts(float x, float y) {
    core = createBodyPart(x, y, 40, 40, 2.0);
    upperArm1 = createBodyPart(x - 30, y, 30, 15, 1.0);
    upperArm2 = createBodyPart(x + 30, y, 30, 15, 1.0);
    lowerArm1 = createBodyPart(x - 60, y, 30, 15, 0.5);
    lowerArm2 = createBodyPart(x + 60, y, 30, 15, 0.5);
  }

  Body createBodyPart(float x, float y, float w, float h, float density) {
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(x, y));
    
    Body body = box2d.createBody(bd);
    PolygonShape shape = new PolygonShape();
    shape.setAsBox(box2d.scalarPixelsToWorld(w/2), box2d.scalarPixelsToWorld(h/2));
    
    FixtureDef fd = new FixtureDef();
    fd.shape = shape;
    fd.density = density;
    fd.friction = 0.3;
    fd.restitution = 0.5;
    
    body.createFixture(fd);
    return body;
  }

  void createJoints() {
    joint1 = createJoint(core, upperArm1, -20);
    joint2 = createJoint(core, upperArm2, 20);
    joint3 = createJoint(upperArm1, lowerArm1, -30);
    joint4 = createJoint(upperArm2, lowerArm2, 30);
  }

  RevoluteJoint createJoint(Body a, Body b, float offset) {
    RevoluteJointDef rjd = new RevoluteJointDef();
    Vec2 anchor = new Vec2(
      a.getPosition().x + box2d.scalarPixelsToWorld(offset),
      a.getPosition().y
    );
    rjd.initialize(a, b, anchor);
    rjd.enableMotor = true;
    rjd.maxMotorTorque = 100;
    rjd.motorSpeed = random(-10, 10);
    return (RevoluteJoint) box2d.world.createJoint(rjd);
  }

  void display() {
    glowIntensity = 150 + abs(sin(time * 2)) * 105;
    
    // Draw all body parts with glow effect
    drawBodyPart(core, 40);
    drawBodyPart(upperArm1, 30);
    drawBodyPart(upperArm2, 30);
    drawBodyPart(lowerArm1, 30);
    drawBodyPart(lowerArm2, 30);
  }

  void drawBodyPart(Body body, float size) {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float angle = body.getAngle();
    
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-angle);
    
    // Draw glow
    for (int i = 3; i > 0; i--) {
      fill(red(creatureColor), green(creatureColor), blue(creatureColor), glowIntensity/(i*2));
      noStroke();
      ellipse(0, 0, size + i*10, size + i*10);
    }
    
    // Draw core
    fill(creatureColor, glowIntensity);
    stroke(255, 150);
    ellipse(0, 0, size, size);
    
    popMatrix();
  }
  
  Body getBodyAtMouse() {
    Vec2 mouseWorld = box2d.coordPixelsToWorld(mouseX, mouseY);
    for (Body b = box2d.world.getBodyList(); b != null; b = b.getNext()) {
      for (Fixture f = b.getFixtureList(); f != null; f = f.getNext()) {
        if (f.testPoint(mouseWorld)) return b;
      }
    }
    return null;
  }
}

// Mouse interaction methods remain the same
void mousePressed() {
  for (SpaceCreature creature : creatures) {
    Body body = creature.getBodyAtMouse();
    if (body != null) {
      MouseJointDef mjd = new MouseJointDef();
      mjd.bodyA = box2d.getGroundBody();
      mjd.bodyB = body;
      Vec2 mousePos = box2d.coordPixelsToWorld(mouseX, mouseY);
      mjd.target.set(mousePos);
      mjd.maxForce = 2000.0 * body.getMass();
      mjd.frequencyHz = 30.0;
      mjd.dampingRatio = 0.5;
      mouseJoint = (MouseJoint) box2d.world.createJoint(mjd);
      break;
    }
  }
}

void mouseDragged() {
  if (mouseJoint != null) {
    Vec2 mousePos = box2d.coordPixelsToWorld(mouseX, mouseY);
    mouseJoint.setTarget(mousePos);
  }
}

void mouseReleased() {
  if (mouseJoint != null) {
    box2d.world.destroyJoint(mouseJoint);
    mouseJoint = null;
  }
}
