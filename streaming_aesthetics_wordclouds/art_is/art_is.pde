/*  art_is.pde - Create a word cloud of art definitions from Twitter.
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

// What to search for on Twitter
String[] search_string = {"art is"};

// Definition regex

String definition_re = "\\bart\\s+is([\\s\\w]+)";
Pattern pattern = Pattern.compile(definition_re);

// Stopwords
// From the alleged old Google list - http://www.ranks.nl/stopwords
// "art is" has been added, along with various other words to taste

String[] stopwords = "art is a about an and are as at be but by cant for from how http i if in it of on or so that the the this to was what when where who will with www".split(" ");

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

// Remove stopwords

boolean isStopword(String word) {
  for(String str: stopwords) {
    if(str.contains(word))
       return true;
  }
  return false;
}

// Scan text for keywords and update counts

void matchKeywords(String text) {
  Matcher matcher = pattern.matcher(text);
  while (matcher.find()) {
    String definition = matcher.group();
    String[] keywords = definition.split(" ");
    for(String keyword: keywords ) {
      keyword = keyword.trim();
      if(keyword != "" && ! isStopword(keyword)) {
        int keyword_weight = keywords_map.get(keyword) + 1;
        keywords_map.set(keyword, keyword_weight);
      }
    }
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

  fq.track(search_string);

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
  size(1000, 700);
  background(BACKGROUND_COLOUR);
  updateWordCram();
  StatusListener listener = createStatusListener();
  createFilteredStream(listener);
  noCursor();
}

void draw() {
  if (anyKeywords()) {
    if (! wordCram.hasMore()) {
      //for (Word word : wordCram.getSkippedWords()) {
      //  println(word.word + ": " + word.wasSkippedBecause());
      //}
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
