/*  twitter_streaming_aesthetics - Visualise aesthetic terms from Twitter. 
    Copyright (C) 2010,2011 Rob Myers<rob@robmyers.org>

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

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import fullscreen.*;
import japplemenubar.*; // Fullscreen imports this
import twitter4j.*;
import twitter4j.conf.*;

/*******************************************************************************
  Configuration
*******************************************************************************/

// The root of a Twitter streaming API filter search that tracks keywords
String twitterStreamingTrack = "1/statuses/filter.json?track=";

// Drawing area size and width
int sizeWidth = 600;
int sizeHeight = 400;
int sizeMax = max(sizeWidth, sizeHeight);

// How long it should take for all queued shapes to appear on the screen
int queueDurationMillis = 1000;

// Should this run full screen?
boolean fullscreen;

// How big should a shape be before we add another?
float shapeAddSize = 25.0;

// The list of shapes used in drawing
String[] shapes = {"circle", "triangle", "square", "rectangle", "oval", "cross"};

// How thick the lines should be
float lineWidth = 2.5;

// The amount shapes should grow if none are added
float drift = 0.1;

/*******************************************************************************
  Global state
*******************************************************************************/

// The user's Twitter account login details
String twitterUser;
String twitterPassword;
String query;

// The last time we drew
int lastDrawMillis;

// Fullscreen app, if needed
FullScreen fs; 

/*******************************************************************************
  Twitter User Details
*******************************************************************************/

// Java is designed to produce this kind of busy-work

class ConfigurationDialog extends JDialog implements ActionListener
{
  JLabel usernameLabel;
  JLabel passwordLabel;
  JTextField usernameField;
  JPasswordField passwordField;
  JCheckBox fullscreenCheck;
  JButton okButton;
  
  JDialog dlg;
  
  boolean okButtonPressed;
  
  public ConfigurationDialog() {
    JPanel usernamePanel = new JPanel();
    usernameLabel = new JLabel("Twitter Account Username:");
    usernameField = new JTextField (10);
    usernamePanel.add(usernameLabel);
    usernamePanel.add(usernameField);
  
    JPanel passwordPanel = new JPanel();
    passwordLabel = new JLabel("Twitter Account Password:");
    passwordField = new JPasswordField(10);
    passwordPanel.add(passwordLabel);
    passwordPanel.add(passwordField);
    
    JPanel fullscreenPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    fullscreenCheck = new JCheckBox("Full Screen");
    fullscreenPanel.add(fullscreenCheck);
  
    JPanel okPanel = new JPanel();
    okButton = new JButton("OK");
    okButton.addActionListener(this);
    okPanel.add(okButton);
  
    dlg = new JDialog();
    dlg.setModalityType (Dialog.ModalityType.APPLICATION_MODAL);
    dlg.setResizable(false);
    dlg.getContentPane().setLayout(new GridLayout (4, 1));
    dlg.getContentPane().add(usernamePanel);
    dlg.getContentPane().add(passwordPanel);
    dlg.getContentPane().add(fullscreenPanel);
    dlg.getContentPane().add(okPanel);
    dlg.getRootPane().setDefaultButton(okButton);
    dlg.setTitle("Configure");
    dlg.pack();
    dlg.setLocationRelativeTo(null);
    dlg.setVisible(true);
  }
  
  public void actionPerformed (ActionEvent ae)
  {
    // This assumes every action is a confirmation action
    if (ae.getSource() == okButton) {
      okButtonPressed = true; 
      twitterUser = usernameField.getText();
      twitterPassword = passwordField.getText();
      fullscreen = fullscreenCheck.isSelected();
    }
    dlg.dispose();
  }
  
  public boolean configured () {
    return okButtonPressed;
  }
}

// Read the configuration from a properties file

Properties getConfigurationProperties () {
  Properties properties = new Properties();
  InputStream propStream = openStream("twitter.properties"); 
  if (propStream != null) {
    try {
      properties.load(propStream);
    } catch (IOException e) {
      // Make sure the properties object is empty & coherent if load failed
      properties = new Properties();
    }
  }
  return properties;
}

// Configure from a properties file rather than the GUI
// This is for development or exhibition rather than online

boolean configureFromProperties () {
  boolean configured = false;
  Properties p = getConfigurationProperties();
  if((p != null) && (p.containsKey("username")) && p.containsKey("password")) {
    twitterUser = (String)p.getProperty("username");
    twitterPassword = (String)p.getProperty("password");
    fullscreen = ((String)p.getProperty("fullscreen", "false").toLowerCase()) == "true";
  }
  return configured;
}

/*******************************************************************************
  Setup
*******************************************************************************/

// Get the Twitter account details needed to access the streaming api

boolean setupConfiguration () {
  boolean configured = false;
  // try to get the details form a properties file
  configured = configureFromProperties();
  if (! configured) {
    ConfigurationDialog getter = new ConfigurationDialog();
    configured = getter.configured();
  }
  return configured;
}

// Make objects Java's syntax doesn't allow us to initialize when we declaer

void initializeData () {
  shapesToAdd = new LinkedList();
  shapesToDraw = new LinkedList();
}

// Set up the window or screen

void initializeDisplay () {
  frame.setTitle("Streaming Aesthetics (Shape)");
  if (fullscreen) {
    Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
    sizeWidth = screen.width;
    sizeHeight = screen.height;
    sizeMax = max(sizeWidth, sizeHeight);
  }
  size(sizeWidth, sizeHeight);
  if (fullscreen) {
    fs = new FullScreen(this);
    fs.enter();
    noCursor();
  } else {
    size(sizeWidth, sizeHeight); 
  }
}

// The Processing setup method

void setup () {
  // Get the information we need to configure the program
  boolean configured = setupConfiguration();
  if (configured) {
    initializeData();
    initializeDisplay();
    // Set the initial "last drawing time" as late as possible
    lastDrawMillis = millis();
    // Set the stream filter processor going
    initializeStatusListener (shapes, twitterUser, twitterPassword);
    // Seems to help convince the sketch to run on Fedora 13
    frameRate(24);
    loop();
  } else {
    exit();
  }
}

/*******************************************************************************
  Shape objects
*******************************************************************************/

class Shape {
  float shapeSize = 0.5;

  // Check whether the shape is large enough that another should be added
  boolean largeEnoughToAddMore () {
    return this.shapeSize > shapeAddSize;
  }

  // Check whether the shape has moved off the drawing area
  // Given the irregular geometry of many subclasses this will need overriding
  boolean largeEnoughToRemove () {
    return this.shapeSize > sizeMax;
  }
 
  void updateShapeSize(float sizeDelta) {
    this.shapeSize += sizeDelta;
  }

  // Implemented by subclasses
  void draw () {}
}

class Star extends Shape {
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
        if (i % 2 == 1) // for odd vertices, use short radius
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
    star(5, 0, 0, shapeSize, shapeSize,
         radians(-18), 0.45);
  }

  boolean largeEnoughToRemove () {
    return this.shapeSize > sizeMax * 2.0;
  }
}

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

class Cross extends Shape {
  void draw () {
    float half = shapeSize / 2.0;
    float quarter = shapeSize / 4.0;
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
  }
  
  boolean largeEnoughToRemove () {
    return this.shapeSize > sizeMax * 2.0;
  }
}

class Circle extends Shape {
  void draw () {
    ellipseMode(CENTER);
    ellipse(0, 0, shapeSize, shapeSize);
  }
  
  boolean largeEnoughToRemove () {
    return this.shapeSize > sizeMax * 1.5;
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

class Square extends Shape {
  void draw () {
    rectMode(CENTER);
    rect(0, 0, shapeSize, shapeSize);
  }
}

class Triangle extends Shape {
  void draw () {
    float half = shapeSize * 0.5;
    triangle(0, -half,
             half, half,
             -half, half);
  }
  
  boolean largeEnoughToRemove () {
    return this.shapeSize > sizeMax * 2;
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

/*******************************************************************************
  The list of shapes found in Tweets but not yet being drawn.
*******************************************************************************/

// The list of shapes created by the tweet handler ready for the draw thread
LinkedList shapesToAdd;

// Make the appropriate shape

Shape makeShapeToAdd(String name) {
  Shape shape = null;
  if(name == "circle") {
    shape = new Circle();
  } else if (name == "square") {
    shape = new Square();
  } else if (name == "triangle") {
    shape = new Triangle();
  } else if (name == "star") {
    shape = new Star();
  } else if (name == "cross") {
    shape = new Cross();
  } else if (name == "rectangle") {
    shape = new Rectangle();
  } else if (name == "oval") {
    shape = new Oval();
  }
  return shape;
}

// Queue a shape

void queueShapeToAdd(String shape) {
  synchronized (shapesToAdd) {
    shapesToAdd.addFirst(makeShapeToAdd(shape));
  }
}

// Get and remove the next shape from the queue

Shape nextShapeToAdd() {
   return (Shape)shapesToAdd.removeLast();
}

// Check whether we have any shapes queued

Boolean haveShapesToAdd() {
  return ! shapesToAdd.isEmpty();
}

/*******************************************************************************
  Tweet processing
*******************************************************************************/

// Insert all shapes found in a tweet into the add queue as shapes to be drawn

//TODO: Handle mentions of a single shape multiple times?
void insertShapes (String message) {
  // Java String contains () isn't case insensitive
  String lowercaseMessage = message.toLowerCase();
  for (int i = 0; i < shapes.length; i++) {
    if (lowercaseMessage.contains(shapes[i])) {
      queueShapeToAdd(shapes[i]);
    }
  }
}

// The streaming API processor
TwitterStream twitterStream;

void initializeStatusListener (String[] terms, String user, String password) {
  ConfigurationBuilder builder = new ConfigurationBuilder();
  builder.setUser(user);
  builder.setPassword(password);
  twitterStream = new TwitterStreamFactory(builder.build()).getInstance();
  StatusListener listener = new StatusListener(){
    public void onStatus(Status status) {
      System.out.println(status.getUser().getName() + " : " + status.getText());
      insertShapes(status.getText());
    }
    public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {}
    public void onTrackLimitationNotice(int numberOfLimitedStatuses) {}
    public void onScrubGeo(long lat, long lon) {}
    public void onException(Exception ex) {
      ex.printStackTrace();
    }
  };
  twitterStream.addListener(listener);
  FilterQuery query = new FilterQuery(0, null, terms);
  twitterStream.filter(query);
}

/*******************************************************************************
  The list of shapes to draw
*******************************************************************************/

// The shapes to be drawn
LinkedList shapesToDraw;

// How much should shapes have grown since we last drew?

float sizeDelta (int now) {
  float timeDiff = now - lastDrawMillis;
  float distanceUnit = (shapesToAdd.size() + drift) * 0.1;
  float delta = timeDiff * distanceUnit;
  lastDrawMillis = now;
  return delta;
}

// Add a new shape if appropriate

void addShapes () {
  // Twitter thread and draw thread are different threads, so synchronize
  synchronized (shapesToAdd) {
    if ((shapesToDraw.isEmpty() ||
          ((Shape)shapesToDraw.peekFirst()).largeEnoughToAddMore()) &&
	  haveShapesToAdd()) {
      shapesToDraw.addFirst(nextShapeToAdd());
    }  
  }
}

// Update the shapes, growing existing ones and adding new ones

void updateShapes () {
  int now = millis();
  float delta = sizeDelta(now);
  Iterator it = shapesToDraw.iterator();
  while (it.hasNext()) {
    Shape shape = (Shape)it.next();
    shape.updateShapeSize(delta);
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
    translate(sizeWidth / 2.0, sizeHeight / 2.0);
}

// Draw the shapes

void drawShapes ()
{
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
