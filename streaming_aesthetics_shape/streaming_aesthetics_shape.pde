/*  twitter_streaming_aesthetics - Visualise aesthetic terms from Twitter. 
    Copyright (C) 2010  Rob Myers<rob@robmyers.org>

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
import com.twitter.processing.*;

/*******************************************************************************
  Configuration
*******************************************************************************/

// The root of a Twitter streaming API filter search that tracks keywords
String twitterStreamingTrack = "1/statuses/filter.json?track=";

// Drawing area size and width
int sizeWidth = 600;
int sizeHeight = 175;

// How wide each shape is
float shapeSize = 25.0;

// How long it should take for all queued shapes to appear on the screen
int queueDurationMillis = 1000;

// Whether the flow is horizontal (false) or vertical (true)
boolean vertical;
// Whether the flow is from the top/left (false) or bottom/right (true)
boolean reverseDirection;
// Should this run full screen?
boolean fullscreen;

static final int CIRCLE_SHAPE = 1;
static final int TRIANGLE_SHAPE = 2;
static final int SQUARE_SHAPE = 3;
static final int OVAL_SHAPE = 4;
static final int RECTANGLE_SHAPE = 5;
static final int STAR_SHAPE = 6;
static final int ARROW_SHAPE = 7;
static final int CRESCENT_SHAPE = 8;
static final int CROSS_SHAPE = 9;

/*******************************************************************************
  Global state
*******************************************************************************/

// The user's Twitter account login details
String twitterUser;
String twitterPassword;

Hashtable shapes;
LinkedList shapesToDraw;
String query;

// How far the queued shapes extend before the origin
float queueOriginOffset;

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
  JCheckBox verticalCheck;
  JCheckBox reverseCheck;
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
    
    JPanel verticalPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    verticalCheck = new JCheckBox("Vertical Flow");
    verticalPanel.add(verticalCheck);
    
    JPanel reversePanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    reverseCheck = new JCheckBox("Reverse Direction");
    reversePanel.add(reverseCheck);
    
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
    dlg.getContentPane().setLayout(new GridLayout (6, 1));
    dlg.getContentPane().add(usernamePanel);
    dlg.getContentPane().add(passwordPanel);
    dlg.getContentPane().add(verticalPanel);
    dlg.getContentPane().add(reversePanel);
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
      vertical = verticalCheck.isSelected();
      reverseDirection = reverseCheck.isSelected();
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
    vertical = ((String)p.getProperty("vertical", "false").toLowerCase()) == "true";
    reverseDirection = ((String)p.getProperty("reverse", "false").toLowerCase()) == "true";
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

// Create the list of shapes used in drawing

Hashtable setupShapes() {
  Hashtable shapes = new Hashtable();
  // We have to use an Integer object for the shape
  //   as Java containers can't handle simple types
  shapes.put("circle", CIRCLE_SHAPE);
  shapes.put("triangle", TRIANGLE_SHAPE);
  shapes.put("square", SQUARE_SHAPE);
  shapes.put("rectangle", RECTANGLE_SHAPE);
  shapes.put("oval", OVAL_SHAPE);
  shapes.put("star", STAR_SHAPE);
  shapes.put("arrow", ARROW_SHAPE);
  shapes.put("crescent", CRESCENT_SHAPE);
  shapes.put("cross", CROSS_SHAPE);
  return shapes;
}

// Make the streaming api query for the shapes from the shape hash

String setupQuery (Hashtable terms)
{
  String query = twitterStreamingTrack;
  Enumeration en = terms.keys();
  while (en.hasMoreElements()) {
    query += (String)en.nextElement();
    if (en.hasMoreElements()) {
      query += ",";
    }
  }
  return query;
}

// The Processing setup method

void setup () {
  // Make the data structures
  shapes = setupShapes();
  query = setupQuery(shapes);
  shapesToDraw = new LinkedList();
  // Get the information we need to configure the program
  boolean configured = setupConfiguration();
  if (configured) {
    TweetStream s = new TweetStream(this, "stream.twitter.com",
                                    80, query, twitterUser, twitterPassword);
    if (fullscreen) {
      Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
      sizeWidth = screen.width;
      sizeHeight = screen.height;
    }
    frame.setTitle("Streaming Aesthetics (Shape)");
    size(sizeWidth, sizeHeight); 
    if (fullscreen) {
      fs = new FullScreen(this);
      fs.enter();
      noCursor();
    }
    // Set the initial "last drawing time" as late as possible
    lastDrawMillis = millis();
    s.go();
    // Seems to help convince the sketch to run on Fedora 13
    frameRate(24);
    loop();
  } else {
    exit();
  }
}


/*******************************************************************************
  Tweet Processing
*******************************************************************************/

// Insert all shapes found in a tweet into the queue as shapes to be drawn

//TODO: Handle mentions of a single shape multiple times?
void insertShapes (String message, LinkedList insertIn) {
  // Java String contains () isn't case insensitive
  String lowercaseMessage = message.toLowerCase();
  Enumeration en = shapes.keys();
  while (en.hasMoreElements()) {
    String shape = (String)en.nextElement();
    if (lowercaseMessage.contains(shape)) {
      insertIn.addFirst((Integer)shapes.get(shape));
      queueOriginOffset += shapeSize;
    }
  }
}

// Tweet Streaming library callback function

void tweet (Status tweet) {
  // Add and iterator get are in different threads, so synchronize
  synchronized (shapesToDraw) {
    println(tweet.text());
    insertShapes(tweet.text(), shapesToDraw);
  }
}


/*******************************************************************************
  Drawing
*******************************************************************************/

// Update the position of the first shape

void updateOrigin () {
  int now = millis();
  float timeDiff = now - lastDrawMillis;
  float distanceUnit = queueOriginOffset / queueDurationMillis;
  float delta = timeDiff * distanceUnit;
  queueOriginOffset -= delta;
  // Avoid slow crawl at end, or < 0 weirdness
  if (queueOriginOffset < 1) {
    queueOriginOffset = 0.0; 
  }
  lastDrawMillis = now;
  //println(queueOriginOffset);
}

// Get the position of the first shape (may well be before the drawing area)

float initialOffset () {
  float origin = - queueOriginOffset;
  if (vertical) {
    if (reverseDirection) {
      origin = height + queueOriginOffset;
    }
  } else {
    if (reverseDirection) {
      origin = width + queueOriginOffset;
    }
  }
  return origin;
}

// Get the position to draw the next shape at

float updateOffset (float origin) {
  if (reverseDirection) {
     origin -= shapeSize;
  } else {
     origin += shapeSize; 
  }
  return origin;
}

// Check whether the shape has moved off the drawing area

boolean shapeIsFinished (float origin) {
  boolean finished = false;
  if (vertical) {
    if (reverseDirection) {
      finished = (origin < 0 - shapeSize);
    } else {
      finished = (origin > height);
    }
  } else {
    if (reverseDirection) {
      finished = (origin < 0 - shapeSize);
    } else {
      finished = (origin > width); 
    }
  }
  return finished;
}

// From http://processing.org/learning/anatomy/

void star(int n, float cx, float cy, float w, float h,
  float startAngle, float proportion)
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


// Shape drawing master switch function

void drawShape (int kind) {
  switch (kind) {
    case CIRCLE_SHAPE:
      ellipse(shapeSize / 2.0, shapeSize / 2.0, shapeSize * 0.9, shapeSize * 0.9);
      break;
    case TRIANGLE_SHAPE:
      triangle(0.05, shapeSize * 0.9, shapeSize / 2.0, 0.05, shapeSize * 0.9, shapeSize * 0.9);
      break;
    case SQUARE_SHAPE:
      rect(shapeSize * 0.05, shapeSize * 0.05, shapeSize * 0.9, shapeSize * 0.9);
      break;
    case OVAL_SHAPE:
      ellipse(shapeSize / 2.0, shapeSize / 2.0, shapeSize * 0.75, shapeSize * 1.5);
      break;
    case RECTANGLE_SHAPE:
      rect(shapeSize * 0.25, -shapeSize * 0.25, shapeSize * 0.75, shapeSize * 1.5);
      break;
    case STAR_SHAPE:
      star(5, shapeSize / 2.0, shapeSize / 2.0, shapeSize, shapeSize, radians(-18), 0.45);
      break;
    case ARROW_SHAPE:
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
      break;
    case CRESCENT_SHAPE:
      float threeQuarters = shapeSize * 0.75;
      float oneAndAQuarter = shapeSize * 1.27; // misnomer
      beginShape();
      vertex(0.0, 0.0);
      bezierVertex(oneAndAQuarter, 0.0, oneAndAQuarter, shapeSize, 0.0, shapeSize);
      bezierVertex(threeQuarters, shapeSize, threeQuarters, 0.0, 0.0, 0.0);
      endShape();
      break;
    case CROSS_SHAPE:
      float oneThird = shapeSize / 3.0;
      float twoThirds = oneThird * 2;
      beginShape();
      vertex(0.0, oneThird);
      vertex(0.0, twoThirds);
      vertex(oneThird, twoThirds);
      vertex(oneThird, shapeSize);
      vertex(twoThirds, shapeSize);
      vertex(twoThirds, twoThirds);
      vertex(shapeSize, twoThirds);
      vertex(shapeSize, oneThird);
      vertex(twoThirds, oneThird);
      vertex(twoThirds, 0.0);
      vertex(oneThird, 0.0);
      vertex(oneThird, oneThird);
      vertex(0.0, oneThird);
      endShape();
      break;
  }
}

// Processing draw function

void draw () {
  // Add and iterator get are in different threads, so synchronize
  synchronized (shapesToDraw) {
    updateOrigin();
    float offset = initialOffset();
    if (vertical) {
      translate(0.0, offset);
    } else {
      translate(offset, 0.0);
    }
    smooth();
    stroke(0);
    strokeWeight(shapeSize / 20.0);
    strokeJoin(ROUND);
    strokeCap(ROUND);
    background(255);
     if (vertical) {
       translate((width / 2.0) - (shapeSize / 2.0), 0.0);
     } else {
       translate(0.0, (height / 2.0) - (shapeSize / 2.0));
    }
    Iterator it = shapesToDraw.iterator();
    while (it.hasNext()) {
      Integer tweetshape = (Integer)it.next();
      // Bad: update logic in draw.
      // Good: single update loop
      if (shapeIsFinished(offset)) {
       it.remove();
      } else {
        drawShape(tweetshape.intValue());
        if (vertical) {
          translate(0.0, shapeSize);
        } else {
          translate(shapeSize, 0.0);
        }
      }
      offset += shapeSize;
    }
  }
}
