/*  twitter_streaming_aesthetics - Visualise aesthetic terms from Twitter. 
    Copyright (C) 2010, 2015  Rob Myers<rob@robmyers.org>

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

import twitter4j.conf.*;
import twitter4j.api.*;
import twitter4j.*;
import java.util.*;
import java.util.regex.*;

/*******************************************************************************
  Configuration
*******************************************************************************/

// The root of a Twitter streaming API filter search that tracks keywords
String twitterStreamingTrack = "1/statuses/filter.json?track=";

// Drawing area size and width
int displayWidth = 1024;
int displayHeight = 275;

// How wide each colour bar is
int barSize = 4;

// How long it should take for all queued bars to appear on the screen
int queueDurationMillis = 1000;

// Whether the flow is horizontal (false) or vertical (true)
boolean vertical;
// Whether the flow is from the top/left (false) or bottom/right (true)
boolean reverseDirection;


/*******************************************************************************
  Global state
*******************************************************************************/

Hashtable colours;
LinkedList lines;

// How far the queued bars extend before the origin
float queueOriginOffset;

// The last time we drew
int lastDrawMillis;


/*******************************************************************************
  Twitter
*******************************************************************************/

ConfigurationBuilder cb;
Query query;

String definition_re = "(red|yellow|blue|green|orange|purple|brown|black|grey|pink|white|cyan|magenta)";
Pattern pattern = Pattern.compile(definition_re);

// Set up the twitter connection using config from configuration.properties

TwitterStream makeTwitterStream() {
  Properties p = new Properties();
  InputStream propStream = openStream("configuration.properties");
  try {
    p.load(propStream);
  } catch (IOException e)
  {
    System.out.println(e);
    noLoop();
  }
  cb = new ConfigurationBuilder();
  cb.setOAuthConsumerKey((String)p.getProperty("consumerKey"));
  cb.setOAuthConsumerSecret((String)p.getProperty("consumerSecret"));
  cb.setOAuthAccessToken((String)p.getProperty("accessToken"));
  cb.setOAuthAccessTokenSecret((String)p.getProperty("accessSecret"));
  return new TwitterStreamFactory(cb.build()).getInstance();
}

// Create the object that handles matches on the Twitter stream

StatusListener createStatusListener() {
 return new StatusListener(){
    public void onStatus(Status status){
      synchronized (lines) {
        insertColourValues(status.getText(), lines);
      }
    }
    public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {}
    public void onTrackLimitationNotice(int numberOfLimitedStatuses) {}
    public void onStallWarning(StallWarning warning) {}
    public void onScrubGeo(long userId, long upToStatusId) {}
    public void onException(Exception ex) {
      ex.printStackTrace();
    }
  };
}

// Tie the Twitter stream search to its handler

TwitterStream createFilteredStream(StatusListener listener) {
  TwitterStream ts = makeTwitterStream();
  FilterQuery fq = new FilterQuery();
  fq.track((String[])colours.keySet().toArray(new String[colours.keySet().size()]));

  ts.addListener(listener);
  ts.filter(fq);
  return ts;
}


/*******************************************************************************
  Colour
*******************************************************************************/

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


/*******************************************************************************
  Main flow of execution
*******************************************************************************/

// The Processing setup method

void setup () {
  size(displayWidth, displayHeight);
  // Make the data structures
  colours = setupPalette();
  lines = new LinkedList();
  // Set the initial "last drawing time" as late as possible
  lastDrawMillis = millis();
  StatusListener listener = createStatusListener();
  createFilteredStream(listener);
  noCursor();
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
