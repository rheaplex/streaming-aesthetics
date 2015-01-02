/*  twitter_streaming_aesthetics - Visualise aesthetic terms from Twitter. 
    Copyright (C) 2010, 2011, 2015 Rob Myers<rob@robmyers.org>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


/*******************************************************************************
  Configuration
*******************************************************************************/

// Drawing area size and width
int sizeMax = max(displayWidth, displayHeight);

// How many pixels the shapes should grow each second 
float growth_rate_per_second = 10;
float growth_rate = growth_rate_per_second /1000;


// The list of shapes used in drawing
String[] shapes = {"circle", "triangle", "square", "pentagon", "hexagon"};//, "star", "cross"};

// How thick the lines should be
float lineWidth = 2.9;

// The amount to pad shapes by
float padding = 20.0;

// How big should a shape be before we add another?
float shapeAddSize = padding;

/*******************************************************************************
  Global state
*******************************************************************************/

// The last time we drew
float lastDrawMillis;

float initialSize = 1.0;

/*******************************************************************************
  Setup
*******************************************************************************/

// Make objects Java's syntax doesn't allow us to initialize when we declaer

void initializeData () {
  shapesToAdd = new LinkedList();
  shapesToDraw = new LinkedList();
}

// Set up the window or screen

void initializeDisplay () {
  size(displayWidth, displayHeight);
  sizeMax = max(displayWidth, displayHeight);
  noCursor();
}

// And connect to Twitter

void initializeTwitter () {
  StatusListener listener = createStatusListener();
  createFilteredStream(listener); 
}

// The Processing setup method

void setup () {
  initializeData();
  initializeDisplay();
  initializeTwitter();
  // Set the initial "last drawing time" as late as possible
  lastDrawMillis = millis();
}


/*******************************************************************************
  The list of shapes to draw
*******************************************************************************/

// The shapes to be drawn
LinkedList shapesToDraw;

// Is the first drawn shape large enough to contain another?

boolean firstDrawnShapeIsLargeEnoughToAddMore () {
  return (! shapesToDraw.isEmpty()) &&
         ((Shape)shapesToDraw.peekFirst()).largeEnoughToAddMore();
}

// Should another shape be transferred from the pending list to the draw list?

boolean shouldAddShapes() {
  boolean should = false;
  // If there are shapes to add
  if (haveShapesToAdd()) {
    // And we have no shapes in the draw list
    if (shapesToDraw.isEmpty() ||
       // Or it's time to add another shape
       firstDrawnShapeIsLargeEnoughToAddMore ()) {
      should = true;
    }
  }
  return should;
}

// Add the shape

void addShape(Shape shape) {
  shapesToDraw.addFirst(shape);
}

// Add a new shape if appropriate

void addShapes () {
  // Twitter thread and draw thread are different threads, so synchronize
  synchronized (shapesToAdd) {
    // If there are shapes to be added
    if (shouldAddShapes()) {
      Shape shape = nextShapeToAdd();
      addShape(shape);
      // Should do something with % padding or % size to add at
      initialSize = initialSize % shapeAddSize;
    }
  }
}

// Increase the size of the shapes over time

void updateInitialSize() {
  float now = millis();
  if(! firstDrawnShapeIsLargeEnoughToAddMore()) { 
    float growth = ((now - lastDrawMillis) * growth_rate);
    initialSize += growth;
  }
  lastDrawMillis = now;
}

// Update the shapes, growing existing ones and adding new ones
// This could be calculated as they are drawn, or recursively
// But it's separate to make debugging easier

// Need to grow size of first shap


void updateShapes() {
  updateInitialSize();
  float currentSize = initialSize;
  Iterator it = shapesToDraw.iterator();
  while (it.hasNext()) {
    Shape shape = (Shape)it.next();
    shape.setSizeFromInnerDiameter(currentSize);
    currentSize = shape.outerDiameter() + padding;
    if (shape.largeEnoughToRemove()) {
      it.remove();
    }
  }
  addShapes();
}

/*******************************************************************************
  Drawing
*******************************************************************************/

// Set the graphics state for the shapes to be drawn with

void setDrawParams () {
    smooth();
    noFill();
    stroke(100);
    strokeWeight(lineWidth);
    strokeJoin(ROUND);
    strokeCap(ROUND);
    background(255);
    translate(displayWidth / 2.0, displayHeight / 2.0);
}

// Draw the shapes

void drawShapes () {
  Iterator it = shapesToDraw.iterator();
  while (it.hasNext()) {
    Shape shape = (Shape)it.next();
    shape.draw();
  }
}

// Update (bad design) then draw the shapes

void draw () {
  updateShapes();
  setDrawParams();
  drawShapes();
}

