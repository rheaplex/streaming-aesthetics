
/*******************************************************************************
  Shape objects
*******************************************************************************/

class Shape {
  float diameter = 1.0;
  
  // The inner points of a star, the centre points of the edges of a rectangle
  // Subclass should override
  float innerDiameter() {
  	return diameter;
  }

  // The outer points of a star, the corners of a rectangle
  // Subclass should override
  float outerDiameter() {
  	return diameter;
  }

  // Scale the shape around its inner diameter
  // Subclass should override
  void setSizeFromInnerDiameter(float innerDiameter) {
       diameter = innerDiameter;
  }
  
  // Scale the shape around its outer diameter
  // Subclass should override
  void setSizeFromOuterDiameter(float outerDiameter) {
       diameter = outerDiameter;
  }

  // Check whether the shape is large enough that another should be added
  // Subclass should override
  boolean largeEnoughToAddMore () {
    return innerDiameter() >= shapeAddSize;
  }

  // Check whether the shape has moved off the drawing area
  // Subclass should override
  boolean largeEnoughToRemove () {
    // Make entirely sure the shape is off the screen
    return innerDiameter() > sizeMax * 2;
  }

  // Implemented by subclasses
  void draw () {}
}

class Circle extends Shape {
  void draw () {
    ellipseMode(CENTER);
    ellipse(0, 0, diameter, diameter);
  }
}

class Square extends Shape {
  void draw () {
    rectMode(CENTER);
    float sideLength = innerDiameter();
    rect(0, 0, sideLength, sideLength);
  }
  
  float innerDiameter () {
    return sqrt((diameter * diameter) / 2);
  }
  
  void setSizeFromInnerDiameter(float innerDiameter) {
       diameter = sqrt((innerDiameter * innerDiameter) * 2);
  }
}

class Star extends Shape {
  protected float innerProportion = 0.45;
  // From http://processing.org/learning/anatomy/
  void star(int n, float cx, float cy, float w, float h, float startAngle,
            float proportion)
  {
    if (n > 2)
    {
      float angle = TWO_PI/ (2 *n);  // twice as many sides
      float dw; // draw width
      float dh; // draw height
    
      w = w / 2.0;
      h = h / 2.0;
    
      beginShape();
      for (int i = 0; i < 2 * n; i++)
      {
        dw = w;
        dh = h;
        if (i % 2 == 1) // for odd vertices, use short diameter
        {
          dw = w * proportion;
          dh = h * proportion;
        }
        vertex(cx + dw * cos(startAngle + angle * i),
               cy + dh * sin(startAngle + angle * i));
      }
      endShape(CLOSE);
    }
  }

  void draw () {
    star(5, 0, 0, diameter, diameter,
         radians(-18), innerProportion);
    /*stroke(0,0,255);
    ellipseMode(CENTER);
    ellipse(0, 0, diameter, diameter);
    stroke(0,0,0);
    stroke(255,0,0);
    ellipseMode(CENTER);
    ellipse(0, 0, innerDiameter(), innerDiameter());
    stroke(0,0,0);*/
  }
  
  // https://secure.wikimedia.org/wikipedia/en/wiki/Apothem
  float innerDiameter () {
   return diameter * innerProportion;
  }
  
  void setSizeFromInnerDiameter (float value) {
      diameter = value / innerProportion;
  }

}

class Polygon extends Shape {
  protected int sides;
  protected float start_angle;
  
  void polygon(int n, float cx, float cy, float w, float h, float startAngle)
  {
    if (n > 2)
    {
      float angle = TWO_PI/ n;
      float dw; // draw width
      float dh; // draw height
    
      w = w / 2.0;
      h = h / 2.0;
    
      beginShape();
      for (int i = 0; i < n; i++)
      {
        dw = w;
        dh = h;
        vertex(cx + dw * cos(startAngle + angle * i),
               cy + dh * sin(startAngle + angle * i));
      }
      endShape(CLOSE);
    }
  }
    
  void draw () {
    polygon(sides, 0, 0, diameter, diameter, radians(start_angle));
    /*stroke(0,0,255);
    ellipseMode(CENTER);
    ellipse(0, 0, diameter, diameter);
    stroke(0,0,0);
    stroke(255,0,0);
    ellipseMode(CENTER);
    ellipse(0, 0, innerDiameter(), innerDiameter());
    stroke(0,0,0);*/
  }
  
  // https://secure.wikimedia.org/wikipedia/en/wiki/Apothem
  float innerDiameter () {
   return diameter * cos(PI / sides);
  }
  
  void setSizeFromInnerDiameter (float value) {
      diameter = value / cos(PI / sides);
  }
}

class Triangle extends Polygon {
  Triangle () {
    sides = 3;
    start_angle = 30;
  }
}

class Pentagon extends Polygon {
  Pentagon () {
    sides = 5;
    start_angle = 55;
  }
}

class Hexagon extends Polygon {
  Hexagon () {
    sides = 6;
    start_angle = 0;
  }
}

class Point {
 float x;
 float y;
 
 Point(float x, float y) {
   this.x = x;
   this.y =y;
 }
}

class Cross extends Shape {
  private static final float side_angle = 60;
  
  Point circlept(float angle) {
    float t = radians(angle);
    float radius = diameter / 2.0;
    return new Point(radius * sin(t), radius * cos(t));
  }
  
  void draw () {
    // Construct the cross using points on the radius
    // top right top
    Point p1 = circlept(0 + (side_angle / 2));
    // right top right
    Point p2 = circlept(90 - (side_angle / 2));
    // bottom bottom left
    Point p3 = circlept(180 + (side_angle / 2));
    // left bottom left
    Point p4 = circlept(270 - (side_angle / 2));
    beginShape();
    vertex(p1.x, p1.y); // .
    vertex(p1.x, p2.y); // |
    vertex(p2.x, p2.y); // -
    vertex(p2.x, p4.y); // |
    vertex(p1.x, p4.y); // -
    vertex(p1.x, p3.y); // |
    vertex(p3.x, p3.y); // -
    vertex(p3.x, p4.y); // |
    vertex(p4.x, p4.y); // _
    vertex(p4.x, p2.y); // |
    vertex(p3.x, p2.y); // -
    vertex(p3.x, p1.y); // |
    vertex(p1.x, p1.y); // -.
    endShape();
    /*stroke(0,0,255);
    ellipseMode(CENTER);
    ellipse(0, 0, diameter, diameter);
    stroke(0,0,0);
    stroke(255,0,0);
    ellipseMode(CENTER);
    ellipse(0, 0, innerDiameter(), innerDiameter());
    stroke(0,0,0);*/
  }
  
  float innerDiameter () {
    // Calculate the x and y of the inside top right point
    // Get distance from inside point to that
    // so sqrt(pow(p1.x, 2) + pow(p2.y, 2));
    // This simplifies to:
    return sqrt(pow(diameter * sin(radians(0 + (side_angle / 2))), 2) + 
                pow(diameter * cos(radians(90 - (side_angle / 2))), 2));
  }
  
  void setSizeFromInnerDiameter (float value) {
      // Nope, no idea. Set arbitrarily for 60 degrees
      // Figure out later...
      diameter = value * 1.4;
  }
}

// Make the appropriate shape

Shape makeShape(String name) {
  Shape shape = null;
  if(name == "circle") {
    shape = new Circle();
  } else if (name == "triangle") {
    shape = new Triangle();
  } else if (name == "square") {
    shape = new Square();
  } else if (name == "pentagon") {
    shape = new Pentagon();
  } else if (name == "hexagon") {
    shape = new Hexagon();
  } else if (name == "star") {
    shape = new Star();
  } else if (name == "cross") {
    shape = new Cross();
  }
  return shape;
}

