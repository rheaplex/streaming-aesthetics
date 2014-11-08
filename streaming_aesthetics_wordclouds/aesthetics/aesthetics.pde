/*  aesthetics.pde - Visualise aesthetic terms from Twitter as a wordcloud.
    Copyright (C) 2014  Rob Myers<rob@robmyers.org>

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

import wordcram.*;

// CONSTANTS

// Aesthetics configuration

float BACKGROUND_COLOUR = 0.3;
color TEXT_COLOUR = #ededed;
long DISPLAY_FINISHED_WORDCLOUD_FOR = 5000;

// Twitter

ConfigurationBuilder cb;
Query query;

// Word cloud

WordCram wordCram;

// Search keywords

String search_keywords_string = "black,white,grey,gray,red,orange,yellow,green,blue,purple,cyan,magenta,pink,brown,beige,violet,indigo,point,line,circle,triangle,square,star,spiral,grid,painting,drawing,printmaking,sculpture,video art,sound art,performance art,installation art,digital art,conceptual art,varporwave,glitch,gif,cyberpunk,net art,ascii art,game art,locative media,code poetry,generative art,algorithmic art,Yayoi Kusama,Barbara Kruger,Richard Serra,Jeff Koons,Cindy Sherman,Ai Weiwei,Takashi Murakami,Marina Abramovic,Banksy,Damien Hirst,Tate,Getty,MOMA,ICA,LACMA,Prado,Louvre,Uffizi,Saatchi Gallery,Rijksmuseum";
String search_keywords[] = search_keywords_string.split(",");
String keywords_re = "\\b(" + search_keywords_string.replaceAll(",", "|") + ")\\b";
Pattern pattern = Pattern.compile(keywords_re);

// STATE

// Keyword counts

IntDict keywords_map = new IntDict();

// Display timing

long display_finished_wordcloud_until = 0;

// FUNCTIONS

// Are there any keywords?

boolean anyKeywords() {
  return keywords_map.size() > 0;
}

// Convert the keyword counts to a format usable by WordCram

Word[] keywordCounts() {
  Word words[] = new Word[keywords_map.size()];
  int i = 0;
  for (String keyword : keywords_map.keys()) {
    words[i] = new Word(keyword, keywords_map.get(keyword));
    i++;
  }
  return words;
}

// Scan text for keywords and update counts

void matchKeywords(String text) {
  Matcher matcher = pattern.matcher(text);
  while (matcher.find()) {
    String keyword = matcher.group();
    int keyword_weight = keywords_map.get(keyword) + 1;
    keywords_map.set(keyword, keyword_weight);
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
      matchKeywords(status.getText().toLowerCase());
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
  fq.track(search_keywords);
  ts.addListener(listener);
  ts.filter(fq);
  return ts;
}

// Get the current keyword counts and make a wordcloud of them

void updateWordCram() {
 wordCram = new WordCram(this).fromWords(keywordCounts())
                              .withColor(TEXT_COLOUR)
                              .withPlacer(Placers.centerClump());
}

// MAIN FLOW OF EXECUTION

void setup() {
  size(600, 400);
  background(BACKGROUND_COLOUR);
  updateWordCram();
  StatusListener listener = createStatusListener();
  createFilteredStream(listener);
  noCursor();
}

void draw() {
  if (anyKeywords()) {
    if (! wordCram.hasMore()) {
      if (display_finished_wordcloud_until == 0) {
        display_finished_wordcloud_until = System.currentTimeMillis() + DISPLAY_FINISHED_WORDCLOUD_FOR;
      } else if (System.currentTimeMillis() > display_finished_wordcloud_until) {
        display_finished_wordcloud_until = 0;
        updateWordCram();
        background(BACKGROUND_COLOUR);
      }
    }
    wordCram.drawNext();
  }
}
