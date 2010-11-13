#!/usr/bin/python

import re
import tweetstream

#TODO Can we hide the password?
username = str(raw_input("Twitter username:"))
password = str(raw_input("Twitter password:"))

# Have to search for individual words, so can't search directly for "art is"

def is_art_is(tweet_text):
    """Determine whether the tweet states what art is"""
    return re.search(r'\bart is\b', tweet_text, re.IGNORECASE)

# extract stopwords
# increment counts
# print counts

# Keep a log of the tweets for debugging

#serialise counts
# deserialise on startup


def go():
    stream = tweetstream.TrackStream(username, password, ["art"])
    for tweet in stream:
        tweet_text = tweet["text"]
        if is_art_is(tweet_text):
            print "TWEET: %s" % (tweet_text)
go()
