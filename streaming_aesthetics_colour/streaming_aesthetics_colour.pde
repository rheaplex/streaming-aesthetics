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
import twitter4j.*;
import twitter4j.conf.*;

/*******************************************************************************
  Configuration
*******************************************************************************/

// The root of a Twitter streaming API filter search that tracks keywords
String twitterStreamingTrack = "1/statuses/filter.json?track=";

// Drawing area size and width
int sizeWidth = 600;
int sizeHeight = 175;

// How wide each colour bar is
int barSize = 10;

// How long it should take for all queued bars to appear on the screen
int queueDurationMillis = 1000;

// Whether the flow is horizontal (false) or vertical (true)
boolean vertical;
// Whether the flow is from the top/left (false) or bottom/right (true)
boolean reverseDirection;
// Should this run full screen?
boolean fullscreen;


/*******************************************************************************
  Global state
*******************************************************************************/

// The user's Twitter account login details
String twitterUser;
String twitterPassword;

Hashtable colours;
LinkedList lines;
String query;

// How far the queued bars extend before the origin
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
  InputStream propStream = openStream("configuration.properties"); 
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
    vertical = ((String)p.getProperty("vertical", "false").toLowerCase()).equals("true");
    reverseDirection = ((String)p.getProperty("reverse", "false").toLowerCase()).equals("true");
    fullscreen = ((String)p.getProperty("fullscreen", "false").toLowerCase()).equals("true");
    configured = true;
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

// Create the colour palette used in drawing

Hashtable setupPalette () {
  Hashtable palette = new Hashtable();
  // We have to use an Integer object for the colour
  //   as Java containers can't handle simple types
  // Colours adapted from HTML colour names.
  palette.put("red", new Integer(color(#DD0000)));
  palette.put("yellow", new Integer(color(#DDDD00)));
  palette.put("blue", new Integer(color(#4169E1)));
  palette.put("green", new Integer(color(#008000)));
  palette.put("orange", new Integer(color(#FF4500)));
  palette.put("purple", new Integer(color(#800080)));
  palette.put("brown", new Integer(color(#A0522D)));
  palette.put("black", new Integer(color(#151515)));
  palette.put("grey", new Integer(color(#888888)));
  palette.put("pink", new Integer(color(#FA8072)));
  palette.put("white", new Integer(color(#EEEEEE)));
  palette.put("cyan", new Integer(color(#00DDDD)));
  palette.put("magenta", new Integer(color(#DD00DD)));
  return palette;
}

// Make the streaming api query for the colours from the palette

String[] coloursArray () {
  Enumeration keys = colours.keys();
  String[] keyArray = new String[colours.size()];
  Enumeration en = colours.keys();
  for (int i = 0; i < colours.size(); i++) {
    keyArray[i] = (String)keys.nextElement();
  }
  return keyArray;
}

// The Processing setup method

void setup () {
  // Make the data structures
  colours = setupPalette();
  lines = new LinkedList();
  // Get the information we need to configure the program
  boolean configured = setupConfiguration();
  if (configured) {
    if (fullscreen) {
      Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
      sizeWidth = screen.width;
      sizeHeight = screen.height;
    }
    frame.setTitle("Streaming Aesthetics (Colour)");
    size(sizeWidth, sizeHeight); 
    if (fullscreen) {
      fs = new FullScreen(this);
      fs.enter();
      noCursor();
    }
    // Set the initial "last drawing time" as late as possible
    lastDrawMillis = millis();
    initializeStatusListener (coloursArray(), twitterUser, twitterPassword);
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

// Insert all colours found in a tweet into the queue as bars to be drawn

//TODO: Handle mentions of a single colour multiple times?
void insertColourValues (String message, LinkedList insertIn) {
  // Java String contains () isn't case insensitive
  String lowercaseMessage = message.toLowerCase();
  Enumeration en = colours.keys();
  while (en.hasMoreElements()) {
    String colour = (String)en.nextElement();
    if (lowercaseMessage.contains(colour)) {
      insertIn.addFirst((Integer)colours.get(colour));
      queueOriginOffset += barSize;
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
      // Add and iterator get are in different threads, so synchronize
      synchronized (lines) {
        insertColourValues(status.getText(), lines);
      }
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
  Drawing
*******************************************************************************/

// Update the position of the first bar

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

// Get the position of the first bar (may well be before the drawing area)

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

// Get the position to draw the next bar at

float updateOffset (float origin) {
  if (reverseDirection) {
     origin -= barSize;
  } else {
     origin += barSize; 
  }
  return origin;
}

// Check whether the bar has moved off the drawing area

boolean barIsFinished (float origin) {
  boolean finished = false;
  if (vertical) {
    if (reverseDirection) {
      finished = (origin < 0 - barSize);
    } else {
      finished = (origin > height);
    }
  } else {
    if (reverseDirection) {
      finished = (origin < 0 - barSize);
    } else {
      finished = (origin > width); 
    }
  }
  return finished;
}

// Processing draw function

void draw () {
  // Add and iterator get are in different threads, so synchronize
  synchronized (lines) {
    smooth();
    background(255);
    noStroke();
    updateOrigin();
    float offset = initialOffset();
    Iterator it = lines.iterator();
    while (it.hasNext()) {
      Integer tweetColour = (Integer)it.next();
      // Bad: update logic in draw.
      // Good: single update loop
      if (barIsFinished(offset)) {
       it.remove();
      } else {
        fill (tweetColour.intValue());
        if (vertical) {
          rect (0, offset, width, barSize);
        } else {
          rect (offset, 0, barSize, height);
        }
      }
      offset = updateOffset(offset);
    }
  }
}
