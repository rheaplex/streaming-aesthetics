
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
    return innerDiameter() > sizeMax;
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
  
  // https://secure.wikimedia.org/wikipedia/en/wiki/Apothem
  float innerDiameter () {
   return (diameter * cos(PI / sides));
  }
  
  void setSizeFromInnerDiameter (float value) {
      diameter = value / cos(PI / sides);
  }
}

class Triangle extends Polygon {
  Triangle () {
    sides = 3;
  }
  
  void draw () {
    polygon(3, 0, 0, diameter, diameter, radians(30));
    /*stroke(0,0,255);
    ellipseMode(CENTER);
    ellipse(0, 0, diameter, diameter);
    stroke(0,0,0);
    stroke(255,0,0);
    ellipseMode(CENTER);
    ellipse(0, 0, innerDiameter(), innerDiameter());
    stroke(0,0,0);*/
  }
}

class Cross extends Shape {
  void draw () {
    float half = diameter / 2.0;
    float quarter = diameter / 4.0;
    beginShape();
    vertex(-quarter, half);
    vertex(quarter, half);
    vertex(quarter, quarter);
    vertex(half, quarter);
    vertex(half, -quarter);
    vertex(quarter, -quarter);
    vertex(quarter, -half);
    vertex(-quarter, -half);
    vertex(-quarter, -quarter);
    vertex(-half, -quarter);
    vertex(-half, quarter);
    vertex(-quarter, quarter);
    vertex(-quarter, half);
    endShape();
    stroke(0,0,255);
    ellipseMode(CENTER);
    ellipse(0, 0, diameter, diameter);
    stroke(0,0,0);
    stroke(255,0,0);
    ellipseMode(CENTER);
    ellipse(0, 0, innerDiameter(), innerDiameter());
    stroke(0,0,0);
  }
  
  float innerDiameter () {
    return sqrt((diameter * (diameter / 2)));
  }
}

/*
class Arrow extends Shape {
  void draw () {
    beginShape();
    vertex(shapeSize / 2.0, 0.0);
    vertex(shapeSize, shapeSize / 1.6);
    vertex(shapeSize * 0.6666, shapeSize / 1.6);
    vertex(shapeSize * 0.6666, shapeSize);
    vertex(shapeSize * 0.3333, shapeSize);
    vertex(shapeSize * 0.3333, shapeSize / 1.6);
    vertex(0.0, shapeSize / 1.6);
    vertex(shapeSize / 2.0, 0.0);
    endShape();
  }
}

class Rectangle extends Shape {
  void draw () {
    rectMode(CENTER);
    rect(0, 0, shapeSize * 1.5, shapeSize * 0.75);
  }
}

class Oval extends Shape {
  void draw () {
    ellipseMode(CENTER);
    ellipse(0, 0, shapeSize * 1.5, shapeSize * 0.75);
  }
}

class Crescent extends Shape {
  void draw () {
    float threeQuarters = shapeSize * 0.75;
    float oneAndAQuarter = shapeSize * 1.27; // misnomer
    beginShape();
    vertex(0.0, 0.0);
    bezierVertex(oneAndAQuarter, 0.0, oneAndAQuarter, shapeSize, 0.0,
                 shapeSize);
    bezierVertex(threeQuarters, shapeSize, threeQuarters, 0.0, 0.0, 0.0);
    endShape();
  }
}
*/

// Make the appropriate shape

Shape makeShape(String name) {
  Shape shape = null;
  if(name == "circle") {
    shape = new Circle();
  } else if (name == "square") {
    shape = new Square();
  } else if (name == "triangle") {
    shape = new Triangle();
  } else if (name == "star") {
    shape = new Star();
  }else if (name == "cross") {
    shape = new Cross();
  }/* else if (name == "rectangle") {
    shape = new Rectangle();
  } else if (name == "oval") {
    shape = new Oval();
  } else if (name == "crescent") {
    shape = new Crescent();
  }*/
  return shape;
}

